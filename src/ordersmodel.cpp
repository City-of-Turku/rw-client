#include "ordersmodel.h"

OrdersModel::OrdersModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

QVariant OrdersModel::headerData(int section, Qt::Orientation orientation, int role) const
{
    // FIXME: Implement me!
}

int OrdersModel::rowCount(const QModelIndex &parent) const
{
    // For list models only the root node (an invalid parent) should return the list's size. For all
    // other (valid) parents, rowCount() should return 0 so that it does not become a tree model.
    if (parent.isValid())
        return 0;

    return m_data.size();
}

QVariant OrdersModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid())
        return QVariant();

    const QList<QString> keys=m_data.keys();
    QString key=keys.at(index.row());

    switch (role) {
    case OrdersModel::NameRole:
        // return QVariant(item->name);
        break;

    }
    return QVariant();
}

bool OrdersModel::insertRows(int row, int count, const QModelIndex &parent)
{
    beginInsertRows(parent, row, row + count - 1);
    // FIXME: Implement me!
    endInsertRows();
}
