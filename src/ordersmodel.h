#ifndef ORDERSMODEL_H
#define ORDERSMODEL_H

#include "abstractobjectmodel.h"

class OrdersModel : public Cute::AbstractObjectModel
{
    Q_OBJECT

public:
    explicit OrdersModel(QObject *parent = nullptr);

};

#endif // ORDERSMODEL_H
