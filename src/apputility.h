#ifndef APPUTILITY_H
#define APPUTILITY_H

#include <QObject>

class AppUtility : public QObject
{
    Q_OBJECT
public:
    explicit AppUtility(QObject *parent = 0);
    Q_INVOKABLE int getImageRotation(QString file);
    Q_INVOKABLE bool remoteFile(QString file);

signals:

public slots:
};

#endif // APPUTILITY_H
