#ifndef ORDERSMODEL_H
#define ORDERSMODEL_H

#include <QAbstractListModel>

class OrdersModel : public QAbstractListModel
{
    Q_OBJECT

public:
    explicit OrdersModel(QObject *parent = nullptr);

    enum Roles {NameRole = Qt::UserRole};

    // Header:
    QVariant headerData(int section, Qt::Orientation orientation, int role = Qt::DisplayRole) const override;

    // Basic functionality:
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

    // Add data:
    bool insertRows(int row, int count, const QModelIndex &parent = QModelIndex()) override;

    QHash<int, QByteArray> roleNames() const override {
        QHash<int, QByteArray> roles;
        roles[NameRole] = "name";
        return roles;
    }

private:
    QMap<QString, QObject *> m_data;
};

#endif // ORDERSMODEL_H
