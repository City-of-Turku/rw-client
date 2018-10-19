#ifndef RVAPI_H
#define RVAPI_H

#include <QObject>

#include <QtNetwork/QNetworkAccessManager>
#include <QtNetwork/QNetworkRequest>
#include <QtNetwork/QNetworkReply>
#include <QtNetwork/QHttpMultiPart>
#include <QtNetwork/QHttpPart>

#include <QSsl>
#include <QSslError>

#include <QTimer>
#include <QTimerEvent>

#include <QFile>
#include <QMap>
#include <QUrl>

#include <QCache>
#include <QNetworkDiskCache>

#include <QStringListModel>

#include "productitem.h"
#include "itemlistmodel.h"
#include "categorymodel.h"
#include "locationmodel.h"
#include "orderitem.h"
#include "ordersmodel.h"

class RvAPI : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)

    // Are we authenticated ?
    Q_PROPERTY(bool authenticated READ authenticated NOTIFY authenticatedChanged)

    // User login related properties
    Q_PROPERTY(QString username READ username WRITE setUsername NOTIFY usernameChanged)
    Q_PROPERTY(QString password READ password WRITE setPassword NOTIFY passwordChanged)

    Q_PROPERTY(QUrl url READ url WRITE setUrl NOTIFY urlChanged)
    Q_PROPERTY(QString apikey READ apikey WRITE setApikey NOTIFY apikeyChanged)

    // Flag to indicate that there are more items available
    Q_PROPERTY(bool hasMore READ hasMore NOTIFY hasMoreChanged)

    Q_PROPERTY(uint uploadProgress READ uploadProgress NOTIFY uploadProgressChanged)
    Q_PROPERTY(uint downloadProgress READ downloadProgress NOTIFY downloadProgressChanged)

public:
    explicit RvAPI(QObject *parent = nullptr);
    virtual ~RvAPI();

    enum RequestStatus {
        RequestOK,
        RequestFail,
        RequestInProgress
    };

    Q_ENUM(RequestStatus)

    enum UserRoles {
        UserBrowse,
        UserManage,
        UserOrder
    };

    Q_ENUM(UserRoles)

    QUrl url() const
    {
        return m_url;
    }

    QString username() const
    {
        return m_username;
    }

    QString password() const
    {
        return m_password;
    }

    QString apikey() const
    {
        return m_apikey;
    }

    bool busy() const
    {
        return m_busy;
    }

    quint8 uploadProgress() const { return m_uploadProgress; }
    quint8 downloadProgress() const { return m_downloadProgress; }

    Q_INVOKABLE bool login();
    Q_INVOKABLE bool logout();

    Q_INVOKABLE void setAppVersion(uint ver);

    Q_INVOKABLE bool searchBarcode(const QString barcode, bool checkonly=false);    

    Q_INVOKABLE bool products(uint page=0, uint amount=50, const QString category="", const QString search="");
    Q_INVOKABLE bool searchCancel();

    Q_INVOKABLE bool add(ProductItem *product);
    Q_INVOKABLE bool update(ProductItem *product);

    Q_INVOKABLE QUrl getImageUrl(const QString image);

    Q_INVOKABLE bool requestLocations();
    Q_INVOKABLE bool requestCategories();

    Q_INVOKABLE bool validateBarcode(const QString barcode) const;
    Q_INVOKABLE bool validateBarcodeEAN(const QString code) const;

    Q_INVOKABLE ItemListModel *getItemModel();
    Q_INVOKABLE ItemListModel *getCartModel();
    Q_INVOKABLE LocationListModel *getLocationsModel();
    Q_INVOKABLE CategoryModel *getCategoryModel();
    Q_INVOKABLE CategoryModel *getSubCategoryModel(const QString key);

    Q_INVOKABLE QStringListModel *getTaxModel();

    Q_INVOKABLE bool downloadUpdate();

    bool authenticated() const;
    bool hasMore() const;

    Q_INVOKABLE bool haveLocations();

    Q_INVOKABLE bool isOrderEmpty();
    Q_INVOKABLE bool createOrder(bool done);
    Q_INVOKABLE bool orders();

    Q_INVOKABLE ProductItem *getProduct(const QString &barcode) const;

    Q_INVOKABLE void clearProductStore();

    Q_INVOKABLE void setProxy(const QString server, quint16 port, const QString user, const QString password);

signals:

    void urlChanged(QUrl url);

    void usernameChanged(QString username);

    void passwordChanged(QString password);

    void apikeyChanged(QString apikey);

    void busyChanged(bool busy);

    void requestActive(QString op);

    void loginSuccesfull();
    void loginFailure(const QString msg, int code);

    void authenticationFailure();

    void secureConnectionFailure();

    void updateAvailable();
    void updateDownloaded(QString file);

    void productFail(int error, QString msg);
    void productSaved(bool wasAdd);
    void productDeleted(QString barcode);

    void productsFail(int error, QString msg);

    void productNotFound(QString barcode);

    void requestFailure(int error, int code, const QString msg);
    void requestSuccessful();

    void searchCompleted(bool hasMore, bool success);

    void orderCreated();

    void uploading(quint8 progress);
    void downloading(quint8 progress);

    void uploadProgressChanged(quint8 progress);
    void downloadProgressChanged(quint8 progress);

    void authenticatedChanged(bool authenticated);

    void hasMoreChanged(bool hasMore);

public slots:

    void setUrl(QUrl url);

    void setUsername(QString username)
    {
        if (m_username == username)
            return;

        m_username = username;
        emit usernameChanged(username);
    }

    void setPassword(QString password)
    {
        if (m_password == password)
            return;

        m_password = password;
        emit passwordChanged(password);
    }

    void setApikey(QString apikey)
    {
        if (m_apikey == apikey)
            return;

        m_apikey = apikey;
        emit apikeyChanged(apikey);
    }

protected:
    void queueRequest(QNetworkReply *req, const QString op);
    bool createSimpleAuthenticatedRequest(const QString op);

protected slots:
    void onIgnoreSSLErrors(QNetworkReply *reply, QList<QSslError> error);
    void connectReply(QNetworkReply *reply);
    void setHasMore(bool hasmore);

private slots:
    void uploadProgress(qint64 bytes, qint64 total);
    void downloadProgress(qint64 bytes, qint64 total);
    void requestError(QNetworkReply::NetworkError code);
    void requestFinished();

private:
    enum RequestOps {
        UnknownOperation,
        AuthLogin, AuthLogout,
        ProductSearch, ProductSearchBarcode, Product, Products,
        Order, Orders,
        Categories,
        Locations,
        DownloadAPK,
    };

    enum SortOptions {
        SortDateAsc,
        SortDateDesc,
        SortTitleAsc,
        SortTitleDesc,
    };

    QNetworkAccessManager *m_NetManager;

    // API Operation endpoints as const strings
    // Authentication endpoints
    const QString op_auth_login=QStringLiteral("auth/login");
    const QString op_auth_logout=QStringLiteral("auth/logout");

    // Product endpoints
    const QString op_product=QStringLiteral("product");
    const QString op_products=QStringLiteral("products");

    const QString op_order=QStringLiteral("order");
    const QString op_orders=QStringLiteral("orders");

    // Search endpoints
    const QString op_product_barcode=QStringLiteral("product/barcode");
    const QString op_products_search=QStringLiteral("products/search");    

    const QString op_locations=QStringLiteral("locations");
    const QString op_categories=QStringLiteral("categories");

    const QString op_download=QStringLiteral("download/apk");

    // OP id to base string
    //QMap<RequestOps, const QString *>m_opmap;
    QMap<QString, RequestOps>m_opmap;

    RequestOps getOperationIdentifier(const QString op);

    // Active requests
    QMap<RequestOps, QString>m_ops;

    QUrl m_url;
    quint8 m_uploadProgress;
    quint8 m_downloadProgress;

    // The API version we support. Is sent on login request and server can then inform in case interface has changed
    // used mostly under development period, but might come in handy later too to inform users they need to
    // upgrade.
    int m_apiversion;

    // My app version
    int m_appversion;

    // API sent current appversion
    int m_cappversion;

    QString m_apk;

    QString m_hversion;

    bool m_authenticated;
    QString m_username;
    QString m_password;
    QString m_apikey;    
    QString m_authtoken;
    QString m_msg;
    bool m_busy;

    bool m_hasMore;
    int m_loadedAmount;
    int m_loadedPage;

    ProductMap m_product_store;

    QObjectList m_orders;

    ItemListModel m_itemsmodel;
    ItemListModel m_cartmodel;
    CategoryModel m_categorymodel;
    LocationListModel m_locations;    
    OrdersModel m_ordersmodel;

    QStringList m_taxes;
    QStringListModel m_tax_model;

    QMap<QString, CategoryModel *>m_subcategorymodels;    

    bool addFilePart(QHttpMultiPart *mp, QString prefix, QString fileName);
    QNetworkReply *post(QNetworkRequest &request, QHttpMultiPart *mp);
    QNetworkReply *put(QNetworkRequest &request, QHttpMultiPart *mp);
    QNetworkReply *get(QNetworkRequest &request);
    QNetworkReply *head(QNetworkRequest &request);

    QVariantMap parseJsonResponse(const QByteArray &data);
    void parseResponse(QNetworkReply *reply);
    bool parseOKResponse(const QString op, const QByteArray &response, const QNetworkAccessManager::Operation method);
    void parseErrorResponse(int code, QNetworkReply::NetworkError e, const QString op, const QByteArray &response);

    bool isRequestActive(const QString &op) const;

    void setBusy(bool busy);

    const QUrl createRequestUrl(const QString &endpoint, const QString &detail=nullptr);
    void setAuthenticationHeaders(QNetworkRequest *request);
    void addParameter(QHttpMultiPart *mp, const QString key, const QVariant value);

    QMap<QNetworkReply *, QString>m_requests;

    QStringList m_attributes;

    QString getRequestOp(QNetworkReply *rep);    

    void setAuthentication(bool auth);
    bool parseLocationData(QVariantMap &data);
    bool parseCategoryData(QVariantMap &data);
    bool parseProductData(QVariantMap &data, const QNetworkAccessManager::Operation method);
    bool parseProductsData(QVariantMap &data);
    bool parseLogin(QVariantMap &data);
    bool parseLogout();
    bool parseFileDownload(const QByteArray &data);
    void parseCategoryMap(const QString key, CategoryModel &model, QVariantMap &tmp);
    bool parseOrderCreated(QVariantMap &data);
    bool parseOrders(QVariantMap &data);
    void addCommonProductParameters(QHttpMultiPart *mp, ProductItem *product);
};

#endif // RVAPI_H
