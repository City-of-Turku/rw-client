#include "itemlistmodel.h"
#include <QDebug>

ItemListModel::ItemListModel(QObject *parent) :
    QAbstractListModel(parent),
    m_hasMore(false)
{

}

ItemListModel::~ItemListModel()
{
    qDebug("*** Product model going away, clearing");
    clear();
}

bool ItemListModel::prependProduct(ProductItem *item)
{
    beginInsertRows(QModelIndex(), 0, 0);
    item->setParent(this);
    m_data.insert(0, item);
    endInsertRows();

    return true;
}

/**
 * @brief ItemListModel::addProduct
 * @param item
 * @return
 *
 * Add item to model. Takes ownership of the item.
 *
 */
bool ItemListModel::appendProduct(ProductItem *item)
{
    int p=m_data.size();    
    beginInsertRows(QModelIndex(), p, p);
    item->setParent(this);
    m_data.append(item);
    endInsertRows();
    emit countChanged(m_data.size());

    return true;
}

bool ItemListModel::updateProduct(ProductItem *item)
{
    Q_UNUSED(item)
    return false;
}

bool ItemListModel::removeProduct(ProductItem *item)
{
    Q_UNUSED(item)
    return false;
}

int ItemListModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_data.size();
}

QVariant ItemListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid())
        return QVariant();

    const ProductItem *item=m_data.at(index.row());

    switch (role) {
    case ItemListModel::BarcodeRole:
        return QVariant(item->getBarcode());
        break;
    case ItemListModel::TitleRole:
        return QVariant(item->getTitle());
        break;
    case ItemListModel::DescriptionRole:
        return QVariant(item->getDescription());
        break;
    case ItemListModel::ThumbnailRole: {
        QVariantList i=item->images();
        if (i.size()>0)
            return i.first();
        return QVariant();
    }
        break;
    case ItemListModel::PurposeRole:
        return QVariant(item->getAttribute("purpose"));
        break;

    case ItemListModel::StockRole:
        return QVariant(item->getStock());
        break;
    }

    return QVariant();
}

void ItemListModel::clear()
{
    qDebug("*** Clearing product model");
    beginResetModel();
    while (!m_data.isEmpty())
        delete m_data.takeFirst();
    m_data.clear();
    endResetModel();
    emit countChanged(0);
}

ProductItem *ItemListModel::get(int index)
{
    qDebug() << "GET " << index;
    ProductItem *item=m_data.at(index);

    return item;
}

bool ItemListModel::canFetchMore(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_hasMore;
}
