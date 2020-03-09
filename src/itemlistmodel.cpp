#include "itemlistmodel.h"
#include <QDebug>

ItemListModel::ItemListModel(ProductMap *storage, QObject *parent) :
    QAbstractListModel(parent),
    m_productstore(storage),
    m_hasMore(false)
{

}

ItemListModel::~ItemListModel()
{
    qDebug("*** Product model going away, clearing");
    clear();
}

bool ItemListModel::prepend(ProductItem *item)
{
    beginInsertRows(QModelIndex(), 0, 0);    
    m_data.insert(0, item->barcode());
    endInsertRows();

    return true;
}

/**
 * @brief ItemListModel::append
 * @param item
 * @return
 *
 * Add item to model. Takes ownership of the item.
 *
 */
bool ItemListModel::append(ProductItem *item)
{
    int p=m_data.size();    
    beginInsertRows(QModelIndex(), p, p);    
    m_data.append(item->barcode());
    endInsertRows();
    emit countChanged(m_data.size());

    return true;
}

bool ItemListModel::append(const QString barcode)
{
    int p=m_data.size();
    beginInsertRows(QModelIndex(), p, p);
    m_data.append(barcode);
    endInsertRows();
    emit countChanged(m_data.size());

    return true;
}

bool ItemListModel::update(ProductItem *item)
{
    if (!m_data.contains(item->barcode()))
            return false;

    int i=m_data.indexOf(item->barcode());

    QModelIndex index=createIndex(i,1);

    emit dataChanged(index, index);

    return false;
}

bool ItemListModel::remove(ProductItem *item)
{
    return remove(item->barcode());
}

bool ItemListModel::remove(const QString barcode)
{
    if (!m_data.contains(barcode))
            return false;

    return remove(m_data.indexOf(barcode));
}

bool ItemListModel::contains(const QString barcode)
{
    return m_data.contains(barcode);
}

int ItemListModel::count() const
{
    return m_data.size();
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

    if (index.row()>m_data.size())
        return QVariant();

    const QString k=m_data.at(index.row());
    const ProductItem *item=m_productstore->value(k);

    if (!item) {
        qWarning() << "Product " << k << " not found in storage!";
        return QVariant();
    }

    switch (role) {
    case ItemListModel::BarcodeRole:
        return QVariant(item->getBarcode());        
    case ItemListModel::TitleRole:
        return QVariant(item->getTitle());       
    case ItemListModel::DescriptionRole:
        return QVariant(item->getDescription());
    case ItemListModel::ThumbnailRole: {        
        if (!item->images().isEmpty())
            return item->images().first();
        return QVariant();
    }        
    case ItemListModel::PurposeRole:
        return QVariant(item->getAttribute("purpose"));
    case ItemListModel::StockRole:
        return QVariant(item->getStock());
    case ItemListModel::PriceRole:
        return QVariant(item->getPrice());
    case ItemListModel::TaxRole:
        return QVariant(item->getTax());
    }

    return QVariant();
}

void ItemListModel::clear()
{
    qDebug("*** Clearing product model");
    beginResetModel();
    m_data.clear();
    endResetModel();
    emit countChanged(0);
}

ProductItem *ItemListModel::get(int index)
{
    if (index>m_data.size() || index<0) {
        qWarning() << "Invalid index" << index;
        return nullptr;
    }

    const QString k=m_data.at(index);
    ProductItem *item=m_productstore->value(k);

    return item;
}

bool ItemListModel::remove(int index)
{
    if (index>m_data.size() || index<0) {
        qWarning() << "Invalid index" << index;
        return false;
    }

    beginResetModel();
    m_data.removeAt(index);
    endResetModel();
    emit countChanged(m_data.size());

    return true;
}

bool ItemListModel::canFetchMore(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_hasMore;
}
