#ifndef ORDERSMODEL_H
#define ORDERSMODEL_H

#include "abstractobjectmodel.h"
#include "orderitem.h"
#include "orderlineitemmodel.h"

class OrdersModel : public Cute::AbstractObjectModel
{
    Q_OBJECT

public:
    explicit OrdersModel(QObject *parent = nullptr);
    ~OrdersModel();

    Q_INVOKABLE OrderItem *getItem(int index) const;
    Q_INVOKABLE OrderLineItemModel *getItemLineItemModel(int index);

private:
    OrderLineItemModel m_lineitems;
};

#endif // ORDERSMODEL_H
