#include "eanvalidator.h"

#include <QDebug>

EANValidator::EANValidator(QObject *parent) : QValidator(parent)
{

}

QValidator::State EANValidator::validate(QString &code, int &pos) const
{
    Q_UNUSED(pos)
    int val=0,eanl=0;

    if (code.length()==0)
        return QValidator::Intermediate;

    if (code.at(pos-1).isDigit()==false)
        return QValidator::Invalid;

    if ((code.length()<8 || code.length()>8) && code.length()<13)
        return QValidator::Intermediate;

    if (code.length()>13)
        return QValidator::Invalid;

    if (code.length()==8)
        eanl=7;
    else if (code.length()==13)
        eanl=12;
    else
        return QValidator::Intermediate;

    qDebug() << code << code.length() << pos << eanl;

    for (int i=0;i<eanl;i++) {
        const QChar c=code.at(i);
        if (c.isDigit()==false) {
            pos=i;
            return QValidator::Invalid;
        }

        val+=c.digitValue()*((i % 2==0) ? 1 : 3);
    }
    int cd=(10-(val % 10)) % 10;

    return code.at(eanl).digitValue()==cd ? QValidator::Acceptable : QValidator::Intermediate; // (eanl==12 ? QValidator::Invalid : QValidator::Intermediate);
}

void EANValidator::fixup(QString &code) const
{
    code=code.trimmed();
    code.truncate(13);
}
