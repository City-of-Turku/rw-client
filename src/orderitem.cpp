#include "orderitem.h"

#include <QDebug>
#include <QVariant>

OrderItem::OrderItem(QObject *parent) : QObject(parent)
{

}

OrderItem *OrderItem::fromVariantMap(QVariantMap &data, QObject *parent)
{
    OrderItem *o=new OrderItem(parent);

    qDebug() << data;

    o->m_id=data.value("id").toString().toUInt();
    o->m_uid=data.value("user").toString().toUInt();

    o->m_changed=QDateTime::fromSecsSinceEpoch(data.value("changed").toString().toUInt());
    o->m_created=QDateTime::fromSecsSinceEpoch(data.value("created").toString().toUInt());

    o->m_amount=data.value("amount").toString().toUInt();

    o->m_billing=data.value("billing").toMap();
    o->m_shipping=data.value("shipping").toMap();

    QString s=data.value("status").toString();
    if (s=="cart")
        o->m_status=OrderStatus::Cart;
    else if (s=="shipped")
        o->m_status=OrderStatus::Shipped;
    else if (s=="pending")
        o->m_status=OrderStatus::Pending;
    else
        o->m_status=OrderStatus::Unknown;

    QVariantList items=data.value("items").toList();

    for (int is=0;is<items.size();is++) {
        QPair<QString, int> line;
        QVariantMap l=items.at(is).toMap();

        QString sku=l.value("sku").toString();
        line.first=l.value("title").toString();
        line.second=l.value("amount").toInt();
        o->m_products.insert(sku, line);
    }

    // qDebug() << "Order Items:\n"<< items;

    return o;
}

int OrderItem::count()
{
    return m_products.size();
}

QStringList OrderItem::products()
{
    return m_products.keys();
}

QVariantMap OrderItem::shipping()
{
    return m_shipping;
}

QVariantMap OrderItem::billing()
{
    return m_billing;
}

