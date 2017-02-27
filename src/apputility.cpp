#include <QDebug>
#include <QFile>

#include "apputility.h"

#include "3rdparty/qexifimageheader/qexifimageheader.h"

AppUtility::AppUtility(QObject *parent) : QObject(parent)
{

}

int AppUtility::getImageRotation(QString file)
{
    QExifImageHeader eh;

    qDebug() << file;

    if (file.startsWith("http:")) {
        qWarning("Ignoring remote image");
        return 0;
    }

    if (file.startsWith("file:/"))
        file.remove(0,6);

    if (!eh.loadFromJpeg(file)) {
        qWarning() << "Failed to load exif data from " << file;
        return 0;
    }

    if (!eh.contains(QExifImageHeader::Orientation)) {
        qWarning("exif orientation data not present");
        return 0;
    }

    int r=eh.value(QExifImageHeader::Orientation).toShort();

    qDebug() << "Image " << file << " orientation value is " << r;

    switch (r) {
    case 0:
        return 0;
    case 3:
        return 180;
    case 6:
        return 90;
    case 8:
        return -90;
    default:
        qWarning() << "Unhandled image orientation: " << r;
        return 0;
    }

    return 0;
}

bool AppUtility::removeFile(QString file)
{
    return QFile::remove(file);
}
