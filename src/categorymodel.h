#ifndef CATEGORYMODEL_H
#define CATEGORYMODEL_H

#include <QObject>
#include <QMap>
#include <QPair>
#include <QAbstractListModel>

class CategoryModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    Q_FLAGS(FeatureFlags)
    Q_ENUMS(Roles)
public:
    explicit CategoryModel(QObject *parent=0);
    explicit CategoryModel(QString cparent, QObject *parent=0);

    enum Roles {CategoryID = Qt::UserRole, TitleRole, FlagsRole };

    enum FeatureFlag {
        DefaultNone=0,
        HasSize=1,
        HasWeight=1 << 1,
        HasColor=1 << 2,
        HasISBN=1 << 3,
        HasEAN=1 << 4,
        HasMakeAndModel=1 << 5,
        HasStock=1 << 6,
        HasAuthor=1 << 7,
        HasPrice=1 << 8,
        HasPurpose=1 << 9,
        PlaceHolder006=1 << 10,
        InvalidCategory=1 << 11
    };
    Q_DECLARE_FLAGS(FeatureFlags, FeatureFlag)

    // QAbstractItemModel interface
    int rowCount(const QModelIndex &parent=QModelIndex()) const;
    QVariant data(const QModelIndex &index, int role) const;
    bool insertRows(int row, int count, const QModelIndex &parent);

    void addCategory(const QString id, const QString category, FeatureFlags flags);

    Q_INVOKABLE void clear();
    Q_INVOKABLE QVariantMap get(int index) const;

    QHash<int, QByteArray> roleNames() const {
        QHash<int, QByteArray> roles;
        roles[CategoryID] = "cid";
        roles[TitleRole] = "category";
        roles[FlagsRole] = "flags";
        return roles;
    }

signals:
    void countChanged(int);

private:
    QMap<QString, QPair<QString, FeatureFlags>> m_data;
    QString m_cparent;
};

Q_DECLARE_OPERATORS_FOR_FLAGS(CategoryModel::FeatureFlags)

#endif // CATEGORYMODEL_H
