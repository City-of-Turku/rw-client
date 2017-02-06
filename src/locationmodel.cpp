#include "locationmodel.h"

#include <QDebug>

LocationListModel::LocationListModel(QObject *parent) :
    QAbstractListModel(parent)
{

}

LocationListModel::~LocationListModel()
{    
    clear();
}

void LocationListModel::setPosition(double latitude, double longitude)
{
    m_geo.setLatitude(latitude);
    m_geo.setLongitude(longitude);
}

bool LocationListModel::prepend(LocationItem *item)
{
    beginInsertRows(QModelIndex(), 0, 0);
    item->setParent(this);
    m_data.insert(0, item);
    endInsertRows();

    return true;
}

/**
 * @brief LocationListModel::addProduct
 * @param item
 * @return
 *
 * Add item to model. Takes ownership of the item.
 *
 */
bool LocationListModel::append(LocationItem *item)
{
    int p=m_data.size();    
    beginInsertRows(QModelIndex(), p, p);
    item->setParent(this);
    m_data.append(item);
    endInsertRows();
    emit countChanged(m_data.size());

    return true;
}

int LocationListModel::findLocationByID(uint id)
{
    for (int i=0;i<m_data.size();i++) {
        LocationItem *item=m_data.at(i);
        if (item->id==id) {
            qDebug() << "Found id " << id << " at " << i;
            return i;
        }
    }
    return 0;
}

int LocationListModel::rowCount(const QModelIndex &parent) const
{
    if (m_filter.isEmpty())
        return m_data.size();
    else
        return m_filter_index.size();
}

QVariant LocationListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid())
        return QVariant();

    if (index.row()<0)
        return QVariant();

    const LocationItem *item;

    if (m_filter.isEmpty()) {
        if (index.row()>m_data.size())
            return QVariant();
        item=m_data.at(index.row());
    } else {
        if (index.row()>m_filter_index.size())
            return QVariant();
        item=m_data.at(m_filter_index.at(index.row()));
    }

    switch (role) {
    case LocationListModel::NameRole:
        return QVariant(item->name);
        break;
    case LocationListModel::StreetRole:
        return QVariant(item->street);
        break;
    case LocationListModel::ZipCodeRole:
        return QVariant(item->zipcode);
        break;
    case LocationListModel::CityRole:
        return QVariant(item->city);
        break;
    case LocationListModel::GeoValidRole:
        return QVariant(item->geo.isValid());
        break;
    case LocationListModel::LatitudeRole:
        return QVariant(item->geo.latitude());
        break;
    case LocationListModel::LongitudeRole:
        return QVariant(item->geo.longitude());
        break;
    case LocationListModel::DistanceRole:
        if (m_geo.isValid() && item->geo.isValid()) {
            qreal dist=m_geo.distanceTo(item->geo)/1000;
            return QVariant(dist);
        }
        return QVariant();
        break;
    }

    return QVariant();
}

bool LocationListModel::search(const QString string)
{
    clearFilter();

    QString s=string.simplified();

    if (s.isEmpty())
        return true;    

    bool isNumeric=false;

    m_filter=s;

    int num=s.toInt(&isNumeric, 10);

    beginResetModel();

    for (int i=0;i<m_data.size();i++) {
        LocationItem *item=m_data.at(i);
        if (item->name.contains(m_filter, Qt::CaseInsensitive) || item->street.contains(m_filter, Qt::CaseInsensitive)) {
            qDebug() << "Found match at " << i << " in " << item->name;
            m_filter_index.append(i);
        } else if (isNumeric && item->zipcode.contains(m_filter)) {
            qDebug() << "Find zipcode match at " << i << " in " << item->zipcode;
            m_filter_index.append(i);
        }
    }

    endResetModel();
    emit countChanged(m_filter_index.size());

    return true;
}

void LocationListModel::clearFilter()
{
    if (m_filter.isEmpty())
        return;

    beginResetModel();
    m_filter.clear();
    m_filter_index.clear();
    endResetModel();
    emit countChanged(m_data.size());
    return;
}

void LocationListModel::clear()
{    
    beginResetModel();
    while (!m_data.isEmpty())
        delete m_data.takeFirst();
    m_data.clear();
    endResetModel();
    emit countChanged(0);
}

/**
 * @brief LocationListModel::get
 * @param index
 * @return
 */
LocationItem *LocationListModel::get(int index)
{
    if (index<0)
        return nullptr;

    LocationItem *item;

    if (m_filter.isEmpty())
        item=m_data.at(index);
    else
        item=m_data.at(m_filter_index.at(index));

    return item;
}

/**
 * @brief LocationListModel::getId
 * @param id
 * @return
 */
LocationItem *LocationListModel::getId(uint id)
{
    for (int i = 0; i < m_data.size(); ++i) {
        LocationItem *tmp=m_data.at(i);
        if (tmp->id==id)
            return tmp;
    }
    return nullptr;
}
