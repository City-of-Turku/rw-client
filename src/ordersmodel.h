#ifndef ORDERSMODEL_H
#define ORDERSMODEL_H

#include "abstractobjectmodel.h"
#include "orderitem.h"

class OrdersModel : public Cute::AbstractObjectModel
{
    Q_OBJECT

public:
    explicit OrdersModel(QObject *parent = nullptr);
    ~OrdersModel();

    Q_INVOKABLE OrderItem *getItem(int index) const;
};

#endif // ORDERSMODEL_H
