#include "organizationmodel.h"

OrganizationModel::OrganizationModel(QObject *parent) :
    Cute::AbstractObjectModel(QMetaType::type("OrganizationItem"), parent)
{
    m_has_key=true;
    m_key_name="code";
}

OrganizationItem *OrganizationModel::getItem(int index) const
{
    return dynamic_cast<OrganizationItem *>(getObject(index));
}
