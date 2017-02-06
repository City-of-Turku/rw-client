#include "androidhelper.h"

#include <QDebug>

AndroidHelper::AndroidHelper(QObject *parent) : QObject(parent)
{   
    resOK = QAndroidJniObject::getStaticField<jint>("android/app/Activity", "RESULT_OK");
    resCANCEL = QAndroidJniObject::getStaticField<jint>("android/app/Activity", "RESULT_CANCELED");
}

bool AndroidHelper::imagePicker()
{
    QAndroidJniObject ACTION_PICK=QAndroidJniObject::getStaticObjectField("android/content/Intent", "ACTION_PICK", "Ljava/lang/String;");
    QAndroidJniObject EXTERNAL_CONTENT_URI=QAndroidJniObject::getStaticObjectField("android/provider/MediaStore$Images$Media", "EXTERNAL_CONTENT_URI", "Landroid/net/Uri;");

    QAndroidJniObject intent=QAndroidJniObject("android/content/Intent", "(Ljava/lang/String;Landroid/net/Uri;)V", ACTION_PICK.object<jstring>(), EXTERNAL_CONTENT_URI.object<jobject>());

    if (ACTION_PICK.isValid() && intent.isValid())
    {
        intent.callObjectMethod("setType", "(Ljava/lang/String;)Landroid/content/Intent;", QAndroidJniObject::fromString("image/*").object<jstring>());
        QtAndroid::startActivity(intent.object<jobject>(), ImagePicker, this);
        qDebug() << "ImagePicker activity started";
        return true;
    }
    qWarning("Failed to start ImagePicker");
    return false;
}

void AndroidHelper::handleActivityResult(int receiverRequestCode, int resultCode, const QAndroidJniObject &data)
{
    qDebug() << "handleActivityResult: RRC: " << receiverRequestCode << " RC: " << resultCode;


    switch (receiverRequestCode) {
    case ImagePicker:
        if (resultCode == resOK) {
            QAndroidJniEnvironment env;
            QAndroidJniObject uri = data.callObjectMethod("getData", "()Landroid/net/Uri;");
            QAndroidJniObject proj = QAndroidJniObject::getStaticObjectField("android/provider/MediaStore$MediaColumns", "DATA", "Ljava/lang/String;");

            jobjectArray stringArray = (jobjectArray)env->NewObjectArray(1, env->FindClass("java/lang/String"), NULL);
            jobject projStr = env->NewStringUTF(proj.toString().toStdString().c_str());
            env->SetObjectArrayElement(stringArray, 0, projStr);

            QAndroidJniObject contentResolver = QtAndroid::androidActivity().callObjectMethod("getContentResolver", "()Landroid/content/ContentResolver;");
            QAndroidJniObject cursor = contentResolver.callObjectMethod("query", "(Landroid/net/Uri;[Ljava/lang/String;Ljava/lang/String;[Ljava/lang/String;Ljava/lang/String;)Landroid/database/Cursor;", uri.object<jobject>(), stringArray, NULL, NULL, NULL);
            jint columnIndex = cursor.callMethod<jint>("getColumnIndex", "(Ljava/lang/String;)I", proj.object<jstring>());
            cursor.callMethod<jboolean>("moveToFirst", "()Z");

            QAndroidJniObject res = cursor.callObjectMethod("getString", "(I)Ljava/lang/String;", columnIndex);
            if (res.isValid()) {
                QString src = "file://" + res.toString();
                qDebug() << src;
                emit imagePicked(src);
            } else {
                emit imagePickError();
            }
        } else if (resultCode==resCANCEL) {
            qDebug("ImagePick canceled");
        } else {
            emit imagePickError();
        }
        break;
    default:
        qWarning() << "Unknown receiverRequestCode " << receiverRequestCode;
        break;
    }
}
