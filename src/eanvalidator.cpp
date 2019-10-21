#include "eanvalidator.h"

#include <QDebug>

EANValidator::EANValidator(QObject *parent) : QValidator(parent)
{

}

QValidator::State EANValidator::validate(QString &code, int &pos) const
{
    Q_UNUSED(pos)
    int val=0;

    qDebug() << code << pos;

    if (code.length()<13)
        return QValidator::Intermediate;

    if (code.length()>13)
        return QValidator::Invalid;

    for (int i=0;i<12;i++) {
        const QChar c=code.at(i);
        if (c.isDigit()==false)
            return QValidator::Invalid;        

        val+=c.digitValue()*((i % 2==0) ? 1 : 3);
    }
    int cd=(10-(val % 10)) % 10;

    return code.at(12).digitValue()==cd ? QValidator::Acceptable : QValidator::Invalid;
}

void EANValidator::fixup(QString &code) const
{
    code=code.trimmed();
}
