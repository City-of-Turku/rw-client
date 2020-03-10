#ifndef PRODUCTITEM_H
#define PRODUCTITEM_H

#include <QObject>
#include <QVariantList>
#include <QVariantHash>
#include <QList>
#include <QDateTime>

class ProductItem : public QObject
{
    Q_OBJECT

    Q_ENUMS(ImageSource)

    Q_PROPERTY(uint productID READ getID NOTIFY productIDChanged)
    Q_PROPERTY(QString title READ title WRITE setTitle NOTIFY titleChanged)
    Q_PROPERTY(QString barcode READ barcode WRITE setBarcode NOTIFY barcodeChanged)
    Q_PROPERTY(QString description READ description WRITE setDescription NOTIFY descriptionChanged)
    Q_PROPERTY(QVariantList images READ images WRITE setImages NOTIFY imagesChanged)
    Q_PROPERTY(QString thumbnail READ thumbnail NOTIFY thumbnailChanged)
    Q_PROPERTY(QString category READ category WRITE setCategory NOTIFY categoryChanged)
    Q_PROPERTY(QString subCategory READ subCategory WRITE setSubCategory NOTIFY subCategoryChanged)
    Q_PROPERTY(uint stock READ getStock NOTIFY stockChanged)
    Q_PROPERTY(uint warehouse READ getWarehouse NOTIFY warehouseChanged)

    // XXX:
    Q_PROPERTY(double price READ getPrice WRITE setPrice NOTIFY priceChanged)
    Q_PROPERTY(uint tax READ getTax WRITE setTax NOTIFY taxChanged)

    Q_PROPERTY(bool keepImages READ keepImages WRITE setKeepImages NOTIFY keepImagesChanged)

public:
    explicit ProductItem(QObject *parent = nullptr);
    explicit ProductItem(const QString &barcode,const QString &title,const QString &description, QObject *parent = nullptr);
    ~ProductItem();

    static ProductItem* fromVariantMap(QVariantMap &data, QObject *parent = nullptr);
    static ProductItem *fromProduct(ProductItem &data, QObject *parent = nullptr);

    enum ImageSource { UnknownSource=0, CameraSource, GallerySource, RemoteSource };

    Q_INVOKABLE bool isNew() const;
    Q_INVOKABLE uint getID() const;
    Q_INVOKABLE const QString getBarcode() const;
    Q_INVOKABLE const QString getTitle() const;
    Q_INVOKABLE const QString getDescription() const;
    Q_INVOKABLE uint getOwner() const;
    Q_INVOKABLE uint getStock() const;
    Q_INVOKABLE uint getWarehouse() const;
    Q_INVOKABLE QDateTime getCreated() const;
    Q_INVOKABLE QDateTime getModified() const;

    Q_INVOKABLE void addImage(const QVariant image, const ImageSource source);
    Q_INVOKABLE void removeImages();

    Q_INVOKABLE bool hasAttribute(const QString key) const;
    Q_INVOKABLE bool hasAttributes() const;
    Q_INVOKABLE QVariant getAttribute(const QString key) const;
    Q_INVOKABLE void setAttribute(const QString key, const QVariant value);
    Q_INVOKABLE bool clearAttribute(const QString key);
    Q_INVOKABLE QVariantMap getAttributes() const;

    Q_INVOKABLE void setStock(uint stock);
    Q_INVOKABLE void setTitle(QString title);
    Q_INVOKABLE void setBarcode(QString barcode);
    Q_INVOKABLE void setDescription(QString description);
    Q_INVOKABLE void setImages(QVariantList images);
    Q_INVOKABLE void setCategory(const QString category);
    Q_INVOKABLE void setSubCategory(const QString category);
    Q_INVOKABLE void setTax(uint tax);
    Q_INVOKABLE void setPrice(double price);
    Q_INVOKABLE void setKeepImages(bool keepImages);

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

    Q_INVOKABLE uint getTax() const
    {
        return m_tax;
    }

    Q_INVOKABLE double getPrice() const
    {
        return m_price;
    }

    bool keepImages() const
    {
        return m_keepImages;
    }

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

    void warehouseChanged(uint warehouse);

    void attributesChanged(const QString key, const QVariant value);

    void taxChanged(uint tax);

    void priceChanged(double price);

    void keepImagesChanged(bool keepImages);

public slots:


private:
    Q_DISABLE_COPY(ProductItem)

    // Internal identifier
    uint m_id;
    uint m_uid;

    // Barcode of item
    QString m_barcode;

    // Oneline title
    QString m_title;

    // Longer description
    QString m_description;

    // List of images, and image sources
    QVariantList m_images;
    QMap<QVariant, ImageSource> m_imagesource;

    // Category identifier
    QString m_category;
    QString m_subcategory;

    QDateTime m_created;
    QDateTime m_modified;

    QVariantMap m_attributes;
    QString m_thumbnail;

    uint m_stock;
    uint m_warehouse;

    uint m_tax;
    double m_price;
    bool m_keepImages;
};

#endif // PRODUCTITEM_H
