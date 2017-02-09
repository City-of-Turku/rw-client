#include <QApplication>
#include <QDebug>

#include <QtQuick>
#include <QtQml>
#include <QQmlApplicationEngine>
#include <QQmlPropertyMap>

#include <QCamera>
#include <QCameraInfo>

#include <QSettings>
#include <QQuickStyle>
#include <QTranslator>

#include <QtWebView/QtWebView>

#include "src/barcodevideofilter.h"

#include "rvapi.h"
#include "itemlistmodel.h"
#include "settings.h"
#include "apputility.h"

#ifdef Q_OS_ANDROID
#include "androidhelper.h"
#endif

#define VERSION "0.0.10"
#define VERSION_CODE 10

class MyNetworkAccessManager : public QNetworkAccessManager
{
public:
    explicit MyNetworkAccessManager(QObject *parent = 0);
protected:
    QNetworkReply* createRequest(QNetworkAccessManager::Operation op, const QNetworkRequest &req, QIODevice *device);
};

MyNetworkAccessManager::MyNetworkAccessManager(QObject *parent)
    : QNetworkAccessManager(parent)
{

}

QNetworkReply* MyNetworkAccessManager::createRequest(QNetworkAccessManager::Operation op, const QNetworkRequest &req, QIODevice *device)
{
    QNetworkRequest myReq(req);

    myReq.setRawHeader(QByteArray("X-AuthenticationKey"), API_KEY);
    return QNetworkAccessManager::createRequest(op, myReq, device);
}

class MyNetworkAccessManagerFactory : public QQmlNetworkAccessManagerFactory
{
public:
    virtual QNetworkAccessManager *create(QObject *parent);
};

QNetworkAccessManager *MyNetworkAccessManagerFactory::create(QObject *parent)
{
    QNetworkAccessManager *nam = new MyNetworkAccessManager(parent);
    QNetworkDiskCache *diskCache = new QNetworkDiskCache(nam);

    diskCache->setCacheDirectory(QStandardPaths::writableLocation(QStandardPaths::CacheLocation));
    nam->setCache(diskCache);

    return nam;
}

int main(int argc, char *argv[])
{
    QGuiApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QGuiApplication app(argc, argv);
    QtWebView::initialize();
    const QString appversion(VERSION);
    const int appvcode=VERSION_CODE;

    QCoreApplication::setOrganizationDomain(APP_DOMAIN);
    QCoreApplication::setOrganizationName(APP_ORG);
    QCoreApplication::setApplicationName(APP_NAME);
    QCoreApplication::setApplicationVersion(appversion);

    QTranslator translator;

    QQmlPropertyMap user;
    Settings settings;
    AppUtility apputil;

    user.insert("username", settings.getSettingsStr("username", ""));
    user.insert("password", settings.getSettingsStr("password", ""));
    user.insert("apikey", API_KEY);
    user.insert("urlSanbox", API_SERVER_SANDBOX);
    user.insert("urlProduction", API_SERVER_PRODUCTION);

    QString locale(QLocale().name());

    qDebug() << "Locale is: " << locale;

    if (translator.load(QLocale(), QLatin1String("rvtku"), QLatin1String("_"), QLatin1String(":/translations")))
        app.installTranslator(&translator);
    else
        qDebug() << "Translation not available for locale " << locale;

    QQmlApplicationEngine engine;

    QQuickStyle::setStyle("Material");

    engine.setNetworkAccessManagerFactory(new MyNetworkAccessManagerFactory);

    qmlRegisterType<BarcodeVideoFilter>("net.ekotuki", 1,0, "BarcodeScanner");
    qmlRegisterType<ProductItem>("net.ekotuki", 1,0, "Product");
    qmlRegisterType<RvAPI>("net.ekotuki", 1,0, "ServerApi");
    qmlRegisterType<CategoryModel>("net.ekotuki", 1,0, "CategoryModel");
    qmlRegisterType<ItemListModel>("net.ekotuki", 1,0, "ItemListModel");
    //qmlRegisterType<LocationListModel>("net.ekotuki", 1,0, "LocationListModel");

    qRegisterMetaType<CategoryModel*>();
    qRegisterMetaType<ItemListModel*>();
    qRegisterMetaType<LocationListModel*>();
    qRegisterMetaType<ProductItem*>("ProductItem");
    qRegisterMetaType<LocationItem*>("LocationItem");

#ifdef Q_OS_ANDROID
    AndroidHelper android;
    engine.rootContext()->setContextProperty("android", &android);
#endif

    engine.rootContext()->setContextProperty("settings", &settings);
    engine.rootContext()->setContextProperty("appVersion", appversion);
    engine.rootContext()->setContextProperty("appVersionCode", appvcode);
    engine.rootContext()->setContextProperty("userData", &user);
    engine.rootContext()->setContextProperty("appUtil", &apputil);

    engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));

    return app.exec();
}
