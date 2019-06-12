#ifndef ORGANIZATIONITEM_H
#define ORGANIZATIONITEM_H

#include <QObject>

class OrganizationItem : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString code MEMBER m_code )
    Q_PROPERTY(QString name MEMBER m_name)
    Q_PROPERTY(QString apiUrlProduction MEMBER m_apiUrl)
    Q_PROPERTY(QString apiUrlSandbox MEMBER m_apiUrlSandbox)
    Q_PROPERTY(QString apiKey MEMBER m_apiKey)

public:
    explicit OrganizationItem(QObject *parent = nullptr);

private:
    QString m_code;
    QString m_name;
    QString m_apiUrl;
    QString m_apiUrlSandbox;
    QString m_apiKey;
};

#endif // ORGANIZATIONITEM_H
