#include "colormodel.h"

ColorModel::ColorModel(QObject *parent) :
    Cute::AbstractObjectModel(QMetaType::type("ColorItem"), parent)
{
    m_has_key=true;
    m_key_name="cid";
}

ColorItem *ColorModel::getItem(int index) const
{
    return dynamic_cast<ColorItem *>(getObject(index));
}
