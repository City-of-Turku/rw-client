#ifndef ORDERLINEITEMMODEL_H
#define ORDERLINEITEMMODEL_H

#include <QObject>

#include "abstractobjectmodel.h"
#include "orderlineitem.h"

class OrderLineItemModel : public Cute::AbstractObjectModel
{
    Q_OBJECT
public:
    explicit OrderLineItemModel(QObject *parent = nullptr);

    OrderLineItem *getItem(int index) const;
};

#endif // ORDERLINEITEMMODEL_H
