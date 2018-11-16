#include "ordersmodel.h"

#include <QDebug>

OrdersModel::OrdersModel(QObject *parent)
    : Cute::AbstractObjectModel(QMetaType::type("OrderItem"), parent),
      m_lineitems(this)
{        
    m_has_id=true;
}

OrdersModel::~OrdersModel()
{
    clear();
}

OrderItem *OrdersModel::getItem(int index) const
{
    return dynamic_cast<OrderItem *>(getObject(index));
}

OrderLineItemModel *OrdersModel::getItemLineItemModel(int index)
{
    OrderItem *o=getItem(index);

    //m_lineitems.clear();
    m_lineitems.setList(o->products());

    return &m_lineitems;
}

