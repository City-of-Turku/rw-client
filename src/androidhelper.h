#ifndef ANDROIDHELPER_H
#define ANDROIDHELPER_H

#include <QObject>
#include <QtAndroidExtras>
#include <QAndroidActivityResultReceiver>

class AndroidHelper : public QObject, QAndroidActivityResultReceiver
{
    Q_OBJECT
public:
    explicit AndroidHelper(QObject *parent = 0);
    Q_INVOKABLE bool imagePicker();

    void handleActivityResult(int receiverRequestCode, int resultCode, const QAndroidJniObject &data);

signals:
    void imagePicked(QString src);
    void imagePickError();

public slots:

private:
    enum RequestCode { ImagePicker = 100 };
    jint resOK;
    jint resCANCEL;
};

#endif // ANDROIDHELPER_H
