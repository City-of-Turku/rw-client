#ifndef PRODUCTITEM_H
#define PRODUCTITEM_H

#include <QObject>
#include <QVariantList>
#include <QVariantHash>
#include <QList>

class ProductItem : public QObject
{
    Q_OBJECT
    Q_PROPERTY(uint productID READ getID NOTIFY productIDChanged)
    Q_PROPERTY(QString title READ title WRITE setTitle NOTIFY titleChanged)
    Q_PROPERTY(QString barcode READ barcode WRITE setBarcode NOTIFY barcodeChanged)
    Q_PROPERTY(QString description READ description WRITE setDescription NOTIFY descriptionChanged)
    Q_PROPERTY(QVariantList images READ images WRITE setImages NOTIFY imagesChanged)
    Q_PROPERTY(QString thumbnail READ thumbnail NOTIFY thumbnailChanged)
    Q_PROPERTY(QString category READ category WRITE setCategory NOTIFY categoryChanged)
    Q_PROPERTY(QString subCategory READ subCategory WRITE setSubCategory NOTIFY subCategoryChanged)
    Q_PROPERTY(uint stock READ getStock NOTIFY stockChanged)

public:
    explicit ProductItem(QObject *parent = 0);
    explicit ProductItem(const QString &barcode,const QString &title,const QString &description, QObject *parent = 0);
    virtual ~ProductItem();

    static ProductItem* fromVariantMap(QVariantMap &data, QObject *parent = 0);

    Q_INVOKABLE uint getID() const;
    Q_INVOKABLE const QString getBarcode() const;
    Q_INVOKABLE const QString getTitle() const;
    Q_INVOKABLE const QString getDescription() const;
    Q_INVOKABLE uint getOwner() const;
    Q_INVOKABLE uint getStock() const;

    Q_INVOKABLE QString title() const
    {
        return m_title;
    }

    Q_INVOKABLE QString barcode() const
    {
        return m_barcode;
    }

    Q_INVOKABLE QString description() const
    {
        return m_description;
    }

    Q_INVOKABLE QVariantList images() const
    {
        return m_images;
    }

    Q_INVOKABLE QString thumbnail() const;

    Q_INVOKABLE QString category() const
    {
        return m_category;
    }

    Q_INVOKABLE QString subCategory() const
    {
        return m_subcategory;
    }

    Q_INVOKABLE bool hasAttribute(const QString key) const;
    Q_INVOKABLE bool hasAttributes() const;
    Q_INVOKABLE QVariant getAttribute(const QString key) const;
    Q_INVOKABLE void setAttribute(const QString key, const QVariant value);
    Q_INVOKABLE void setStock(uint stock);

signals:

    void productIDChanged(uint id);

    void ownerChanged(uint id);

    void titleChanged(QString title);

    void barcodeChanged(QString barcode);

    void descriptionChanged(QString description);

    void imagesChanged(QVariantList images);

    void thumbnailChanged(QString thumbnail);

    void categoryChanged(QString category);

    void subCategoryChanged(QString category);

    void stockChanged(uint stock);

    void attributesChanged(const QString key, const QVariant value);

public slots:

    void setTitle(QString title);

    void setBarcode(QString barcode);

    void setDescription(QString description);

    void addImage(const QVariant image);

    void setImages(QVariantList images);

    void setCategory(const QString category);

    void setSubCategory(const QString category);

private:
    // Internal identifier
    uint m_id;
    uint m_uid;

    uint m_stock;

    // Barcode of item
    QString m_barcode;

    // Oneline title
    QString m_title;

    // Longer description
    QString m_description;

    // List of image identifiers
    QVariantList m_images;

    // Category identifier
    QString m_category;
    QString m_subcategory;

    QVariantMap m_attributes;
    QString m_thumbnail;

    Q_DISABLE_COPY(ProductItem)
};

#endif // PRODUCTITEM_H
