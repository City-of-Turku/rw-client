#ifndef LOCATIONITEM_H
#define LOCATIONITEM_H

#include <QObject>
#include <QVariantList>
#include <QVariantHash>
#include <QGeoCoordinate>

class LocationItem : public QObject
{
    Q_OBJECT
    Q_PROPERTY(uint id READ getID)
    Q_PROPERTY(QString zip READ getZip)
    Q_PROPERTY(QString city READ getCity)
    Q_PROPERTY(QString street READ getStreet)
public:
    explicit LocationItem(QObject *parent = 0) {
        this->setParent(parent);
    }

    // virtual ~LocationItem();

    // static LocationItem* fromVariantMap(QVariantMap &data, QObject *parent = 0);

    uint id;

    QString name;
    QString zipcode;
    QString street;
    QString city;

    QGeoCoordinate geo;

private:
    uint getID() const { return id; }
    const QString getZip() const { return zipcode; }
    const QString getStreet() const { return street; }
    const QString getCity() const { return city; }

};

#endif // PRODUCTITEM_H
