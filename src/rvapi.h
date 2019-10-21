#ifndef RVAPI_H
#define RVAPI_H

#include <QObject>

#include <QtNetwork/QNetworkAccessManager>
#include <QtNetwork/QNetworkRequest>
#include <QtNetwork/QNetworkReply>
#include <QtNetwork/QHttpMultiPart>
#include <QtNetwork/QHttpPart>

#include <QNetworkConfigurationManager>

#include <QSsl>
#include <QSslError>

#include <QTimer>
#include <QTimerEvent>

#include <QFile>
#include <QMap>
#include <QUrl>

#include <QCache>
#include <QNetworkDiskCache>
#include <QAuthenticator>

#include <QStringListModel>

#include "productitem.h"
#include "itemlistmodel.h"
#include "categorymodel.h"
#include "locationmodel.h"
#include "orderitem.h"
#include "ordersmodel.h"
#include "orderlineitem.h"
#include "orderlineitemmodel.h"

#include "organizationitem.h"
#include "organizationmodel.h"

#include "coloritem.h"
#include "colormodel.h"

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

    Q_PROPERTY(QString searchCategory MEMBER m_searchcategory NOTIFY searchCategoryChanged)
    Q_PROPERTY(QString searchString MEMBER m_searchstring NOTIFY searchStringChanged)
    Q_PROPERTY(ItemSort searchSort MEMBER m_searchsort NOTIFY searchSortChanged)

    Q_PROPERTY(bool isonline READ isOnline NOTIFY isOnlineChanged)

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

    enum ItemSort {
        SortNotSet=0,
        SortDateAsc,
        SortDateDesc,
        SortTitleAsc,
        SortTitleDesc,
        SortPriceAsc,
        SortPriceDesc,
        SortSKUAsc,
        SortSKUDesc
    };
    Q_ENUM(ItemSort)

    enum OrderSort {
        SortCreatedAsc,
        SortCreatedDesc,
        SortStatusAsc,
        SortStatusDesc
    };
    Q_ENUM(OrderSort)

    enum OrderStatus {
        OrderPending,
        OrderProcessing,
        OrderComplete
    };
    Q_ENUM(OrderStatus)

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
    Q_INVOKABLE bool loginCancel();
    Q_INVOKABLE bool logout();

    Q_INVOKABLE void setAppVersion(uint ver);    

    Q_INVOKABLE bool searchCancel();

    Q_INVOKABLE bool addProduct(ProductItem *product);
    Q_INVOKABLE bool updateProduct(ProductItem *product);
    Q_INVOKABLE bool getProduct(const QString &barcode, bool update=false);
    Q_INVOKABLE bool products(uint page=0, uint amount=50);
    Q_INVOKABLE bool searchBarcode(const QString barcode, bool checkonly=false);

    Q_INVOKABLE QUrl getImageUrl(const QString image);

    Q_INVOKABLE bool requestLocations();
    Q_INVOKABLE bool requestCategories();
    Q_INVOKABLE bool requestColors();

    Q_INVOKABLE bool validateBarcode(const QString barcode) const;
    Q_INVOKABLE bool validateBarcodeEAN(const QString code) const;

    Q_INVOKABLE OrganizationModel *getOrganizationModel();

    Q_INVOKABLE ItemListModel *getItemModel();
    Q_INVOKABLE OrderLineItemModel *getCartModel();
    Q_INVOKABLE OrdersModel *getOrderModel();
    Q_INVOKABLE LocationListModel *getLocationsModel();
    Q_INVOKABLE CategoryModel *getCategoryModel();    
    Q_INVOKABLE CategoryModel *getSubCategoryModel(const QString key);

    Q_INVOKABLE QStringListModel *getTaxModel();

    Q_INVOKABLE ColorModel *getColorModel();

    Q_INVOKABLE bool downloadUpdate();

    bool authenticated() const;
    bool hasMore() const;

    Q_INVOKABLE bool haveLocations();

    Q_INVOKABLE bool isOrderEmpty();
    Q_INVOKABLE bool createOrder(bool done);
    Q_INVOKABLE bool orders(OrderStatus status=OrderPending);

    // Should be, but QtQuick does not like enums in Q_INVOKABLE bool updateOrderStatus(OrderItem *order, OrderItem::OrderStatus status);
    Q_INVOKABLE bool updateOrderStatus(OrderItem *order, int status);

    Q_INVOKABLE bool getUserCart();
    Q_INVOKABLE bool clearUserCart();
    Q_INVOKABLE bool checkoutCart();
    Q_INVOKABLE bool addToCart(const QString sku, int quantity);
    Q_INVOKABLE bool removeFromCart(const QString sku);

    Q_INVOKABLE void clearProductStore();

    Q_INVOKABLE void setProxy(const QString server, quint16 port, const QString user, const QString password);

    Q_INVOKABLE void clearProductFilters();

    Q_INVOKABLE void clearCache();

    Q_INVOKABLE bool hasRole(const QString &role);

    bool isOnline() const
    {
        return m_isonline;
    }

signals:

    void urlChanged(QUrl url);

    void usernameChanged(QString username);

    void passwordChanged(QString password);

    void apikeyChanged(QString apikey);

    void busyChanged(bool busy);

    void requestActive(QString op);

    void loginSuccesfull();
    void loginFailure(const QString msg, int code);
    void loginCanceled();

    void authenticationFailure();

    void secureConnectionFailure();

    void updateAvailable();
    void updateDownloaded(QString file);

    void productFail(int error, QString msg);
    void productSaved(ProductItem *product, bool wasAdd);
    void productDeleted(QString barcode);

    void productsFail(int error, QString msg);

    void productFound(ProductItem *product);
    void productNotFound(QString barcode);

    void requestFailure(int error, int code, const QString msg);
    void requestSuccessful();

    void searchCompleted(bool hasMore, bool success);

    void orderCreated();
    void orderStatusUpdated();
    void cartCheckout();

    void productAddedToCart();
    void productOutOfStock();
    void cartCleared();
    void cartProductOutOfStock();

    void uploading(quint8 progress);
    void downloading(quint8 progress);

    void uploadProgressChanged(quint8 progress);
    void downloadProgressChanged(quint8 progress);

    void authenticatedChanged(bool authenticated);

    void hasMoreChanged(bool hasMore);

    void searchCategoryChanged();
    void searchStringChanged();
    void searchSortChanged();

    void isOnlineChanged(bool isonline);

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

protected slots:
    void onIgnoreSSLErrors(QNetworkReply *reply, QList<QSslError> error);
    void authenticationRequired(QNetworkReply *reply, QAuthenticator *authenticator);

    void connectReply(QNetworkReply *reply);
    void setHasMore(bool hasmore);

private slots:
    void uploadProgress(qint64 bytes, qint64 total);
    void downloadProgress(qint64 bytes, qint64 total);
    void requestError(QNetworkReply::NetworkError code);
    void requestFinished();
    void onNetworkOnlineChanged(bool online);

private:
    enum RequestOps {
        UnknownOperation,
        AuthLogin, AuthLogout,
        ProductSearch, ProductSearchBarcode, ProductAdd, ProductUpdate, Product, Products,
        Order, Orders, OrderUpdateStatus,
        Cart, ClearCart, AddToCart, CheckoutCart,
        Categories, Locations, Colors,
        DownloadAPK,
    };

    QNetworkAccessManager *m_NetManager;

    // API Operation endpoints as const strings
    // Authentication endpoints
    const QString op_auth_login=QStringLiteral("auth/login");
    const QString op_auth_logout=QStringLiteral("auth/logout");

    // Product endpoint
    const QString op_products=QStringLiteral("products");

    // Orders    
    const QString op_orders=QStringLiteral("orders");

    // Cart
    const QString op_getcart=QStringLiteral("cart");
    const QString op_clearcart=QStringLiteral("cart");
    const QString op_checkoutcart=QStringLiteral("cart/checkout");
    const QString op_addtocart=QStringLiteral("cart/item");

    // Search endpoints
    const QString op_product_barcode=QStringLiteral("products/barcode");
    const QString op_products_search=QStringLiteral("products/search");
    const QString op_product_get=QStringLiteral("products/barcode");

    // Dynamic meta data lists
    const QString op_locations=QStringLiteral("locations");
    const QString op_categories=QStringLiteral("categories");
    const QString op_colors=QStringLiteral("colors");

    const QString op_download=QStringLiteral("download/apk");

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

    // User details
    bool m_authenticated;
    QString m_username;
    QString m_password;
    QString m_apikey;    
    QString m_authtoken;
    QString m_msg;

    QVariantList m_roles;
    uint m_uid;
    QDateTime m_lastlogin;

    QNetworkConfigurationManager *m_netconf;
    bool m_isonline;

    bool m_busy;

    bool m_hasMore;
    int m_loadedAmount;
    int m_loadedPage;

    // Filtering settings
    QString m_searchcategory;
    QString m_searchstring;
    ItemSort m_searchsort;

    ProductMap m_product_store;

    QObjectList m_orders;
    OrganizationModel m_organization_model;
    ColorModel m_color_model;
    ItemListModel m_itemsmodel;
    OrderLineItemModel m_cartmodel;
    CategoryModel m_categorymodel;
    LocationListModel m_locations;    
    OrdersModel m_ordersmodel;    

    QStringList m_taxes;
    QStringListModel m_tax_model;

    QMap<OrderItem::OrderStatus, QString>m_order_status_str;

    QMap<QString, CategoryModel *>m_subcategorymodels;

    QMap<QNetworkReply *, RequestOps>m_requests;
    QStringList m_attributes;

    QNetworkReply *post(QNetworkRequest &request, QHttpMultiPart *mp);
    QNetworkReply *put(QNetworkRequest &request, QHttpMultiPart *mp);
    QNetworkReply *get(QNetworkRequest &request);
    QNetworkReply *head(QNetworkRequest &request);

    bool cancelOperation(RequestOps op);

    void queueRequest(QNetworkReply *req, RequestOps op);
    bool createSimpleAuthenticatedRequest(const QString opurl, RequestOps op, QVariantMap *params=nullptr);
    bool createSimpleAuthenticatedPostRequest(const QString opurl, RequestOps op, QVariantMap *params=nullptr);
    bool createSimpleAuthenticatedPutRequest(const QString opurl, RequestOps op, QVariantMap *params=nullptr);

    bool parseJsonResponse(const QByteArray &data, QVariantMap &map);
    void parseResponse(QNetworkReply *reply);
    bool parseOKResponse(RequestOps op, const QByteArray &response, const QNetworkAccessManager::Operation method);
    void parseErrorResponse(int code, QNetworkReply::NetworkError e, RequestOps op, const QByteArray &response);
    bool parseLocationData(QVariantMap &data);
    bool parseCategoryData(QVariantMap &data);
    bool parseColorsData(QVariantMap &data);
    void createStaticColorModel();
    bool parseProductData(QVariantMap &data, const QNetworkAccessManager::Operation method);
    bool parseProductsData(QVariantMap &data);
    bool parseLogin(QVariantMap &data);
    bool parseLogout();
    bool parseFileDownload(const QByteArray &data);
    void parseCategoryMap(const QString key, CategoryModel &model, QVariantMap &tmp, CategoryModel::FeatureFlags flags);
    bool parseOrderCreated(QVariantMap &data);
    bool parseOrders(QVariantMap &data);    
    bool parseOrderStatusUpdate(QVariantMap &data);
    bool parseCart(QVariantMap &data);
    bool parseCartCheckout(QVariantMap &data);

    void clearSession();

    void setBusy(bool busy);       

    const QUrl createRequestUrl(const QString &endpoint, const QString &detail=nullptr);
    void setAuthenticationHeaders(QNetworkRequest *request);
    void addParameter(QHttpMultiPart *mp, const QString key, const QVariant value);
    bool addFilePart(QHttpMultiPart *mp, QString prefix, QString fileName);
    void addCommonProductParameters(QHttpMultiPart *mp, ProductItem *product);

    bool isRequestActive(RequestOps op) const;
    RvAPI::RequestOps getRequestOp(QNetworkReply *rep);

    void setAuthentication(bool auth);

    const QString getSortString(ItemSort is) const;
};

#endif // RVAPI_H
