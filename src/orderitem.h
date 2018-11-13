#ifndef ORDERITEM_H
#define ORDERITEM_H

#include <QObject>
#include <QVariant>
#include <QDateTime>
#include <QMap>
#include <QPair>

#include "orderlineitem.h"

class OrderItem : public QObject
{
    Q_OBJECT
    Q_ENUMS(OrderStatus)
    Q_PROPERTY(uint orderID MEMBER m_id NOTIFY orderIDChanged)
    Q_PROPERTY(uint uid MEMBER m_uid NOTIFY uidChanged)
    Q_PROPERTY(QDateTime created MEMBER m_created NOTIFY createdChanged)
    Q_PROPERTY(QDateTime changed MEMBER m_changed NOTIFY changedChanged)
    Q_PROPERTY(OrderStatus status MEMBER m_status NOTIFY statusChanged)
    Q_PROPERTY(int count READ count)

public:
    explicit OrderItem(QObject *parent = nullptr);
    enum OrderStatus { Unknown=0, Cart, Cancelled, Pending, Processing, Shipped };

    static OrderItem *fromVariantMap(QVariantMap &data, QObject *parent);

    Q_INVOKABLE int count();

    Q_INVOKABLE QObjectList products() const;
    Q_INVOKABLE QVariantMap shipping();
    Q_INVOKABLE QVariantMap billing();
    //Q_INVOKABLE QStringList product(const QString &sku);

signals:
    void orderIDChanged(uint orderID);
    void uidChanged(uint uid);
    void createdChanged();
    void changedChanged();
    void statusChanged();

private:
    uint m_id;
    uint m_uid;
    OrderStatus m_status;
    QDateTime m_created;
    QDateTime m_changed;
    uint m_amount;

    QVariantMap m_shipping;
    QVariantMap m_billing;

    QObjectList m_products;
};

#endif // ORDERITEM_H
