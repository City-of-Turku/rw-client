#include "rwnetworkaccessmanagerfactory.h"

#include <QStandardPaths>

RWNetworkAccessManager::RWNetworkAccessManager(QObject *parent)
    : QNetworkAccessManager(parent)
{

}

QNetworkReply* RWNetworkAccessManager::createRequest(QNetworkAccessManager::Operation op, const QNetworkRequest &req, QIODevice *device)
{
    QNetworkRequest myReq(req);

    // qDebug() << "createRequest" << m_api_key << op << req.url();

    if (!m_api_key.isEmpty())
        myReq.setRawHeader(QByteArray("X-AuthenticationKey"), m_api_key.toUtf8());

    myReq.setAttribute(QNetworkRequest::HttpPipeliningAllowedAttribute, true);
    return QNetworkAccessManager::createRequest(op, myReq, device);
}

RWNetworkAccessManagerFactory::RWNetworkAccessManagerFactory(QObject *parent) : QObject(parent), m_nam(nullptr)
{

}

void RWNetworkAccessManagerFactory::setApiKey(const QString apikey)
{    
    if (m_nam) {
        m_nam->m_api_key=apikey;
    } else {
        qDebug() << "Defering setting of apikey";
        m_apikey=apikey;
    }
}

QNetworkAccessManager *RWNetworkAccessManagerFactory::create(QObject *parent)
{
    m_nam = new RWNetworkAccessManager(parent);
    m_nam->m_api_key=m_apikey;
    m_diskCache = new QNetworkDiskCache(m_nam);

    m_diskCache->setCacheDirectory(QStandardPaths::writableLocation(QStandardPaths::CacheLocation));
    m_nam->setCache(m_diskCache);

    qDebug() << "Cache is " << m_diskCache->cacheSize()/1024 << m_diskCache->maximumCacheSize()/1024 << m_diskCache->cacheDirectory();

    return m_nam;
}
