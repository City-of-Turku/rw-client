#ifndef RWNETWORKACCESSMANAGERFACTORY_H
#define RWNETWORKACCESSMANAGERFACTORY_H

#include <QObject>

#include <QQmlNetworkAccessManagerFactory>
#include <QNetworkAccessManager>
#include <QNetworkDiskCache>

class RWNetworkAccessManager : public QNetworkAccessManager
{
public:
    explicit RWNetworkAccessManager(QObject *parent = nullptr);
    QString m_api_key;
protected:
    QNetworkReply* createRequest(QNetworkAccessManager::Operation op, const QNetworkRequest &req, QIODevice *device);
};

class RWNetworkAccessManagerFactory : public QObject, public QQmlNetworkAccessManagerFactory
{
    Q_OBJECT
public:
    explicit RWNetworkAccessManagerFactory(QObject *parent = nullptr);
    virtual QNetworkAccessManager *create(QObject *parent);

    Q_INVOKABLE void setApiKey(const QString apikey);

    RWNetworkAccessManager *m_nam;
    QNetworkDiskCache *m_diskCache;
signals:

public slots:

private:
    QString m_apikey;
};

#endif // RWNETWORKACCESSMANAGERFACTORY_H
