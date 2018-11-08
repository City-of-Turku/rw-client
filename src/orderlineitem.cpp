#include "orderlineitem.h"



OrderLineItem::OrderLineItem(QObject *parent) : QObject(parent)
{

}

OrderLineItem *OrderLineItem::fromVariantMap(QVariantMap &data, QObject *parent)
{
    OrderLineItem *o=new OrderLineItem(parent);

    o->m_id=data.value("id").toString().toInt();
    o->m_amount=data.value("amount").toString().toInt();
    o->m_sku=data.value("sku").toString();
    o->m_title=data.value("title").toString();
    o->m_type=data.value("type").toString();
    o->m_status=OrderItemPending;

    return o;
}
