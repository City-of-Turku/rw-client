#include "orderlineitemmodel.h"

#include <QDebug>

OrderLineItemModel::OrderLineItemModel(QObject *parent) : Cute::AbstractObjectModel(QMetaType::type("OrderLineItem"), parent)
{
    connect(this, &OrderLineItemModel::dataChanged, this, &OrderLineItemModel::updateInternals);
    connect(this, &OrderLineItemModel::modelReset, this, &OrderLineItemModel::updateInternals);

    // We need to be able to change the item status so allow writing.
    m_iswritable=true;
    m_is_picked=false;
}

OrderLineItem *OrderLineItemModel::getItem(int index) const
{
    return dynamic_cast<OrderLineItem *>(getObject(index));
}

bool OrderLineItemModel::isPicked() const
{
    for (int i=0;i<rowCount();i++) {
        OrderLineItem *oli=getItem(i);

        // Shipping is listed in the model so ignore anyting that isn't a product
        if (oli->property("type").toString()!="product")
            continue;

        if (oli->property("status").toInt()!=OrderLineItem::OrderItemPicked)
            return false;
    }

    return true;
}

void OrderLineItemModel::setIsPicked()
{
    bool r=isPicked();

    if (m_is_picked==r)
        return;

    m_is_picked=r;

    qDebug() << "OrderLineItemModel-isPicked" << m_is_picked;

    emit isPickedChanged(m_is_picked);
}

void OrderLineItemModel::updateInternals()
{
    qDebug("OrderLineItemModel internal state updated...");
    setIsPicked();
}
