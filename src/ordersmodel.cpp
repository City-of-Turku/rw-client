#include "ordersmodel.h"

#include <QDebug>

OrdersModel::OrdersModel(QObject *parent)
    : Cute::AbstractObjectModel(QMetaType::type("OrderItem"), parent)
{
    qDebug("OrdersModel");
}

OrdersModel::~OrdersModel()
{
    qDebug("~OrdersModel");
}

OrderItem *OrdersModel::getItem(int index) const
{
    return dynamic_cast<OrderItem *>(getObject(index));
}
