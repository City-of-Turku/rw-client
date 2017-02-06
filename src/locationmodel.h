#ifndef LOCATIONLISTMODEL_H
#define LOCATIONLISTMODEL_H

#include <QAbstractListModel>
#include <QList>
#include <QGeoCoordinate>

#include "locationitem.h"

class LocationListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
public:
    explicit LocationListModel(QObject *parent=0);
    virtual ~LocationListModel();

    Q_INVOKABLE void setPosition(double latitude, double longitude);

    Q_INVOKABLE void clear();
    Q_INVOKABLE LocationItem *get(int index);
    Q_INVOKABLE LocationItem *getId(uint id);
    Q_INVOKABLE bool search(QString string);
    bool prepend(LocationItem *item);
    bool append(LocationItem *item);

    Q_INVOKABLE int findLocationByID(uint id);

    enum Roles {NameRole = Qt::UserRole, StreetRole, ZipCodeRole, CityRole, GeoValidRole, LatitudeRole, LongitudeRole, DistanceRole};

    // QAbstractLocationModel interface
    int rowCount(const QModelIndex &parent=QModelIndex()) const;
    QVariant data(const QModelIndex &index, int role) const;

    QHash<int, QByteArray> roleNames() const {
        QHash<int, QByteArray> roles;
        roles[NameRole] = "name";
        roles[StreetRole] = "street";
        roles[ZipCodeRole] = "zipcode";
        roles[CityRole] = "city";
        roles[StreetRole] = "street";
        roles[GeoValidRole] = "geovalid";
        roles[LatitudeRole] = "latitude";
        roles[LongitudeRole] = "longitude";
        roles[DistanceRole] = "distance";        
        return roles;
    }

    Q_INVOKABLE void clearFilter();
signals:
    void countChanged(int);

private:
    QString m_filter;
    QGeoCoordinate m_geo;
    QList<LocationItem*> m_data;
    QList<int> m_filter_index;
};

#endif // LOCATIONLISTMODEL_H
