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

#include <QNetworkProxy>

#include <QDir>

//#define LOGIN_DEBUG 1
//#define DATA_DEBUG 1
//#define JSON_DEBUG 1
//#define SECURE_DEBUG 1

// We disable network cache as there seem to be some issues with stale data when network errors happen
//#define ENABLE_CACHE 1

// Should Barcode/SKU follow a strict pattern or not
#ifndef BARCODE_REGEXP
#define BARCODE_REGEXP "^[A-Z]{3}[0-9]{6,9}$"
#define STRICT_BARCODE_FORMAT 1
#endif

#define REQUIRED_API_VERSION (4)

// Keep this at what proxy API enforces, currently set to 100
#define ITEMS_MAX (100)

RvAPI::RvAPI(QObject *parent) :
    QObject(parent),
    m_NetManager(new QNetworkAccessManager(this)),
    m_apiversion(1),
    m_appversion(0),
    m_authenticated(false),
    m_busy(false),
    m_hasMore(false),
    m_loadedPage(0),
    m_organization_model(this),
    m_color_model(this),
    m_itemsmodel(&m_product_store, this),
    m_cartmodel(this),
    m_categorymodel(nullptr, this),
    m_locations(this),
    m_ordersmodel(this),
    m_tax_model(this)
{

    connect(m_NetManager,SIGNAL(sslErrors(QNetworkReply*,QList<QSslError>)),this,SLOT(onIgnoreSSLErrors(QNetworkReply*,QList<QSslError>)));
    //connect(m_NetManager,SIGNAL(authenticationRequired()), this, SLOT(authenticationRequired));
    connect(m_NetManager, &QNetworkAccessManager::authenticationRequired, this, &RvAPI::authenticationRequired);

#ifdef ENABLE_CACHE
    QNetworkDiskCache *diskCache = new QNetworkDiskCache(this);
    diskCache->setCacheDirectory(QStandardPaths::writableLocation(QStandardPaths::CacheLocation));
    m_NetManager->setCache(diskCache);
#endif

    // Create network request application header string
    m_hversion=QString("RW/%1").arg(QCoreApplication::applicationVersion());

    // Load supported organizations from profiles
    QDir profiles(":/profiles");
    QStringList filters;
    filters << "*.json";
    profiles.setNameFilters(filters);

    // qDebug() << "Profiles available:" << profiles.entryList();

    // String fields to copy from JSON object
    QStringList fields;
    fields << "code" << "name" << "apiKey" << "apiUrlProduction" << "apiUrlSandbox";

    foreach(const QString &profileName, profiles.entryList() ) {
        QFile file(":/profiles/"+profileName);
        file.open(QIODevice::ReadOnly);

        QByteArray data=file.readAll();
        QJsonDocument json=QJsonDocument::fromJson(data);
        if (json.isNull() || json.isEmpty()) {
            qWarning() << "Invalid profile JSON" << profileName;
            continue;
        }
        QVariantMap profileMap=json.object().toVariantMap();

        OrganizationItem *org=new OrganizationItem();
        foreach(const QString &field, fields) {
            // qDebug() << field << profileMap.value(field).toString();
            org->setProperty(field.toLocal8Bit(), profileMap.value(field).toString());
        }

        m_organization_model.append(org);
    }

    // Monitor network connection
    m_netconf=new QNetworkConfigurationManager();
    QObject::connect(m_netconf, SIGNAL(onlineStateChanged(bool)), this, SLOT(onNetworkOnlineChanged(bool)));
    onNetworkOnlineChanged(m_netconf->isOnline());

    // Valid product attributes
    m_attributes << "width" << "height" << "depth" << "weight" << "color" << "ean" << "isbn" << "purpose" << "manufacturer" << "model" << "author" << "location" << "locationdetail";

    m_taxes << "0%" << "24%" << "14%" << "10%";
    m_tax_model.setStringList(m_taxes);

    // Order status Enum to API text map
    m_order_status_str.insert(OrderItem::Cancelled, "canceled");
    m_order_status_str.insert(OrderItem::Pending, "pending");
    m_order_status_str.insert(OrderItem::Processing, "processing");
    m_order_status_str.insert(OrderItem::Shipped, "completed");
    m_order_status_str.insert(OrderItem::Cart, "cart");
}

RvAPI::~RvAPI()
{    
    clearSession();
}

void RvAPI::clearCache()
{
#ifdef ENABLE_CACHE
    m_NetManager->cache()->clear();
#endif
}

void RvAPI::setUrl(QUrl url)
{
    if (m_url == url)
        return;

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

    m_hasMore=hasmore;
    emit hasMoreChanged(hasmore);
}

void RvAPI::setAuthentication(bool auth)
{
    if (auth==false) {
        m_uid=0;
        m_lastlogin=QDateTime::fromSecsSinceEpoch(0);
        m_roles.clear();
    }
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

/**
 * @brief RvAPI::authenticationRequired
 * @param reply
 * @param authenticator
 *
 * Set authentication credential in case API endpoint is behind extra layer of logins.
 *
 */
void RvAPI::authenticationRequired(QNetworkReply *reply, QAuthenticator *authenticator)
{
    qDebug("authenticationRequired");
#if defined(DEVEL_SANDBOX_AUTH_USERNAME) && defined(DEVEL_SANDBOX_AUTH_PASSWORD)
    authenticator->setUser(DEVEL_SANDBOX_AUTH_USERNAME);
    authenticator->setPassword(DEVEL_SANDBOX_AUTH_PASSWORD);
#else
    qWarning("Extra authentication not set");
#endif
}

void RvAPI::requestError(QNetworkReply::NetworkError code)
{
    qWarning() << "Request error: " << code;
    switch(code) {
    case QNetworkReply::ConnectionRefusedError:
        break;
    case QNetworkReply::ContentOperationNotPermittedError:
        break;
    case QNetworkReply::HostNotFoundError:
        break;
    case QNetworkReply::OperationCanceledError:
        break;
    case QNetworkReply::ProtocolInvalidOperationError:
        break;
    case QNetworkReply::TimeoutError:
        break;
    default:
        qWarning() << "Unhandled request error: " << code;
        break;
    }
}

void RvAPI::uploadProgress(qint64 bytes, qint64 total)
{
    quint8 p;
    //QNetworkReply * reply = qobject_cast<QNetworkReply*>(sender());

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

void RvAPI::onNetworkOnlineChanged(bool online)
{
    m_isonline=online;
    emit isOnlineChanged(online);
}

void RvAPI::clearProductStore()
{    
    m_itemsmodel.clear();
    m_cartmodel.clear();
    qDeleteAll(m_product_store);
    m_product_store.clear();
}

void RvAPI::setProxy(const QString server, quint16 port, const QString user, const QString password)
{
    if (server.isEmpty()) {
        m_NetManager->setProxy(QNetworkProxy::NoProxy);
    } else {
        QNetworkProxy proxy;
        proxy.setType(QNetworkProxy::HttpProxy);
        proxy.setHostName(server);
        proxy.setPort(port);
        proxy.setUser(user);
        proxy.setPassword(password);
        m_NetManager->setProxy(proxy);
    }
}

void RvAPI::clearProductFilters()
{
    m_searchsort=SortDateDesc;
    m_searchstring.clear();
    m_searchcategory.clear();

    emit searchCategoryChanged();
    emit searchStringChanged();
    emit searchSortChanged();
}

bool RvAPI::parseJsonResponse(const QByteArray &data, QVariantMap &map)
{
    QJsonDocument json=QJsonDocument::fromJson(data);
    QVariantMap vm;

    if (json.isEmpty() || json.isNull()) {
        qWarning() << "API gave invalid response, unable to parse as JSON!" << data << json.isEmpty() << json.isNull();
        return false;
    }

    if (!json.isObject()) {
        qWarning() << "API gave invalid response, not an object" << data;
        return false;
    }

    vm=json.object().toVariantMap();

    // Make sure the response has the fields we use, and that they are what they should be
    if (vm.value("version").toInt()!=REQUIRED_API_VERSION) {
        qWarning() << "Unknown API response version, need" << REQUIRED_API_VERSION << "got" << vm.value("version").toInt();
        return false;
    }

    if (vm.contains("code")==false) {
        qWarning("Missing response result code");
        return false;
    }

    if (vm.contains("data")==false) {
        qWarning("Missing response data");
        return false;
    }

    map=vm;

    return true;
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
 * @brief RvAPI::put
 * @param request
 * @param mp
 * @return
 */
QNetworkReply *RvAPI::put(QNetworkRequest &request, QHttpMultiPart *mp)
{
    QNetworkReply *reply;

    reply = m_NetManager->put(request, mp);
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

bool RvAPI::cancelOperation(RequestOps op)
{
    auto v=m_requests.values();
    auto k=m_requests.keys();

    if (!v.contains(op)) {
        return false;
    }
    int i=v.indexOf(op);
    if (i==-1)
        return false;

    QNetworkReply *r=k.at(i);
    Q_ASSERT(r);

    r->abort();

    return true;
}

/**
 * @brief RvAPI::isRequestActive
 * @param op
 * @return true if op is already active, false otherwise
 *
 * Check request list if operation is already in progress.
 *
 */
bool RvAPI::isRequestActive(RequestOps op) const
{
    return m_requests.values().contains(op);
}

RvAPI::RequestOps RvAPI::getRequestOp(QNetworkReply *rep)
{
    return m_requests.value(rep, UnknownOperation);
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
 *
 * Handle error response cases. Takes care of both query response errors and network related errors.
 *
 * Operation specific signals are used where applicable:
 * - Login && 403
 * - Product not found
 * - Product and Products loading failure
 *
 * Generic auth error in case of 401
 *
 */
void RvAPI::parseErrorResponse(int code, QNetworkReply::NetworkError e, RequestOps op, const QByteArray &response)
{
    QVariantMap v;

    // Is it a network error ?
    if (code==0) {
        switch (e) {
        case QNetworkReply::OperationCanceledError:
            // XXX: How should we handle this ?
            if (op==AuthLogin)
                emit loginCanceled();
            else
                emit requestFailure(500, e, tr("Network operation was canceled"));
            return;
        case QNetworkReply::ContentAccessDenied:
        case QNetworkReply::ContentOperationNotPermittedError:
            emit requestFailure(403, e, tr("Access denied"));
            return;
        case QNetworkReply::ContentNotFoundError:
            emit requestFailure(404, e, tr("API endpoint not found"));
            return;
        case QNetworkReply::TimeoutError:
            emit requestFailure(500, e, tr("Server connection timeout"));
            return;
        case QNetworkReply::ConnectionRefusedError:
            emit requestFailure(500, e, tr("Server connection error"));
            return;
        case QNetworkReply::RemoteHostClosedError:
            emit requestFailure(500, e, tr("Server closed connection error"));
            return;
        case QNetworkReply::HostNotFoundError:
            emit requestFailure(500, e, tr("Server not found"));
            return;
        case QNetworkReply::SslHandshakeFailedError:
            emit requestFailure(500, e, tr("Failed to establish secure connection"));
            return;
        case QNetworkReply::ProxyConnectionRefusedError:
        case QNetworkReply::ProxyConnectionClosedError:
        case QNetworkReply::ProxyNotFoundError:
        case QNetworkReply::ProxyTimeoutError:
        case QNetworkReply::ProxyAuthenticationRequiredError:
            emit requestFailure(500, e, tr("Proxy error"));
            return;
        case QNetworkReply::UnknownNetworkError:
            emit requestFailure(500, e, tr("Unknown network error"));
            return;
        default:;
        }
        emit requestFailure(500, e, tr("Generic network error"));
        return;
    }

    if (parseJsonResponse(response, v)==false) {
        emit requestFailure(500, QNetworkReply::UnknownServerError, tr("Invalid server response"));
        return;
    }
    QVariantMap data=v.value("data").toMap();

    if (op==AuthLogin || code==403) {
        setAuthentication(false);
        const QString error=data.value("error").toString();
        emit loginFailure(error, code==0 ? e+1000 : code);
        return;
    }

    if (op==ProductSearchBarcode && code==404) {
        emit productNotFound(v.value("message").toString());
        return;
    }

    if (op==Product && code==404) {
        emit productNotFound(v.value("message").toString());
        return;
    }

    if (op==ProductAdd || op==ProductUpdate) {
        emit productFail(code, v.value("message").toString());
        return;
    }

    if (op==Products) {
        emit productsFail(code, v.value("message").toString());
        return;
    }

    if (op==CheckoutCart && code==409) {
        emit cartProductOutOfStock();
        return;
    }

    if (op==AddToCart && code==409) {
        emit productOutOfStock();
        return;
    }

    // Catch all auth failure, op does not matter if we get an auth error at this point
    if (code==401) {
        emit requestFailure(code, e, v.value("message").toString());
        return;
    }

    // Catch all other error cases here
    emit requestFailure(code, e, m_msg);
}

#define checkFlag(_key, _flag) { if (tmp.contains(_key)) flags.setFlag(_flag, tmp.value(_key).toBool()); }

void RvAPI::parseCategoryMap(const QString key, CategoryModel &model, QVariantMap &tmp, CategoryModel::FeatureFlags flags)
{    
    //QString id=tmp.value("id").toString();

    checkFlag("hasSize", CategoryModel::HasSize);
    checkFlag("hasWeight", CategoryModel::HasWeight);
    checkFlag("hasColor", CategoryModel::HasColor);

    checkFlag("hasStock", CategoryModel::HasStock);
    checkFlag("hasAuthor", CategoryModel::HasAuthor);
    checkFlag("hasMakeAndModel", CategoryModel::HasMakeAndModel);

    checkFlag("hasISBN", CategoryModel::HasISBN);
    checkFlag("hasEAN", CategoryModel::HasEAN);

    checkFlag("hasPrice", CategoryModel::HasPrice);
    checkFlag("hasValue", CategoryModel::HasValue);
    checkFlag("hasPurpose", CategoryModel::HasPurpose);

    model.addCategory(key, tmp.value("name").toString(), flags);

    if (tmp.contains("subcategories")) {
        QVariantMap smap=tmp.value("subcategories").toMap();
        QMapIterator<QString, QVariant> i(smap);
        CategoryModel *cm=new CategoryModel(key, this);
        while (i.hasNext()) {
            i.next();
            QVariantMap cmap=i.value().toMap();

            parseCategoryMap(i.key(), *cm, cmap, flags);
        }
        m_subcategorymodels.insert(key, cm);
    }
}

bool RvAPI::parseColorsData(QVariantMap &data)
{
    qDebug() << "ColorData: " << data;

    if (data.isEmpty())
        return false;

    m_color_model.clear();

    // Add the default dummy
    m_color_model.append(new ColorItem("", "", "transparent", &m_color_model));


    QMapIterator<QString, QVariant> i(data);
    while(i.hasNext()) {
        i.next();

        QVariantMap cm=i.value().toMap();

        qDebug() << "ColorMap: " << cm;

        ColorItem *ci=new ColorItem(cm.value("cid").toString(), cm.value("color").toString(), cm.value("code").toString(), &m_color_model);
        m_color_model.append(ci);
    }

    return true;
}

/**
 * @brief RvAPI::createStaticColorModel
 *
 * Create fallback static color model in case server request fails
 */
void RvAPI::createStaticColorModel()
{
    m_color_model.clear();

    m_color_model.append(new ColorItem("", "", "transparent"));

    m_color_model.append(new ColorItem("black", tr("Black"), "#000000"));
    m_color_model.append(new ColorItem("brown", tr("Brown"), "#ab711a"));
    m_color_model.append(new ColorItem("grey", tr("Grey"), "#a0a0a0"));
    m_color_model.append(new ColorItem("white", tr("White"), "#ffffff"));

    m_color_model.append(new ColorItem("blue", tr("Blue"), "#0000ff"));
    m_color_model.append(new ColorItem("green", tr("Green"), "#00ff00"));
    m_color_model.append(new ColorItem("red", tr("Red"), "#ff0000"));
    m_color_model.append(new ColorItem("yellow", tr("Yellow"), "#ffff00"));
    m_color_model.append(new ColorItem("pink", tr("Pink"), "#ff53a6"));
    m_color_model.append(new ColorItem("orange", tr("Orange"), "#ff9800"));
    m_color_model.append(new ColorItem("cyan", tr("Cyan"), "#00FFFF"));
    m_color_model.append(new ColorItem("violet", tr("Violet"), "#800080"));

    m_color_model.append(new ColorItem("multi", tr("Multicolor"), "#transparent"));

    m_color_model.append(new ColorItem("gold", tr("Gold"), "#FFD700"));
    m_color_model.append(new ColorItem("silver", tr("Silver"), "#C0C0C0"));
    m_color_model.append(new ColorItem("chrome", tr("Chrome"), "#DBE4EB"));

    m_color_model.append(new ColorItem("walnut", tr("Walnut"), "#443028"));
    m_color_model.append(new ColorItem("oak", tr("Oak"), "#806517"));
    m_color_model.append(new ColorItem("birch", tr("Birch"), "#f8dfa1"));
    m_color_model.append(new ColorItem("beech", tr("Beech"), "#cdaa88"));
}

bool RvAPI::parseOrderCreated(QVariantMap &data)
{
    emit orderCreated();

    return true;
}

bool RvAPI::parseCartCheckout(QVariantMap &data)
{
    emit cartCheckout();

    return true;
}

bool RvAPI::parseOrderStatusUpdate(QVariantMap &data)
{    
    int id=data["id"].toInt();

    OrderItem *oi=dynamic_cast<OrderItem *>(m_ordersmodel.getId(id));
    if (!oi) {
        qWarning("Updated order not found in our orders list");
        return false;
    }

    oi->updateFromVariantMap(data);

    emit orderStatusUpdated();

    return true;
}

bool RvAPI::parseOrders(QVariantMap &data)
{
    QVariantList orders=data.value("orders").toList();

    m_ordersmodel.clear();
    m_orders.clear();

    QListIterator<QVariant> i(orders);
    while (i.hasNext()) {
        auto om=i.next().toMap();

        OrderItem *o=OrderItem::fromVariantMap(om, this);
        m_orders.append(o);
    }

    m_ordersmodel.setList(m_orders);

    return true;
}

bool RvAPI::parseCart(QVariantMap &data)
{
    QVariantList cart=data.value("items").toList();

    m_cartmodel.clear();

    QListIterator<QVariant> i(cart);
    while (i.hasNext()) {
        auto om=i.next().toMap();

        qDebug() << om;

        OrderLineItem *o=OrderLineItem::fromVariantMap(om, this);
        m_cartmodel.append(o);
    }

    return true;
}

bool RvAPI::parseCategoryData(QVariantMap &data)
{
    m_categorymodel.clear();
    m_categorymodel.addCategory("", "", CategoryModel::InvalidCategory);

    QMapIterator<QString, QVariant> i(data);
    while (i.hasNext()) {
        i.next();
        QVariantMap cmap=i.value().toMap();
        CategoryModel::FeatureFlags default_flags;

        parseCategoryMap(i.key(), m_categorymodel, cmap, default_flags);
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
        l->id=i.key().toUInt();
        l->zipcode=tmp.value("zip").toString();
        l->name=tmp.value("location").toString();
        l->street=tmp.value("street").toString();
        l->city=tmp.value("city").toString();

        // Optional geo-location
        if (tmp.contains("geo")) {
            QVariantList loc=tmp.value("geo").toList();
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

bool RvAPI::isOrderEmpty()
{
    return m_cartmodel.count()==0 ? true : false;
}

/**
 * @brief RvAPI::parseProductData
 * @param data
 * @param method
 * @return
 */
bool RvAPI::parseProductData(QVariantMap &data, const QNetworkAccessManager::Operation method)
{
    switch (method) {
    case QNetworkAccessManager::HeadOperation:
        emit productFound(nullptr);
        return true;
    case QNetworkAccessManager::DeleteOperation:
        emit productDeleted(data["barcode"].toString());
        return true;
    case QNetworkAccessManager::GetOperation: {
        ProductItem *p=ProductItem::fromVariantMap(data, this);
        m_product_store.insert(p->barcode(), p);
        if (m_itemsmodel.contains(p->barcode()))
            m_itemsmodel.update(p);
        else
            m_itemsmodel.append(p);
        emit productFound(p);
    }
        return true;
    case QNetworkAccessManager::PostOperation: {
        ProductItem *p=ProductItem::fromVariantMap(data, this);
        m_product_store.insert(p->barcode(), p);
        if (m_itemsmodel.contains(p->barcode()))
            m_itemsmodel.update(p);
        else
            m_itemsmodel.prepend(p);
        emit productSaved(p, true);
    }
        return true;
    case QNetworkAccessManager::PutOperation: {
        ProductItem *p=ProductItem::fromVariantMap(data, this);
        m_product_store.insert(p->barcode(), p);
        emit productSaved(p, false);
    }
        return true;
    default:
        qCritical("Unhandled product method!");
    }
    return false;
}

bool RvAPI::parseProductsData(QVariantMap &data)
{
    uint page=qRound(data["page"].toDouble());
    uint amount=qRound(data["amount"].toDouble());
    uint requested=qRound(data["ramount"].toDouble());
    QVariantList products=data["products"].toList();

    if (page==1) {
        //m_itemsmodel.clear();
        clearProductStore();
        m_itemsmodel.clear();
    }

    m_loadedAmount=amount;
    m_loadedPage=page;

    QListIterator<QVariant> i(products);
    while (i.hasNext()) {
        QVariantMap tmp=i.next().toMap();
        ProductItem *p=ProductItem::fromVariantMap(tmp, this);
        m_product_store.insert(p->barcode(), p);
        m_itemsmodel.append(p);
    }

    // If we get less than what we ask for then we assume that we are at the end of data.
    //XXX
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
        emit loginFailure("Invalid response", 500);
        return true;
    }

    // Store our UID
    m_uid=data.value("uid").toString().toUInt();

    m_lastlogin=QDateTime::fromSecsSinceEpoch(data["access"].toString().toLong());

    // We only care about the string values
    m_roles=data.value("roles").toList();    

    setAuthentication(true);
    emit loginSuccesfull();

    // Check if response contains app details
    if (data.contains("app")) {
        m_cappversion=data.value("app").toMap().value("version").toInt();
        m_apk=data.value("app").toMap().value("apkg").toString();

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
bool RvAPI::parseOKResponse(RequestOps op, const QByteArray &response, const QNetworkAccessManager::Operation method)
{
    QVariantMap v;

    if (parseJsonResponse(response, v)==false) {
        return false;
    }

    QVariantMap data=v.value("data").toMap();

#ifdef QT_DEBUG
    qDebug() << "parseOKResponse" << method << ":" << op << response;
#endif

    switch (op) {
    case RvAPI::AuthLogin:
        return parseLogin(data);
    case RvAPI::AuthLogout:
        return parseLogout();
    case RvAPI::ProductSearch:
    case RvAPI::ProductSearchBarcode: {
        bool r=parseProductsData(data);
        emit searchCompleted(m_hasMore, r);
        return r;
    }
    case RvAPI::Product:
    case RvAPI::ProductAdd:
    case RvAPI::ProductUpdate: {
        QVariantMap product=data.value("response").toMap();
        return parseProductData(product, method);
    }
    case RvAPI::Products: {
        bool r=parseProductsData(data);
        emit searchCompleted(m_hasMore, r);
        return r;
    }
    case RvAPI::Categories:
        return parseCategoryData(data);
    case RvAPI::Locations:
        return parseLocationData(data);
    case RvAPI::Colors:
        return parseColorsData(data);
    case RvAPI::Orders:
        if (method==QNetworkAccessManager::PostOperation)
            return parseOrderCreated(data);
        else if (method==QNetworkAccessManager::GetOperation)
            return parseOrders(data);
        else
            return false;
    case RvAPI::OrderUpdateStatus:
        if (method==QNetworkAccessManager::PostOperation)
            return parseOrderStatusUpdate(data);
        break;
    case RvAPI::Cart:
        return parseCart(data);
        break;
    case RvAPI::AddToCart:
        if (method==QNetworkAccessManager::PostOperation) {
            emit productAddedToCart();
            return true; //xxx
        }
        break;
    case RvAPI::CheckoutCart:
        if (method==QNetworkAccessManager::PostOperation)
            return parseCartCheckout(data);
        break;
    case RvAPI::ClearCart:
        if (method==QNetworkAccessManager::PostOperation) {
            emit cartCleared();
            return true;
        }
        break;
    case RvAPI::DownloadAPK:
        return parseFileDownload(response);
    default:
        qCritical() << "Unknown operation returned" << op;
        break;
    }

    return false;
}

void RvAPI::parseResponse(QNetworkReply *reply)
{       
    const QNetworkReply::NetworkError e = reply->error();
    const QByteArray data = reply->readAll();
    int hc=reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();

    if (!m_requests.contains(reply)) {
        qWarning("Request missing from queue, this should not happen");
        // XXX: Not much we can do if we don't know what happened, anyway this should not happen.
        emit requestFailure(500, 0, "Unknown request queued");
        return;
    }

    RequestOps op=m_requests.value(reply, UnknownOperation);
    m_requests.remove(reply);

#ifdef QT_DEBUG
    qDebug() << "parseResponse: " << e << hc << op << reply->header(QNetworkRequest::ContentTypeHeader) << reply->url();
    qDebug() << "Data:\n" << data;
#endif

    switch (hc) {
    case 200:
    case 201:
        if (reply->header(QNetworkRequest::ContentTypeHeader)=="application/octet-stream" && op==DownloadAPK) {
            if (parseFileDownload(data)==false)
                emit requestFailure(500, 0, "Failed to parse downloaded file");
        } else {
            if (parseOKResponse(op, data, reply->operation())==false) {
                emit requestFailure(500, QNetworkReply::UnknownServerError, "Error in response");
            }
        }
        break;
    case 400: // HTTP error codes
    case 401: // Unauthorized
    case 403: // Forbidden
    case 404: // Not found
    case 409: // Conflict
    case 500: // Internal error
    case 504: // Timeout
        parseErrorResponse(hc, e, op, data);
        break;
    case 0: // Network error
        parseErrorResponse(hc, e, op, data);
        break;
    default: {
        qWarning() << "Unexpected and unhandled response code: " << hc;
        emit requestFailure(hc, e, reply->errorString());
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
const QUrl RvAPI::createRequestUrl(const QString &endpoint, const QString &detail)
{
    QUrl u=QUrl(m_url);
    QString t=u.path().append(endpoint);
    if (detail!=nullptr) {
        t.append("/").append(detail);
    }

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

void RvAPI::queueRequest(QNetworkReply *req, RequestOps op)
{
    m_requests.insert(req, op);
    setBusy(true);
}

/**
 * @brief RvAPI::createSimpleAuthenticatedRequest
 * @param op
 * @return false if not authenticated or operation is already in progress
 *
 * Create a GET operation request with auth headers and queue it.
 *
 */
bool RvAPI::createSimpleAuthenticatedRequest(const QString opurl, RequestOps op, QVariantMap *params)
{
    if (!m_authenticated)
        return false;

    if (isRequestActive(op))
        return false;

    QUrl url=createRequestUrl(opurl);
    QUrlQuery query;
    QNetworkRequest request;
    setAuthenticationHeaders(&request);

    if (params) {
        QMapIterator<QString, QVariant> i(*params);
        while (i.hasNext()) {
            i.next();
            query.addQueryItem(i.key(), i.value().toString());
        }
    }

    url.setQuery(query);
    request.setUrl(url);
    queueRequest(get(request), op);

    return true;
}

bool RvAPI::createSimpleAuthenticatedPostRequest(const QString opurl, RequestOps op, QVariantMap *params)
{
    if (!m_authenticated)
        return false;

    if (isRequestActive(op))
        return false;

    QUrl url=createRequestUrl(opurl);
    QNetworkRequest request;
    setAuthenticationHeaders(&request);
    QHttpMultiPart *mp = new QHttpMultiPart(QHttpMultiPart::FormDataType);

    if (params) {
        QMapIterator<QString, QVariant> i(*params);
        while (i.hasNext()) {
            i.next();
            addParameter(mp, i.key(), i.value().toString());
        }
    }

    request.setUrl(url);
    queueRequest(post(request, mp), op);

    return true;
}

bool RvAPI::createSimpleAuthenticatedPutRequest(const QString opurl, RequestOps op, QVariantMap *params)
{
    if (!m_authenticated)
        return false;

    if (isRequestActive(op))
        return false;

    QUrl url=createRequestUrl(opurl);
    QNetworkRequest request;
    setAuthenticationHeaders(&request);
    QHttpMultiPart *mp = new QHttpMultiPart(QHttpMultiPart::FormDataType);

    if (params) {
        QMapIterator<QString, QVariant> i(*params);
        while (i.hasNext()) {
            i.next();
            addParameter(mp, i.key(), i.value().toString());
        }
    }

    request.setUrl(url);
    queueRequest(put(request, mp), op);

    return true;
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
    clearSession();

    if (m_url.isEmpty()) {
        qWarning("API urls is not set ");
        return false;
    }

    if (m_username.isEmpty() || m_password.isEmpty()) {
        qWarning("Username or password is not set ");
        return false;
    }

    if (m_authenticated) {
        qWarning("Already authenticated, ignoring");
        return false;
    }

    if (isRequestActive(AuthLogin)) {
        qWarning("Login request is already active");
        return false;
    }

    QNetworkRequest request(createRequestUrl(op_auth_login));
    setAuthenticationHeaders(&request);
    QHttpMultiPart *mp = new QHttpMultiPart(QHttpMultiPart::FormDataType);

    addParameter(mp, QStringLiteral("username"), m_username);
    addParameter(mp, QStringLiteral("password"), m_password);
    addParameter(mp, QStringLiteral("apiversion"), m_apiversion);
    addParameter(mp, QStringLiteral("appversion"), m_appversion);

    queueRequest(post(request, mp), AuthLogin);

    return true;
}

bool RvAPI::loginCancel()
{
    return cancelOperation(AuthLogin);
}

/**
 * @brief RvAPI::logout
 * @return
 */
bool RvAPI::logout()
{
    clearSession();

    if (isRequestActive(AuthLogout))
        return false;

    if (m_authtoken.isEmpty())
        return true;

    QNetworkRequest request(createRequestUrl(op_auth_logout));
    setAuthenticationHeaders(&request);

    QHttpMultiPart *mp = new QHttpMultiPart(QHttpMultiPart::FormDataType);

    queueRequest(post(request, mp), AuthLogout);

    return true;
}

void RvAPI::clearSession()
{
    clearProductStore();
    clearProductFilters();

    m_categorymodel.clear();

    m_cartmodel.clear();
    m_ordersmodel.clear();
    m_orders.clear();

    m_locations.clear();
    m_color_model.clear();
    m_roles.clear();

    m_cappversion=0;
    m_apk.clear();
}

bool RvAPI::hasRole(const QString &role)
{
    return m_roles.contains(role);
}

void RvAPI::setAppVersion(uint ver)
{
    m_appversion=ver;
}

bool RvAPI::products(uint page, uint amount)
{
    if (!m_authenticated)
        return false;

    if (amount>ITEMS_MAX || amount==0)
        amount=ITEMS_MAX;

    if (isRequestActive(Products))
        return false;

    if (page==0 && m_loadedPage>0 && m_hasMore) {// Load next page
        page=m_loadedPage+1;
    } else if (page==0) {
        qWarning() << "Initial page not loaded yet";
        return false;
    } else {
        m_loadedPage=page;
    }

    QUrl url=createRequestUrl(op_products);
    QUrlQuery query;
    QNetworkRequest request;

    setAuthenticationHeaders(&request);

    QString tmp;

    query.addQueryItem("page", tmp.setNum(page));
    query.addQueryItem("amount", tmp.setNum(amount));

    if (!m_searchcategory.isEmpty()) {
        query.addQueryItem("category", m_searchcategory);
    }
    if (!m_searchstring.isEmpty()) {
        query.addQueryItem("q", m_searchstring);
    }
    if (m_searchsort!=SortNotSet) {
        query.addQueryItem("s", getSortString(m_searchsort));
    }

    url.setQuery(query);
    request.setUrl(url);

    queueRequest(get(request), Products);

    return true;
}

const QString RvAPI::getSortString(ItemSort is) const
{
    switch (is) {
    case SortDateAsc:
        return "date_asc";
    case SortDateDesc:
        return "date_desc";
    case SortPriceAsc:
        return "price_asc";
    case SortPriceDesc:
        return "price_desc";
    case SortTitleAsc:
        return "title_asc";
    case SortTitleDesc:
        return "title_desc";
    case SortSKUAsc:
        return "sku_asc";
    case SortSKUDesc:
        return "sku_desc";
    default:
        return "";
    }
}

bool RvAPI::searchCancel()
{
    if (!m_authenticated)
        return false;

    if (isRequestActive(ProductSearch))
        return false;

    return false;
}

/**
 * @brief RvAPI::addCommonProductParameters
 * @param mp
 * @param product
 *
 * Add the product parameters to the QHttpMultiPart request that are shared with POST (Add product) & PUT (Update product) functions.
 *
 */
void RvAPI::addCommonProductParameters(QHttpMultiPart *mp, ProductItem *product)
{
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
    // Validate and add attributes
    // XXX: We don't check for category required attributes here, should we bother ?
    for (int i = 0; i < m_attributes.size(); i++) {
        QString a=m_attributes.at(i);

        if (product->hasAttribute(a)) {
            addParameter(mp, a, product->getAttribute(a));
        }
    }
}

/**
 * @brief RvAPI::add
 * @param product
 * @return
 *
 * Add a new ProductItem
 *
 */
bool RvAPI::addProduct(ProductItem *product)
{    
    if (!m_authenticated)
        return false;

    if (isRequestActive(ProductAdd))
        return false;

    QUrl url=createRequestUrl(op_products);
    QNetworkRequest request;
    setAuthenticationHeaders(&request);

    QHttpMultiPart *mp = new QHttpMultiPart(QHttpMultiPart::FormDataType);

    // XXX Handle multibarcode add
    QString bc=product->getBarcode();
    addParameter(mp, QStringLiteral("barcode"), bc);
    addCommonProductParameters(mp, product);

    // Add images
    QVariantList imf=product->images();

    for (int i = 0; i < imf.size(); i++) {
        bool r;
        QString f=imf.at(i).toString();
        QUrl fu(f);

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

    queueRequest(post(request, mp), ProductAdd);

    return true;
}

/**
 * @brief RvAPI::update
 * @param product
 * @return
 *
 * Update information of given ProductItem. The product must have a valid barcode to identify it.
 *
 */
bool RvAPI::updateProduct(ProductItem *product)
{
    if (!m_authenticated)
        return false;

    if (product->getBarcode().isEmpty())
        return false;

    if (isRequestActive(ProductUpdate))
        return false;

    QUrl url=createRequestUrl(op_products, product->getBarcode());
    QNetworkRequest request;
    setAuthenticationHeaders(&request);

    QHttpMultiPart *mp = new QHttpMultiPart(QHttpMultiPart::FormDataType);

    addCommonProductParameters(mp, product);

    request.setUrl(url);
    queueRequest(post(request, mp), ProductUpdate);

    return true;
}

/**
 * @brief RvAPI::getProduct
 * @param barcode
 * @return
 *
 * Request loading of product. If the product is cached it won't make a network request.
 * Result is notified trough signals:
 *
 *
 */
bool RvAPI::getProduct(const QString &barcode, bool update)
{
    if (!validateBarcode(barcode))
        return false;

    if (m_product_store.contains(barcode) && !update) {
        emit productFound(m_product_store.value(barcode));
        return true;
    }

    QUrl url=createRequestUrl(op_product_get+"/"+barcode);
    QUrlQuery query;
    QNetworkRequest request;

    setAuthenticationHeaders(&request);
    request.setUrl(url);

    QNetworkReply *req=get(request);
    queueRequest(req, Product);

    return true;
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

    if (!validateBarcode(barcode))
        return false;

    if (isRequestActive(ProductSearchBarcode))
        return false;

    // Check if we already know about it
    if (m_product_store.contains(barcode)) {
        qDebug() << "Product for barcode " << barcode << "found in local storage";

        ProductItem *item=m_product_store.value(barcode);
        m_itemsmodel.clear();
        m_itemsmodel.append(item);
        emit searchCompleted(false, true);
        return true;
    }

    QUrl url=createRequestUrl(op_product_barcode+"/"+barcode);
    QUrlQuery query;
    QNetworkRequest request;

    setAuthenticationHeaders(&request);
    request.setUrl(url);

    QNetworkReply *req;

    req=checkOnly ? head(request) : get(request);
    queueRequest(req, ProductSearchBarcode);

    return true;
}

/**
 * @brief RvAPI::sendOrder
 * @return
 *
 * Send cart and creates a product order on server.
 *
 */
bool RvAPI::createOrder(bool done)
{
    if (!m_authenticated)
        return false;

    if (isRequestActive(Orders))
        return false;

    if (m_cartmodel.count()==0)
        return false;

    QVariantMap prods;
    int pc=m_cartmodel.count();

    // Collect and count the products barcodes
    for (int i=0;i<pc;i++) {
        OrderLineItem *pi=m_cartmodel.getItem(i);
        if (!pi) {
            qWarning("Failed to find product!");
            return false;
        }
        if (prods.contains(pi->sku())) {
            uint i=prods.value(pi->sku()).toUInt();
            i++;
            prods.insert(pi->sku(), i);
        } else {
            prods.insert(pi->sku(), 1);
        }
    }

    QUrl url=createRequestUrl(op_orders);
    QNetworkRequest request;
    setAuthenticationHeaders(&request);

    QHttpMultiPart *mp = new QHttpMultiPart(QHttpMultiPart::FormDataType);

    addParameter(mp, QStringLiteral("done"), done);

    QMapIterator<QString, QVariant> i(prods);
    while (i.hasNext()) {
        i.next();

        addParameter(mp, "product["+i.key()+"]", i.value());
    }

    request.setUrl(url);
    queueRequest(post(request, mp), Orders);

    return true;
}


bool RvAPI::addToCart(const QString sku, int quantity)
{
    if (!m_authenticated)
        return false;

    if (isRequestActive(AddToCart))
        return false;

    QVariantMap r;
    r.insert("sku", sku);
    r.insert("quantity", quantity);

    return createSimpleAuthenticatedPostRequest(op_addtocart, AddToCart, &r);
}

bool RvAPI::removeFromCart(const QString sku)
{
    return false;
}

/**
 * @brief RvAPI::sendCart
 * @return
 *
 * Checkout shopping cart on server.
 *
 */
bool RvAPI::checkoutCart()
{
    if (!m_authenticated)
        return false;

    if (isRequestActive(CheckoutCart))
        return false;

    if (m_cartmodel.count()==0)
        return false;

    return createSimpleAuthenticatedPostRequest(op_checkoutcart, CheckoutCart);
}

bool RvAPI::orders(OrderStatus status)
{
    QVariantMap q;

    switch (status) {
    case OrderComplete:
        q.insert("status", "completed");
        break;
    case OrderPending:
        q.insert("status", "pending");
        break;
    case OrderProcessing:
        q.insert("status", "processing");
        break;
    }

    return createSimpleAuthenticatedRequest(op_orders, Orders, &q);
}

bool RvAPI::updateOrderStatus(OrderItem *order, int status)
{
    QUrl url=createRequestUrl(op_orders+"/"+order->property("id").toString()+"/status");
    QNetworkRequest request;
    setAuthenticationHeaders(&request);

    QHttpMultiPart *mp = new QHttpMultiPart(QHttpMultiPart::FormDataType);

    OrderItem::OrderStatus tmp=(OrderItem::OrderStatus)status;

    addParameter(mp, "status", m_order_status_str.value(tmp));
    request.setUrl(url);
    queueRequest(post(request, mp), OrderUpdateStatus);

    return true;
}

bool RvAPI::getUserCart()
{
    return createSimpleAuthenticatedRequest(op_getcart, Cart);
}

bool RvAPI::clearUserCart()
{
    return createSimpleAuthenticatedPostRequest(op_clearcart, ClearCart);
}

bool RvAPI::requestLocations()
{
    return createSimpleAuthenticatedRequest(op_locations, Locations);
}

bool RvAPI::requestCategories()
{
    return createSimpleAuthenticatedRequest(op_categories, Categories);
}

bool RvAPI::requestColors()
{
    return createSimpleAuthenticatedRequest(op_colors, Colors);
}

bool RvAPI::downloadUpdate()
{
    if (!m_authenticated)
        return false;

    if (isRequestActive(DownloadAPK))
        return false;

    QUrl url=createRequestUrl(op_download);
    QNetworkRequest request;
    setAuthenticationHeaders(&request);

    request.setUrl(url);

    queueRequest(get(request), DownloadAPK);

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

bool RvAPI::validateBarcode(const QString barcode) const
{   
    if (barcode.isEmpty())
        return false;
#if STRICT_BARCODE_FORMAT
    QRegularExpression r(BARCODE_REGEXP);

    if (!r.isValid()) {
        qWarning("Invalid barcode regular expression");
        return false;
    }
    QRegularExpressionMatch match = r.match(barcode);
    return match.hasMatch();
#else
    return true;
#endif
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

OrganizationModel *RvAPI::getOrganizationModel()
{
    return &m_organization_model;
}

ItemListModel *RvAPI::getItemModel()
{    
    return &m_itemsmodel;
}

OrderLineItemModel *RvAPI::getCartModel()
{
    return &m_cartmodel;
}

OrdersModel *RvAPI::getOrderModel()
{
    return &m_ordersmodel;
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

ColorModel *RvAPI::getColorModel()
{
    return &m_color_model;
}

bool RvAPI::authenticated() const
{
    return m_authenticated;
}

bool RvAPI::hasMore() const
{
    return m_hasMore;
}


