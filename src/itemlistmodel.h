#ifndef ITEMLISTMODEL_H
#define ITEMLISTMODEL_H

#include <QAbstractListModel>
#include <QList>

#include "productitem.h"

typedef QMap<QString, ProductItem *> ProductMap;

class ItemListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
public:
    explicit ItemListModel(ProductMap *storage, QObject *parent=nullptr);
    virtual ~ItemListModel();

    bool prepend(ProductItem *item);

    Q_INVOKABLE bool append(ProductItem *item);
    Q_INVOKABLE bool append(const QString barcode);

    bool update(ProductItem *item);
    Q_INVOKABLE bool remove(ProductItem *item);
    Q_INVOKABLE bool remove(const QString barcode);

    Q_INVOKABLE bool contains(const QString barcode);

    Q_INVOKABLE int count() const;

    Q_INVOKABLE void clear();
    Q_INVOKABLE ProductItem *get(int index);

    Q_INVOKABLE bool remove(int index);

    bool canFetchMore(const QModelIndex &parent=QModelIndex()) const;

    enum Roles {BarcodeRole = Qt::UserRole, TitleRole, DescriptionRole, ThumbnailRole, PurposeRole, StockRole, PriceRole, TaxRole};

    // QAbstractItemModel interface
    int rowCount(const QModelIndex &parent=QModelIndex()) const;
    QVariant data(const QModelIndex &index, int role) const;

    QHash<int, QByteArray> roleNames() const {
        QHash<int, QByteArray> roles;
        roles[BarcodeRole] = "barcode";
        roles[TitleRole] = "productTitle";
        roles[DescriptionRole] = "description";
        roles[ThumbnailRole]="thumbnail";
        roles[PurposeRole]="purpose";
        roles[StockRole]="stock";
        roles[PriceRole]="price";
        roles[TaxRole]="tax";
        return roles;
    }

signals:
    void countChanged(int);

private:
    ProductMap *m_productstore;
    QVariantList a;
    QList<QString> m_data;
    bool m_hasMore;
};

#endif // ITEMLISTMODEL_H
