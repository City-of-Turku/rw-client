#ifndef BASELISTMODEL_H
#define BASELISTMODEL_H

#include <QObject>
#include <QAbstractListModel>

class BaseListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
public:
    BaseListModel(QObject *parent=nullptr);

    Q_INVOKABLE void virtual clear()=0;

signals:
    void countChanged(int);
};

#endif // BASELISTMODEL_H

