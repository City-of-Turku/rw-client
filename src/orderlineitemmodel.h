#ifndef ORDERLINEITEMMODEL_H
#define ORDERLINEITEMMODEL_H

#include <QObject>

#include "abstractobjectmodel.h"
#include "orderlineitem.h"

class OrderLineItemModel : public Cute::AbstractObjectModel
{
    Q_OBJECT
    Q_PROPERTY(bool isPicked READ isPicked NOTIFY isPickedChanged)
public:
    explicit OrderLineItemModel(QObject *parent = nullptr);

    OrderLineItem *getItem(int index) const;

    Q_INVOKABLE bool isPicked() const;

protected:
    bool m_is_picked;
    void setIsPicked();

signals:
    void isPickedChanged(bool isPicked);

protected slots:
    void updateInternals();
};

#endif // ORDERLINEITEMMODEL_H
