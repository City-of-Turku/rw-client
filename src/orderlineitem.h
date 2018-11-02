#ifndef ORDERLINEITEM_H
#define ORDERLINEITEM_H

#include <QObject>
#include <QMap>
#include <QVariant>

class OrderLineItem : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int itemID MEMBER m_id)
    Q_PROPERTY(QString sku MEMBER m_sku NOTIFY skuChanged)
    Q_PROPERTY(QString title MEMBER m_title NOTIFY titleChanged)
    Q_PROPERTY(QString type MEMBER m_type NOTIFY typeChanged)
    Q_PROPERTY(int amount MEMBER m_amount NOTIFY amountChanged)
public:
    explicit OrderLineItem(QObject *parent = nullptr);

    static OrderLineItem *fromVariantMap(QVariantMap &data, QObject *parent);
signals:
    void skuChanged();
    void titleChanged();
    void typeChanged();
    void amountChanged();

public slots:

private:
    int m_id;
    QString m_sku;
    QString m_title;
    QString m_type;
    int m_amount;
    double m_total;
};

#endif // ORDERLINEITEM_H
