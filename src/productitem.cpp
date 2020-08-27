#include "productitem.h"

#include <QDebug>
#include <QFile>

ProductItem::ProductItem(QObject *parent)
    : QObject(parent)
    , m_id(0)
    , m_uid(0)
    , m_stock(1)
    , m_tax(0)
    , m_price(0.0)
    , m_keepImages(true)
{

}

ProductItem::ProductItem(const QString &barcode, const QString &title, const QString &description, QObject *parent)
    : QObject(parent)
    , m_id(0)
    , m_uid(0)
    , m_barcode(barcode)
    , m_title(title)        
    , m_description(description)
    , m_stock(1)
    , m_warehouse(0)
    , m_tax(0)
    , m_price(0.0)
    , m_keepImages(true)
{

}

ProductItem* ProductItem::fromVariantMap(QVariantMap &data, QObject *parent)
{
    ProductItem *p=new ProductItem(parent);

    p->setBarcode(data["barcode"].toString());
    p->setTitle(data["title"].toString());
    p->setCategory(data["category"].toString());
    p->setSubCategory(data["subcategory"].toString());
    p->setDescription(data["description"].toString());

    p->m_id=data["id"].toString().toUInt();
    if (p->m_id==0)
        qWarning() << "Failed to get product ID, invalid data ? " << data;

    p->m_uid=data["uid"].toString().toUInt();

    if (data.contains("location"))
        p->m_warehouse=data["location"].toString().toUInt();
    else
        p->m_warehouse=0;

    if (data.contains("stock"))
        p->m_stock=data["stock"].toString().toDouble();
    else
        p->m_stock=1;

    if (data.contains("price"))
        p->m_price=data["price"].toString().toDouble();
    else
        p->m_price=0.0;

    if (data.contains("tax"))
        p->m_tax=data["tax"].toString().toUInt();
    else
        p->m_tax=0;

    p->m_created=QDateTime::fromSecsSinceEpoch(data["created"].toString().toLong());
    p->m_modified=QDateTime::fromSecsSinceEpoch(data["modified"].toString().toLong());

    if (data.contains("value"))
        p->setAttribute("value", data["value"].toUInt());

    if (data.contains("images")) {
        QVariantList tmp=data["images"].toList();
        p->setImages(tmp);
    }

    if (data.contains("size")) {
        QVariantMap sm=data["size"].toMap();
        if (sm.contains("weight"))
            p->setAttribute("weight", sm["weight"].toString().toDouble());
        if (sm.contains("depth"))
            p->setAttribute("depth", sm["depth"].toString().toDouble());
        if (sm.contains("width"))
            p->setAttribute("width", sm["width"].toString().toDouble());
        if (sm.contains("height"))
            p->setAttribute("height", sm["height"].toString().toDouble());
    }

    // XXX: Loop over valid attributes ?

    if (data.contains("color"))
        p->setAttribute("color", data["color"].toList());

    if (data.contains("purpose"))
        p->setAttribute("purpose", data["purpose"].toString().toDouble());

    if (data.contains("material"))
        p->setAttribute("materil", data["material"].toString().toDouble());

    if (data.contains("ean"))
        p->setAttribute("ean", data["ean"].toString());

    if (data.contains("isbn"))
        p->setAttribute("isbn", data["isbn"].toString());

    if (data.contains("model"))
        p->setAttribute("model", data["model"].toString());

    if (data.contains("manufacturer"))
        p->setAttribute("manufacturer", data["manufacturer"].toString());

    return p;
}

ProductItem* ProductItem::fromProduct(ProductItem &pi, QObject *parent)
{
    ProductItem *p=new ProductItem(parent);

    p->setTitle(pi.title());
    p->setCategory(pi.category());
    p->setSubCategory(pi.subCategory());
    p->setDescription(pi.description());

    p->m_price=pi.m_price;
    p->m_tax=pi.m_tax;
    p->m_stock=pi.m_stock;
    p->m_warehouse=pi.m_warehouse;
    p->m_attributes=pi.m_attributes;

    return p;
}

bool ProductItem::isNew() const
{
    return m_id==0 ? true : false;
}

ProductItem::~ProductItem()
{
    qDebug() << "*** Delete Product " << m_barcode << m_keepImages;
}

uint ProductItem::getID() const
{
    return m_id;
}

uint ProductItem::getOwner() const
{
    return m_uid;
}

uint ProductItem::getStock() const
{
    return m_stock;
}

uint ProductItem::getWarehouse() const
{
    return m_warehouse;
}

QDateTime ProductItem::getCreated() const
{
    return m_created;
}

QDateTime ProductItem::getModified() const
{
    return m_modified;
}

const QString ProductItem::getBarcode() const
{
    return m_barcode;
}

const QString ProductItem::getTitle() const
{
    return m_title;
}

const QString ProductItem::getDescription() const
{
    return m_description;
}

QString ProductItem::thumbnail() const
{    
    return m_images.isEmpty() ? "" : m_images.first().toString();
}

bool ProductItem::hasAttribute(const QString key) const
{
    return m_attributes.contains(key);
}

bool ProductItem::hasAttributes() const
{
    return m_attributes.size()==0 ? false : true;
}

QVariant ProductItem::getAttribute(const QString key) const
{
    return m_attributes.value(key);
}

void ProductItem::setAttribute(const QString key, const QVariant value)
{
    m_attributes.insert(key, value);
    emit attributesChanged(key, value);
}

bool ProductItem::clearAttribute(const QString key)
{
    bool r=m_attributes.remove(key)==0 ? false : true;

    if (r)
        emit attributesChanged(key, QVariant());

    return r;
}

QVariantMap ProductItem::getAttributes() const
{
    qDebug() << m_attributes;
    return m_attributes;
}

void ProductItem::setStock(uint stock)
{
    if (m_stock==stock)
        return;

    m_stock=stock;
    emit stockChanged(stock);
}

void ProductItem::setTitle(QString title)
{
    if (m_title == title)
        return;

    m_title = title;
    emit titleChanged(title);
}

void ProductItem::setBarcode(QString barcode)
{
    if (m_barcode == barcode)
        return;

    m_barcode = barcode;
    emit barcodeChanged(barcode);
}

void ProductItem::setDescription(QString description)
{
    if (m_description == description)
        return;

    m_description = description;
    emit descriptionChanged(description);
}

void ProductItem::addImage(const QVariant image, const ImageSource source)
{
    m_images.append(image);
    m_imagesource.insert(image, source);
    emit imagesChanged(m_images);
}

void ProductItem::removeImages()
{
    if (!m_keepImages) {
        for (int i = 0; i < m_images.size(); i++) {
            QString f=m_images.at(i).toString();

            ImageSource is=m_imagesource.value(f, UnknownSource);
            if (is!=CameraSource)
                continue;

            if (!QFile::exists(f))
                continue;

            qDebug() << "Removing file: " << f;
            QFile::remove(f);
        }
    }
    m_images.clear();
    m_imagesource.clear();
}

void ProductItem::setImages(QVariantList images)
{    
    if (m_images==images)
        return;

    m_imagesource.clear();
    m_images = images;
    emit imagesChanged(images);
    emit thumbnailChanged(images.isEmpty() ? "" : images.first().toString());
}

void ProductItem::setCategory(const QString category)
{
    if (m_category == category)
        return;

    m_category = category;
    emit categoryChanged(category);
}

void ProductItem::setSubCategory(const QString category)
{
    if (m_subcategory == category)
        return;

    m_subcategory = category;
    emit subCategoryChanged(category);
}

void ProductItem::setTax(uint tax)
{
    if (m_tax == tax)
        return;

    m_tax = tax;
    emit taxChanged(tax);
}

void ProductItem::setPrice(double price)
{
    if (m_price == price)
        return;

    m_price = price;
    emit priceChanged(price);
}

void ProductItem::setKeepImages(bool keepImages)
{
    if (m_keepImages == keepImages)
        return;

    m_keepImages = keepImages;
    emit keepImagesChanged(keepImages);
}
