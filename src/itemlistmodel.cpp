#include "itemlistmodel.h"
#include <QDebug>

ItemListModel::ItemListModel(QMap<QString, ProductItem *> *storage, QObject *parent) :
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

bool ItemListModel::prependProduct(ProductItem *item)
{
    beginInsertRows(QModelIndex(), 0, 0);    
    m_data.insert(0, item->barcode());
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
    m_data.append(item->barcode());
    endInsertRows();
    emit countChanged(m_data.size());

    return true;
}

bool ItemListModel::appendProduct(const QString barcode)
{
    int p=m_data.size();
    beginInsertRows(QModelIndex(), p, p);
    m_data.append(barcode);
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
    if (!m_data.contains(item->barcode()))
            return false;

    beginResetModel();


    endResetModel();
    return false;
}

bool ItemListModel::removeProduct(const QString barcode)
{
    if (!m_data.contains(barcode))
            return false;

    return true;
}

uint ItemListModel::count()
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
        break;
    case ItemListModel::TitleRole:
        return QVariant(item->getTitle());
        break;
    case ItemListModel::DescriptionRole:
        return QVariant(item->getDescription());
        break;
    case ItemListModel::ThumbnailRole: {        
        if (!item->images().isEmpty())
            return item->images().first();
        return QVariant();
    }
        break;
    case ItemListModel::PurposeRole:
        return QVariant(item->getAttribute("purpose"));
        break;

    case ItemListModel::StockRole:
        return QVariant(item->getStock());
        break;
    case ItemListModel::PriceRole:
        return QVariant(item->getPrice());
        break;
    case ItemListModel::TaxRole:
        return QVariant(item->getTax());
        break;
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
    qDebug() << "GET " << index;

    if (index>m_data.size())
        return nullptr;

    const QString k=m_data.at(index);
    ProductItem *item=m_productstore->value(k);

    return item;
}

bool ItemListModel::canFetchMore(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_hasMore;
}
