#include "coloritem.h"

ColorItem::ColorItem(QObject *parent) : QObject(parent)
{

}

ColorItem::ColorItem(const QString &cid, const QString &color, const QString &code, QObject *parent) : QObject(parent)
{
    m_cid=cid;
    m_color=color;
    m_code=code;
}

ColorItem *ColorItem::fromVariantMap(const QVariantMap &data, QObject *parent)
{
    ColorItem *o=new ColorItem(parent);

    o->m_cid=data.value("id").toString();
    o->m_color=data.value("color").toString();
    o->m_code=data.value("code").toString();

    return o;
}


