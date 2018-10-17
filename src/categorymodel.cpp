#include "categorymodel.h"
#include <QDebug>

CategoryModel::CategoryModel(QObject *parent) :
    BaseListModel(parent)
{

}

CategoryModel::CategoryModel(QString cparent, QObject *parent) :
    BaseListModel(parent),
    m_cparent(cparent)
{

}

int CategoryModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_data.count();
}

QVariant CategoryModel::data(const QModelIndex &index, int role) const
{    
    if (!index.isValid()) {        
        return QVariant();
    }

    const QList<QString> keys=m_data.keys();
    QString key=keys.at(index.row());

    QPair<QString, FeatureFlags> tmp=m_data.value(key);

    switch (role) {
    case CategoryModel::CategoryID:
        return QVariant(key);
    case CategoryModel::TitleRole:
        return QVariant(tmp.first);        
    case CategoryModel::FlagsRole:
        return QVariant(tmp.second);        
    }

    return QVariant();
}

bool CategoryModel::insertRows(int row, int count, const QModelIndex &parent)
{
    Q_UNUSED(row)
    Q_UNUSED(count)
    Q_UNUSED(parent)
    return false;
}

void CategoryModel::addCategory(const QString id, const QString category, FeatureFlags flags)
{
    beginResetModel();
    //beginInsertRows(QModelIndex(), 0, 1);
    QPair<QString, FeatureFlags> tmp;
    tmp.first=category;
    tmp.second=flags;
    m_data.insert(id, tmp);    
    //endInsertRows();
    endResetModel();

    emit countChanged(m_data.count());

    qDebug() << "Categories: " << m_data.count() << id << category << flags;
}

void CategoryModel::clear()
{
    beginResetModel();
    m_data.clear();
    endResetModel();
}

QVariantMap CategoryModel::get(int index) const
{
    QVariantMap map;

    if (m_data.size()==0)
        return map;

    const QList<QString> keys=m_data.keys();    

    if (index>keys.size())
        return map;

    QString key=keys.at(index);
    QPair<QString, FeatureFlags> tmp=m_data.value(key);

    map["cid"] = key;
    map["category"] = tmp.first;
    map["flags"] = QVariant(tmp.second);

    return map;
}

