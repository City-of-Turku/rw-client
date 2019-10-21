#ifndef EANVALIDATOR_H
#define EANVALIDATOR_H

#include <QObject>
#include <QValidator>

class EANValidator : public QValidator
{
    Q_OBJECT
public:
    EANValidator(QObject *parent = nullptr);

public:
    State validate(QString &code, int &pos) const;
    void fixup(QString &code) const;
};

#endif // EANVALIDATOR_H
