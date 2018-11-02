#include "orderlineitemmodel.h"

OrderLineItemModel::OrderLineItemModel(QObject *parent) : Cute::AbstractObjectModel(QMetaType::type("OrderLineItem"), parent)
{

}

OrderLineItem *OrderLineItemModel::getItem(int index) const
{
    return dynamic_cast<OrderLineItem *>(getObject(index));
}
