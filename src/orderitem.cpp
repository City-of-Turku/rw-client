#include "orderitem.h"

#include <QDebug>
#include <QVariant>

OrderItem::OrderItem(QObject *parent) : QObject(parent)
{

}

OrderItem *OrderItem::fromVariantMap(QVariantMap &data, QObject *parent)
{
    OrderItem *o=new OrderItem(parent);

    qDebug() << "OrderItem" << data;

    o->m_id=data.value("id").toString().toUInt();
    o->m_created=QDateTime::fromSecsSinceEpoch(data.value("created").toString().toUInt());
    o->m_amount=data.value("amount").toString().toUInt();
    o->m_currency=data.value("currency").toString();

    o->updateFromVariantMap(data);

    qDebug() << o->m_id << o->m_uid << o->m_amount << o->m_created << o->m_changed;

    o->m_billing=data.value("billing").toMap();
    o->m_shipping=data.value("shipping").toMap();

    QVariantList items=data.value("items").toList();

    for (int is=0;is<items.size();is++) {
        QVariantMap lim=items.at(is).toMap();
        OrderLineItem *lip=OrderLineItem::fromVariantMap(lim, o);

        o->m_products.append(lip);
    }

    return o;
}

void OrderItem::updateFromVariantMap(QVariantMap &data)
{
    m_uid=data.value("user").toString().toUInt();
    m_changed=QDateTime::fromSecsSinceEpoch(data.value("changed").toString().toUInt());

    emit changedChanged();

    m_amount=data.value("amount").toString().toUInt();
    emit amountChanged(amount());

    m_currency=data.value("currency").toString();

    QString s=data.value("status").toString();
    setStatusFromString(s);
}

int OrderItem::count()
{
    return m_products.size();
}

QObjectList OrderItem::products() const
{
    return m_products;
}

QVariantMap OrderItem::shipping()
{
    return m_shipping;
}

QVariantMap OrderItem::billing()
{
    return m_billing;
}

OrderItem::OrderStatus OrderItem::setStatusFromString(const QString &s)
{
    if (s=="cart")
        m_status=OrderStatus::Cart;
    else if (s=="completed")
        m_status=OrderStatus::Shipped;
    else if (s=="pending")
        m_status=OrderStatus::Pending;
    else if (s=="processing")
        m_status=OrderStatus::Processing;
    else if (s=="canceled")
        m_status=OrderStatus::Cancelled;
    else {
        qWarning() << "Unknown order status " << s;
        m_status=OrderStatus::Unknown;
    }

    emit statusChanged();

    return m_status;
}

