#include "ordersmodel.h"

OrdersModel::OrdersModel(QObject *parent)
    : Cute::AbstractObjectModel(QMetaType::type("OrderItem"), parent)
{

}


