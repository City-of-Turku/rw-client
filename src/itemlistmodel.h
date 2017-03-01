#ifndef ITEMLISTMODEL_H
#define ITEMLISTMODEL_H

#include <QAbstractListModel>
#include <QList>

#include "productitem.h"

class ItemListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
public:
    explicit ItemListModel(QMap<QString, ProductItem *> *storage, QObject *parent=0);
    virtual ~ItemListModel();

    bool prependProduct(ProductItem *item);
    bool appendProduct(ProductItem *item);
    bool updateProduct(ProductItem *item);
    bool removeProduct(ProductItem *item);

    Q_INVOKABLE void clear();
    Q_INVOKABLE ProductItem *get(int index);

    bool canFetchMore(const QModelIndex &parent=QModelIndex()) const;

    enum Roles {BarcodeRole = Qt::UserRole, TitleRole, DescriptionRole, ThumbnailRole, PurposeRole, StockRole};

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
        return roles;
    }

signals:
    void countChanged(int);

private:
    QMap<QString, ProductItem *> *m_productstore;
    QList<QString> m_data;
    bool m_hasMore;
};

#endif // ITEMLISTMODEL_H
