#ifndef COLORMODEL_H
#define COLORMODEL_H

#include <QObject>

#include "abstractobjectmodel.h"
#include "coloritem.h"

class ColorModel : public Cute::AbstractObjectModel
{
    Q_OBJECT
public:
    explicit ColorModel(QObject *parent = nullptr);
    Q_INVOKABLE ColorItem *getItem(int index) const;

};

#endif // COLORMODEL_H
