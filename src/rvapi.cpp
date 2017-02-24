#include "rvapi.h"

#include <QFileInfo>

#include <QJsonDocument>
#include <QJsonObject>

#include <QUrlQuery>

#include <QDebug>
#include <QStandardPaths>
#include <QGeoCoordinate>
#include <QRegularExpression>

#include <QCoreApplication>
#include <QStandardPaths>

//#define LOGIN_DEBUG 1
//#define DATA_DEBUG 1
//#define JSON_DEBUG 1
//#define SECURE_DEBUG 1

#define ITEMS_MAX (10)

RvAPI::RvAPI(QObject *parent) :
    QObject(parent),
    m_NetManager(new QNetworkAccessManager(this)),
    m_apiversion(1),
    m_appversion(0),
    m_authenticated(false),    
    m_busy(false),
    m_hasMore(false),    
    m_loadedPage(0),
    m_itemsmodel(this),
    m_categorymodel(0, this),
    m_locations(this),
    m_tax_model(this)
{
    CategoryModel *cm;

    connect(m_NetManager,SIGNAL(sslErrors(QNetworkReply*,QList<QSslError>)),this,SLOT(onIgnoreSSLErrors(QNetworkReply*,QList<QSslError>)));

    QNetworkDiskCache *diskCache = new QNetworkDiskCache(this);
    diskCache->setCacheDirectory(QStandardPaths::writableLocation(QStandardPaths::CacheLocation));
    m_NetManager->setCache(diskCache);

    // Create network request application header string
    m_hversion=QString("RW/%1").arg(QCoreApplication::applicationVersion());

    // XXX: We should load this from a JSON/XML/something!!
#if 0
    m_categorymodel.addCategory("", "", CategoryModel::InvalidCategory);
    m_categorymodel.addCategory("huonekalu", "Huonekalu", CategoryModel::HasSize | CategoryModel::HasWeight | CategoryModel::HasColor);
    m_categorymodel.addCategory("laite", "Laite", CategoryModel::HasSize | CategoryModel::HasWeight | CategoryModel::HasMakeAndModel | CategoryModel::HasEAN);
    m_categorymodel.addCategory("kirja", "Kirja", CategoryModel::HasISBN | CategoryModel::HasAuthor);
    m_categorymodel.addCategory("askartelu", "Askartelu", CategoryModel::HasSize | CategoryModel::HasColor | CategoryModel::HasStock);
    m_categorymodel.addCategory("liikunta", "Liikunta", 0);
    m_categorymodel.addCategory("rakennusmateriaali", "Rakennusmateriaali", 0);
    m_categorymodel.addCategory("sekalaista", "Sekalaista", 0);

    cm=new CategoryModel("huonekalu", this);
    cm->addCategory("tuoli", "Tuoli", CategoryModel::HasSize | CategoryModel::HasWeight| CategoryModel::HasColor);
    cm->addCategory("hylly", "Hylly", CategoryModel::HasSize | CategoryModel::HasWeight| CategoryModel::HasColor);
    cm->addCategory("poyta", "Pöytä", CategoryModel::HasSize | CategoryModel::HasWeight| CategoryModel::HasColor);
    cm->addCategory("sohva", "Sohva", CategoryModel::HasSize | CategoryModel::HasWeight| CategoryModel::HasColor);
    cm->addCategory("lipasto", "Lipasto", CategoryModel::HasSize | CategoryModel::HasWeight| CategoryModel::HasColor);
    cm->addCategory("pulpetti", "Pulpetti", CategoryModel::HasSize | CategoryModel::HasWeight| CategoryModel::HasColor);
    cm->addCategory("kaappi", "Kaappi", CategoryModel::HasSize | CategoryModel::HasWeight| CategoryModel::HasColor);
    cm->addCategory("rulokaappi", "Kaappi/Rulokaappi", CategoryModel::HasSize | CategoryModel::HasWeight| CategoryModel::HasColor);
    cm->addCategory("hyllykaappi", "Kaappi/Hyllykaappi", CategoryModel::HasSize | CategoryModel::HasWeight| CategoryModel::HasColor);
    cm->addCategory("vaatekaappi", "Kaappi/Vaatekaappi", CategoryModel::HasSize | CategoryModel::HasWeight| CategoryModel::HasColor);
    cm->addCategory("huonemuu", "Muu", CategoryModel::HasSize | CategoryModel::HasWeight| CategoryModel::HasColor);
    m_subcategorymodels.insert("huonekalu", cm);

    cm=new CategoryModel("laite", this);
    cm->addCategory("kodinkone", "Kodinkone", CategoryModel::HasSize | CategoryModel::HasWeight | CategoryModel::HasEAN);
    cm->addCategory("it", "IT", CategoryModel::HasMakeAndModel | CategoryModel::HasEAN);
    cm->addCategory("laitemuu", "Muut", CategoryModel::HasSize | CategoryModel::HasWeight | CategoryModel::HasMakeAndModel | CategoryModel::HasEAN);
    m_subcategorymodels.insert("laite", cm);

    cm=new CategoryModel("kirja", this);
    cm->addCategory("kirjakauno", "Kaunokirjallisuus", CategoryModel::HasISBN | CategoryModel::HasAuthor);
    cm->addCategory("kirjamuu", "Muu", CategoryModel::HasISBN | CategoryModel::HasAuthor);
    m_subcategorymodels.insert("kirja", cm);

    cm=new CategoryModel("askartelu", this);
    cm->addCategory("askartelumuu", "Muu", CategoryModel::HasSize | CategoryModel::HasColor | CategoryModel::HasStock);
    m_subcategorymodels.insert("askartelu", cm);

    cm=new CategoryModel("liikunta", this);
    cm->addCategory("liikuntamuu", "Muu", CategoryModel::HasSize | CategoryModel::HasWeight | CategoryModel::HasColor);
    m_subcategorymodels.insert("liikunta", cm);

    cm=new CategoryModel("rakennusmateriaali", this);
    cm->addCategory("rakmuu", "Muu", CategoryModel::HasSize | CategoryModel::HasWeight | CategoryModel::HasColor);
    m_subcategorymodels.insert("rakennusmateriaali", cm);

    cm=new CategoryModel("sekalaista", this);
    cm->addCategory("sekalaistamuu", "Muu", 0);
    m_subcategorymodels.insert("sekalaista", cm);
#endif

    m_attributes << "width" << "height" << "depth" << "weight" << "color" << "ean" << "isbn" << "purpose" << "make" << "model" << "author" << "location" << "locationdetail";

    m_taxes << "0%" << "10%" << "14%" << "24%";
    m_tax_model.setStringList(m_taxes);
}

RvAPI::~RvAPI()
{
    qDebug("*** API going away");
}

void RvAPI::setUrl(QUrl url)
{
    if (m_url == url)
        return;

    qDebug() << "API url " << url;

    m_url = url;
    emit urlChanged(url);
}

/**
 * @brief RvAPI::setHasMore
 * @param hasmore
 */
void RvAPI::setHasMore(bool hasmore)
{
    if (m_hasMore==hasmore)
        return;

    qDebug() << "HasMore " << hasmore;

    m_hasMore=hasmore;
    emit hasMoreChanged(hasmore);
}

void RvAPI::setAuthentication(bool auth)
{
    if (m_authenticated==auth)
        return;

    m_authenticated=auth;
    emit authenticatedChanged(m_authenticated);
}

void RvAPI::onIgnoreSSLErrors(QNetworkReply *reply, QList<QSslError> error)
{
#ifdef SECURE_DEBUG
    reply->ignoreSslErrors(error);
#endif
    qWarning() << "SSL Error(s):" << error;

    emit secureConnectionFailure();
}

void RvAPI::requestError(QNetworkReply::NetworkError code)
{
    qWarning() << "Request error: " << code;
    switch(code) {
    case QNetworkReply::ConnectionRefusedError:
        break;
    case QNetworkReply::ContentOperationNotPermittedError:
        break;
    default:
        break;
    }
}

void RvAPI::uploadProgress(qint64 bytes, qint64 total)
{
    quint8 p;
    //QNetworkReply * reply = qobject_cast<QNetworkReply*>(sender());
    qDebug() << "Uploading: " << bytes << " / " << total;

    if (total==0 || bytes==0)
        p=0;
    else
        p=(quint8)(double(bytes)/double(total)*100.0f);

    setBusy(true);
    m_uploadProgress=p;
    uploadProgressChanged(m_uploadProgress);
    emit uploading(p);
}

void RvAPI::downloadProgress(qint64 bytes, qint64 total)
{
    quint8 p;
    qDebug() << "Downloading: " << bytes << " / " << total;

    if (total==0 || bytes==0)
        p=0;
    else
        p=(quint8)(double(bytes)/double(total)*100.0f);

    m_downloadProgress=p;
    downloadProgressChanged(m_downloadProgress);

    setBusy(true);
    emit downloading(p);
}

void RvAPI::requestFinished() {
    QNetworkReply * reply = qobject_cast<QNetworkReply*>(sender());

    parseResponse(reply);

    reply->deleteLater();
}

QVariantMap RvAPI::parseJsonResponse(const QByteArray &data)
{
    QJsonDocument json=QJsonDocument::fromJson(data);
#ifdef JSON_DEBUG
    qDebug() << data;
    qDebug() << json.toJson();
    qDebug() << "json object " << json.isObject();
#endif

    if (json.isEmpty() || json.isNull()) {
        qWarning("API gave invalid JSON!");
        QVariantMap dummy;
        return dummy;
    }

    return json.object().toVariantMap();
}

bool RvAPI::addFilePart(QHttpMultiPart *mp, QString prefix, QString fileName) {
    QFile *file = new QFile(fileName);
    if (file->open(QIODevice::ReadOnly)==false) {
        delete file;
        return false;
    }
    QHttpPart p;
    QFileInfo fi(fileName);
    QVariant cth("image/jpeg");
    QVariant cdh("form-data; name=\"images[]\"; filename=\""+prefix+fi.fileName()+"\"");

    qDebug() << cdh;

    p.setHeader(QNetworkRequest::ContentTypeHeader, cth);
    p.setHeader(QNetworkRequest::ContentDispositionHeader, cdh);
    p.setBodyDevice(file);
    file->setParent(mp);
    mp->append(p);

    return true;
}

void RvAPI::addParameter(QHttpMultiPart *mp, const QString key, const QVariant value)
{
    QHttpPart requestPart;
#ifdef DATA_DEBUG
    qDebug() << "KEY: " << key << "\nVALUE:\n" << value;
#endif

    requestPart.setHeader(QNetworkRequest::ContentDispositionHeader, QVariant("form-data; name=\""+key+"\""));
    requestPart.setBody(value.toString().toUtf8());
    mp->append(requestPart);
}

void RvAPI::connectReply(QNetworkReply *reply)
{
    QObject::connect(reply, SIGNAL(finished()), this, SLOT(requestFinished()));
    QObject::connect(reply, SIGNAL(error(QNetworkReply::NetworkError)), this, SLOT(requestError(QNetworkReply::NetworkError)));
    QObject::connect(reply, SIGNAL(uploadProgress(qint64, qint64)), this, SLOT(uploadProgress(qint64, qint64)));
    QObject::connect(reply, SIGNAL(downloadProgress(qint64, qint64)), this, SLOT(downloadProgress(qint64, qint64)));
}

/**
 * @brief RvAPI::POSTRequest
 * @param request
 * @param mp
 * @return
 */
QNetworkReply *RvAPI::post(QNetworkRequest &request, QHttpMultiPart *mp)
{
    QNetworkReply *reply;

    reply = m_NetManager->post(request, mp);
    mp->setParent(reply);
    connectReply(reply);

    return reply;
}

/**
 * @brief RvAPI::get
 * @param request
 * @return
 */
QNetworkReply *RvAPI::get(QNetworkRequest &request)
{
    QNetworkReply *reply;

    reply = m_NetManager->get(request);
    connectReply(reply);

    return reply;
}

/**
 * @brief RvAPI::head
 * @param request
 * @return
 */
QNetworkReply *RvAPI::head(QNetworkRequest &request)
{
    QNetworkReply *reply;

    reply = m_NetManager->head(request);
    connectReply(reply);

    return reply;
}

/**
 * @brief RvAPI::isRequestActive
 * @param op
 * @return true if op is already active, false otherwise
 *
 * Check request list if operation is already in progress.
 *
 */
bool RvAPI::isRequestActive(const QString &op) const
{
    return m_requests.values().contains(op);
}

QString RvAPI::getRequestOp(QNetworkReply *rep)
{
    return m_requests.value(rep, "");
}

QNetworkReply *RvAPI::getOpRequest(const QString &op)
{
    Q_UNUSED(op)
    return NULL;
}

void RvAPI::setBusy(bool busy)
{
    if (m_busy==busy)
        return;

    m_busy=busy;
    emit busyChanged(m_busy);
}

/**
 * @brief RvAPI::parseErrorResponse
 * @param code
 * @param response
 */
void RvAPI::parseErrorResponse(int code, const QString op, const QByteArray &response)
{
    QVariantMap v=parseJsonResponse(response);

    QVariantMap data=v.value("data").toMap();
    // QVariantMap meta=data.value("meta").toMap();
#ifdef DATA_DEBUG
    qDebug() << "ErrorDATA:\n" << data;
#endif

    if (op==op_auth_login || code==403) {        
        setAuthentication(false);
        const QString error=data.value("error").toString();
        emit loginFailure(error);
        return;
    }

    if (op==op_product_barcode && code==404) {
        // XXX: Signal product not found
        QString msg=v.value("message").toString();
        emit productNotFound(msg);
        return;
    }

    if (op==op_product) {
        QString msg=v.value("message").toString();
        emit productFail(code, msg);
        return;
    }

    if (op==op_products) {
        QString msg=v.value("message").toString();
        emit productsFail(code, msg);
        return;
    }

    // Catch all auth failure, op does not matter if we get an auth error at this point
    if (code==401) {
        QString msg=v.value("message").toString();
        emit requestFailure(code, msg);
        return;
    }

    emit requestFailure(code, m_msg);
}

void RvAPI::parseCategoryMap(const QString key, CategoryModel &model, QVariantMap &tmp)
{
    CategoryModel::FeatureFlags flags;

    //QString id=tmp.value("id").toString();

    if (tmp.value("hasSize").toBool())
        flags|=CategoryModel::HasSize;
    if (tmp.value("hasWeight").toBool())
        flags|=CategoryModel::HasWeight;
    if (tmp.value("hasColor").toBool())
        flags|=CategoryModel::HasColor;
    if (tmp.value("hasStock").toBool())
        flags|=CategoryModel::HasStock;
    if (tmp.value("hasAuthor").toBool())
        flags|=CategoryModel::HasAuthor;
    if (tmp.value("hasMakeAndModel").toBool())
        flags|=CategoryModel::HasMakeAndModel;
    if (tmp.value("hasISBN").toBool())
        flags|=CategoryModel::HasISBN;
    if (tmp.value("hasEAN").toBool())
        flags|=CategoryModel::HasEAN;
    if (tmp.value("hasPrice").toBool())
        flags|=CategoryModel::HasPrice;

    model.addCategory(key, tmp.value("name").toString(), flags);

    if (tmp.contains("subcategories")) {
        QVariantMap smap=tmp.value("subcategories").toMap();
        QMapIterator<QString, QVariant> i(smap);
        CategoryModel *cm=new CategoryModel(key, this);
        while (i.hasNext()) {
            i.next();
            QVariantMap cmap=i.value().toMap();

            parseCategoryMap(i.key(), *cm, cmap);
        }
        m_subcategorymodels.insert(key, cm);
    }
}

bool RvAPI::parseCategoryData(QVariantMap &data)
{
    m_categorymodel.clear();
    m_categorymodel.addCategory("", "", CategoryModel::InvalidCategory);

    QMapIterator<QString, QVariant> i(data);
    while (i.hasNext()) {
        i.next();        
        QVariantMap cmap=i.value().toMap();

        parseCategoryMap(i.key(), m_categorymodel, cmap);
    }

    return true;
}

bool RvAPI::parseLocationData(QVariantMap &data)
{    
    m_locations.clear();

    QMapIterator<QString, QVariant> i(data);
    while (i.hasNext()) {
        i.next();

        QVariantMap tmp=i.value().toMap();

        LocationItem *l=new LocationItem(this);
        l->id=i.key().toInt();
        l->zipcode=tmp.value("zip").toString();
        l->name=tmp.value("location").toString();
        l->street=tmp.value("street").toString();
        l->city=tmp.value("city").toString();
        if (tmp.contains("geo")) {
            QVariantList loc=tmp.value("geo").toList();
            qDebug() << "Got geocoordinates for location: " << loc;
            if (loc.size()==2) {
                l->geo.setLongitude(loc.at(0).toDouble());
                l->geo.setLatitude(loc.at(1).toDouble());
            }
        }
        m_locations.append(l);
    }

    return true;
}

bool RvAPI::haveLocations()
{
    return m_locations.rowCount()==0 ? true : false;
}

bool RvAPI::parseProductData(QVariantMap &data, const QNetworkAccessManager::Operation method)
{
    switch (method) {
    case QNetworkAccessManager::PostOperation:
        emit productSaved(true);
        break;
    case QNetworkAccessManager::PutOperation:
        emit productSaved(false);
        break;
    case QNetworkAccessManager::DeleteOperation:
        emit productDeleted(data["barcode"].toString());
        break;
    default:
        qFatal("Unknown method!");
        return false;
        break;
    }

    ProductItem *p=ProductItem::fromVariantMap(data, this);
    m_product_cache.insert(p->barcode(), p);

    return true;
}

bool RvAPI::parseProductsData(QVariantMap &data)
{    
    uint page=qRound(data["page"].toDouble());
    uint amount=qRound(data["amount"].toDouble());
    QVariantMap products=data["products"].toMap();

    qDebug() << "parseProductsData " << page << " : " << amount;

    if (page==1) {
        m_itemsmodel.clear();
    }

    m_loadedAmount=amount;
    m_loadedPage=page;
    uint requested=ITEMS_MAX; // XXX

    QMapIterator<QString, QVariant> i(products);
    while (i.hasNext()) {
        i.next();

        QVariantMap tmp=i.value().toMap();
        ProductItem *p=ProductItem::fromVariantMap(tmp, this);
        m_itemsmodel.appendProduct(p);
        // m_product_cache.insert(p->barcode(), p);
    }

    qDebug() << "Loaded items: " << m_itemsmodel.rowCount();

    // If we get less than what we ask for then we assume that we are at the end of data.
    setHasMore((amount<requested) ? false : true);

    return true;
}

/**
 * @brief RvAPI::parseLogin
 * @param data
 * @return
 *
 * Parse login response. We don't need to check for OK status values here.
 *
 */
bool RvAPI::parseLogin(QVariantMap &data)
{
    m_authtoken=data.value("apitoken").toString();

    // Check that token is valid
    if (m_authtoken.isEmpty()) {
        setAuthentication(false);
        emit loginFailure("Invalid response");
        return true;
    }

    setAuthentication(true);
    emit loginSuccesfull();

    // Check if response contains app details
    if (data.contains("app")) {
        m_cappversion=data.value("app").toMap().value("version").toInt();
        m_apk=data.value("app").toMap().value("apkg").toString();

        qDebug() << m_apk << m_cappversion << m_appversion;
        if (m_cappversion>m_appversion)
            emit updateAvailable();
    }

    return true;
}

bool RvAPI::parseLogout()
{
    m_authtoken="";
    setAuthentication(false);
    // emit logoutSuccesfull();
    return true;
}

bool RvAPI::parseFileDownload(const QByteArray &data)
{
    QFile f;
    QString fn;

    fn.append(QStandardPaths::writableLocation(QStandardPaths::DownloadLocation));
    fn.append("/app-update-file.apk"); // XXX: Don't hardcode name!

    qDebug() << "Saving downloaded to to " << fn;

    f.setFileName(fn);
    f.open(QIODevice::WriteOnly);
    f.write(data);
    f.close();

    emit updateDownloaded(fn);

    return true;
}

/**
 * @brief RvAPI::parseOKResponse
 * @param op
 * @param response
 */
bool RvAPI::parseOKResponse(const QString op, const QByteArray &response, const QNetworkAccessManager::Operation method)
{
    QVariantMap v=parseJsonResponse(response);

    // JSON failed to parse so bail
    if (v.isEmpty())
        return false;

    QVariantMap data=v.value("data").toMap();
#ifdef DATA_DEBUG
    qDebug() << method << ":" << op << "\nResponse:\n****\n" << data;
#endif

    // Login
    if (op==op_auth_login) {
        return parseLogin(data);
    } else if (op==op_auth_logout) {
        return parseLogout();
    }

    if (op==op_products || op==op_products_search || op==op_product_barcode) {
        bool r=parseProductsData(data);
        emit searchCompleted(m_hasMore);
        return r;
    }

    if (op==op_product)
        return parseProductData(data, method);

    if (op==op_categories)
        return parseCategoryData(data);

    if (op==op_locations)
        return parseLocationData(data);

    if (op==op_download)
        return parseFileDownload(response);

    emit requestSuccessful();
    return true;
}

void RvAPI::parseResponse(QNetworkReply *reply)
{       
    QNetworkReply::NetworkError e = reply->error();

    if (e!=QNetworkReply::NoError)
        qWarning() << "Request error: " << e;

    const QByteArray data = reply->readAll();
    int hc=reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();

#ifdef DATA_DEBUG
    qDebug() << "API request response:";
    qDebug() << "OP: " << reply->operation() << " Code: " << hc;
    qDebug() << "Data:\n" << data;
#endif

    if (!m_requests.contains(reply)) {
        qWarning("Request missing from queue, this should not happen");
        // XXX: Not much we can do if we don't know what happened, anyway this should not happen.
        emit requestFailure(500, "Internal error, unknown request");
        return;
    }

    const QString op=m_requests.value(reply, "");
    m_requests.remove(reply);

    qDebug() << "OP: " << op;

    switch (hc) {
    case 200:
    case 201:
        if (reply->header(QNetworkRequest::ContentTypeHeader)=="application/octet-stream" && op==op_download) {
                if (parseFileDownload(data)==false)
                    emit requestFailure(500, "Unexpected error");
        } else {
            if (parseOKResponse(op, data, reply->operation())==false) {
                emit requestFailure(500, "Unexpected error");
            }
        }
        break;
    case 401:
    case 403:
        qWarning("Authentication error");
        parseErrorResponse(hc, op, data);
        break;
    case 400:
        qWarning("Invalid request failure");
        parseErrorResponse(hc, op, data);
        break;
    case 404:
        qWarning("Not found failure");
        parseErrorResponse(hc, op, data);
        break;
    case 500:
        qWarning("Server failure");
        parseErrorResponse(hc, op, data);
        break;
    case 0:
        qWarning("Generic network failure");
        emit requestFailure(hc, "Network error "+reply->errorString());
        break;
    default: {
        qWarning() << "Unexpected and unhandled response code: " << hc;
        emit requestFailure(hc, "Unexpected error");
        break;
    }
    }

    // If there aren't any other request pending then mark us !busy
    if (m_requests.count()==0)
        setBusy(false);
}

/**
 * @brief RvAPI::createRequestUrl
 * @return base URL with endpoint appended to path
 */
const QUrl RvAPI::createRequestUrl(QString endpoint)
{
    QUrl u=QUrl(m_url);
    QString t=u.path().append(endpoint);

    u.setPath(t);

    return u;
}

void RvAPI::setAuthenticationHeaders(QNetworkRequest *request)
{
    request->setHeader(QNetworkRequest::UserAgentHeader, m_hversion);
    request->setRawHeader(QByteArray("Accept"), "application/json");
    if (!m_apikey.isEmpty())
        request->setRawHeader(QByteArray("X-AuthenticationKey"), m_apikey.toUtf8());
    else
        qWarning("API Key is not set! This won't work at all.");
    if (!m_authtoken.isEmpty())
        request->setRawHeader(QByteArray("X-Auth-Token"), m_authtoken.toUtf8());
}

void RvAPI::queueRequest(QNetworkReply *req, const QString op)
{
    m_requests.insert(req, op);
    setBusy(true);
}

/**
 * @brief RvAPI::login
 * @return bool
 *
 * Start login procedure. Success or failure is signaled with loginSuccess() or loginFailure() signals
 *
 * Returns: true if initiated ok, false if any necessary setting is missing (user,pass,url,etc)
 *
 */
bool RvAPI::login()
{    
    if (m_url.isEmpty()) {
        qWarning("API urls is not set ");
        return false;
    }

    if (m_username.isEmpty() || m_password.isEmpty()) {
        qWarning("Username or password is not set ");
        return false;
    }

    if (isRequestActive(op_auth_login)) {
        qDebug("Login request is already active");
        return false;
    }

    QNetworkRequest request(createRequestUrl(op_auth_login));
    setAuthenticationHeaders(&request);
    QHttpMultiPart *mp = new QHttpMultiPart(QHttpMultiPart::FormDataType);

    addParameter(mp, QStringLiteral("username"), m_username);
    addParameter(mp, QStringLiteral("password"), m_password);
    addParameter(mp, QStringLiteral("apiversion"), m_apiversion);
    addParameter(mp, QStringLiteral("appversion"), m_appversion);

    queueRequest(post(request, mp), op_auth_login);

    return true;
}

/**
 * @brief RvAPI::logout
 * @return
 */
bool RvAPI::logout()
{
    if (isRequestActive(op_auth_logout))
        return false;

    if (m_authtoken.isEmpty())
        return true;

    QNetworkRequest request(createRequestUrl(op_auth_logout));
    setAuthenticationHeaders(&request);

    QHttpMultiPart *mp = new QHttpMultiPart(QHttpMultiPart::FormDataType);

    queueRequest(post(request, mp), op_auth_logout);

    return true;
}

void RvAPI::setAppVersion(uint ver)
{
    m_appversion=ver;
}

bool RvAPI::products(uint page, uint amount, const QString category, const QString search)
{
    if (!m_authenticated)
        return false;

    if (amount>ITEMS_MAX || amount==0)
        amount=ITEMS_MAX;

    if (isRequestActive(op_products))
        return false;

    qDebug() << m_loadedPage;

    if (page==0 && m_loadedPage>0 && m_hasMore) {// Load next page
        page=m_loadedPage+1;
        qDebug() << "Loading next page " << page;
    } else if (page==0) {
        qWarning() << "Initial page not loaded yet";
        return false;
    } else {
        m_loadedPage=page;
        qDebug() << "Loading page " << page;
    }

    QUrl url=createRequestUrl(op_products);
    QUrlQuery query;
    QNetworkRequest request;

    setAuthenticationHeaders(&request);

    QString tmp;

    query.addQueryItem("page", tmp.setNum(page));
    query.addQueryItem("amount", tmp.setNum(amount));

    if (!category.isEmpty()) {
        query.addQueryItem("category", category);
    }
    if (!search.isEmpty()) {
        query.addQueryItem("q", search);
        // XXX: Remove when API fixed
        query.addQueryItem("string", search);
    }

    url.setQuery(query);
    request.setUrl(url);

    queueRequest(get(request), op_products);

    return true;
}

bool RvAPI::searchCancel()
{
    if (!m_authenticated)
        return false;

    if (isRequestActive(op_products_search))
        return false;

    return false;
}

/**
 * @brief RvAPI::searchBarcode
 * @param barcode
 * @param checkOnly
 * @return
 *
 * Search for specific product by barcode. Optionally just request check if product exists or not.
 *
 */
bool RvAPI::searchBarcode(const QString barcode, bool checkOnly)
{       
    if (!m_authenticated)
        return false;

    // XXX: Check properly that barcode is in valid format (AAA123123123)
    if (barcode.isEmpty())
        return false;

    // Allow for old format (AAA123456) and new (AAA123456789)
    if (barcode.size()!=9 && barcode.size()!=12)
        return false;

    if (isRequestActive(op_product_barcode))
        return false;

    QUrl url=createRequestUrl(op_product_barcode+"/"+barcode);
    QUrlQuery query;
    QNetworkRequest request;

    setAuthenticationHeaders(&request);

    //query.addQueryItem("barcode", barcode);

    //url.setQuery(query.query());
    request.setUrl(url);

    QNetworkReply *req;

    req=checkOnly ? head(request) : get(request);
    queueRequest(req, op_product_barcode);

    return true;
}

/**
 * @brief RvAPI::add
 * @param product
 * @return
 *
 * Add a new ProductItem
 *
 */
bool RvAPI::add(ProductItem *product)
{    
    if (!m_authenticated)
        return false;

    if (isRequestActive(op_product))
        return false;

    QUrl url=createRequestUrl(op_product);
    QNetworkRequest request;
    setAuthenticationHeaders(&request);

    QHttpMultiPart *mp = new QHttpMultiPart(QHttpMultiPart::FormDataType);

    // XXX Handle multibarcode add
    QString bc=product->getBarcode();

    addParameter(mp, QStringLiteral("barcode"), bc);
    addParameter(mp, QStringLiteral("title"), product->getTitle());
    addParameter(mp, QStringLiteral("category"), product->category());
    addParameter(mp, QStringLiteral("subcategory"), product->subCategory());
    addParameter(mp, QStringLiteral("description"), product->getDescription());
    uint s=product->getStock();
    if (s!=1) {
        QString num;
        addParameter(mp, QStringLiteral("stock"), num.setNum(s));
    }
    double p=product->getPrice();
    if (p>0.0) {
        QString num;
        addParameter(mp, QStringLiteral("price"), num.setNum(p,'f',2));
        addParameter(mp, QStringLiteral("tax"), product->getTax());
    }

    // Add attributes
    // XXX: We don't check for category required attributes here, should we bother ?
    for (int i = 0; i < m_attributes.size(); i++) {
        QString a=m_attributes.at(i);

        if (product->hasAttribute(a)) {
            addParameter(mp, a, product->getAttribute(a).toString());
        }
    }

    // Add images
    QVariantList imf=product->images();

    qDebug() << "Images are: " << imf;

    for (int i = 0; i < imf.size(); i++) {
        bool r;
        QString f=imf.at(i).toString();
        QUrl fu(f);

        qDebug() << fu;
        if (!fu.isLocalFile()) {
            qWarning("File is not local, can not use!");
            continue;
        }

        r=addFilePart(mp, "sku-"+bc+"-", fu.toLocalFile());
        if (!r) {
            qWarning() << "Failed to open file for uploading: " << f;
        }
    }

    // XXX: Add any extras, check against somekind of category specific flags or something like that

    request.setUrl(url);

    queueRequest(post(request, mp), op_product);

    return true;
}

/**
 * @brief RvAPI::update
 * @param product
 * @return
 *
 * Update information of given ProductItem. The product must have a valid identifier.
 *
 */
bool RvAPI::update(ProductItem *product)
{
    Q_UNUSED(product)
    qWarning("Product update is not yet implemented!");
    return false;

    if (!m_authenticated)
        return false;

    if (isRequestActive(op_product))
        return false;

    QUrl url=createRequestUrl(op_product);
    QNetworkRequest request;
    setAuthenticationHeaders(&request);

    QHttpMultiPart *mp = new QHttpMultiPart(QHttpMultiPart::FormDataType);

    // XXX: Needs to be implemented

    request.setUrl(url);
    queueRequest(post(request, mp), op_product);

    return true;
}

/**
 * @brief RvAPI::getImageUrl
 * @param image
 * @return
 *
 * Just in case we need to do something special with the images, we route the url trough here
 * even though the URL, at this time, is a full absolute url.
 *
 */
QUrl RvAPI::getImageUrl(const QString image)
{
    QUrl u=QUrl(image);

    return u;
}

bool RvAPI::requestLocations()
{
    if (!m_authenticated)
        return false;

    if (isRequestActive(op_locations))
        return false;

    QUrl url=createRequestUrl(op_locations);
    QNetworkRequest request;
    setAuthenticationHeaders(&request);

    request.setUrl(url);    
    queueRequest(get(request), op_locations);

    return true;
}

bool RvAPI::requestCategories()
{
    if (!m_authenticated)
        return false;

    if (isRequestActive(op_categories))
        return false;

    QUrl url=createRequestUrl(op_categories);
    QNetworkRequest request;
    setAuthenticationHeaders(&request);

    request.setUrl(url);
    queueRequest(get(request), op_categories);

    return true;
}

bool RvAPI::validateBarcode(const QString barcode) const
{
    QRegularExpression r("^[A-Z]{3}[0-9]{6,9}$");

    if (!r.isValid()) {
        qWarning("Invalid barcode regular expression");
        return false;
    }
    QRegularExpressionMatch match = r.match(barcode);
    return match.hasMatch();
}

bool RvAPI::validateBarcodeEAN(const QString code) const
{
    int val=0;

    if (code.length()!=13)
        return false;

    for (int i=0;i<12;i++) {
        const QChar c=code.at(i);
        if (c.isDigit()==false)
            return false;

        val+=c.digitValue()*((i % 2==0) ? 1 : 3);
    }
    int cd=(10-(val % 10)) % 10;

    return code.at(12).digitValue()==cd ? true : false;
}

ItemListModel *RvAPI::getItemModel()
{    
    return &m_itemsmodel;
}

LocationListModel *RvAPI::getLocationsModel()
{
    return &m_locations;
}

CategoryModel *RvAPI::getCategoryModel()
{    
    return &m_categorymodel;
}

CategoryModel *RvAPI::getSubCategoryModel(const QString key)
{
    return m_subcategorymodels.value(key, Q_NULLPTR);
}

QStringListModel *RvAPI::getTaxModel()
{
    return &m_tax_model;
}

bool RvAPI::downloadUpdate()
{
    if (!m_authenticated)
        return false;

    if (isRequestActive(op_download))
        return false;

    QUrl url=createRequestUrl(op_download);
    QNetworkRequest request;
    setAuthenticationHeaders(&request);

    request.setUrl(url);

    queueRequest(get(request), op_download);

    return true;
}

bool RvAPI::authenticated() const
{
    return m_authenticated;
}

bool RvAPI::hasMore() const
{
    return m_hasMore;
}


