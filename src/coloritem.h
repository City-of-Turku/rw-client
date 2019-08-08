#ifndef COLORITEM_H
#define COLORITEM_H

#include <QObject>
#include <QVariantMap>

class ColorItem : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString cid MEMBER m_cid NOTIFY cidChanged)
    Q_PROPERTY(QString color MEMBER m_color NOTIFY colorChanged)
    Q_PROPERTY(QString code MEMBER m_code NOTIFY codeChanged)

public:
    explicit ColorItem(QObject *parent = nullptr);
    explicit ColorItem(const QString &cid, const QString &color, const QString &code, QObject *parent = nullptr);

    ColorItem *fromVariantMap(const QVariantMap &data, QObject *parent = nullptr);

signals:
    void cidChanged(QString cid);
    void colorChanged(QString color);
    void codeChanged(QString code);

private:
    QString m_cid;
    QString m_color;
    QString m_code;

};

#endif // COLORITEM_H
