#ifndef ORGANIZATIONMODEL_H
#define ORGANIZATIONMODEL_H

#include <QObject>

#include "abstractobjectmodel.h"
#include "organizationitem.h"

class OrganizationModel : public Cute::AbstractObjectModel
{
    Q_OBJECT
public:
    explicit OrganizationModel(QObject *parent = nullptr);

    Q_INVOKABLE OrganizationItem *getItem(int index) const;
};

#endif // ORGANIZATIONMODEL_H
