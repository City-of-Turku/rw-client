TEMPLATE = app

QT += qml quick widgets multimedia svg quickcontrols2 webview
QT += positioning

CONFIG += c++11

defineTest(minQtVersion) {
    maj = $$1
    min = $$2
    patch = $$3
    isEqual(QT_MAJOR_VERSION, $$maj) {
        isEqual(QT_MINOR_VERSION, $$min) {
            isEqual(QT_PATCH_VERSION, $$patch) {
                return(true)
            }
            greaterThan(QT_PATCH_VERSION, $$patch) {
                return(true)
            }
        }
        greaterThan(QT_MINOR_VERSION, $$min) {
            return(true)
        }
    }
    greaterThan(QT_MAJOR_VERSION, $$maj) {
        return(true)
    }
    return(false)
}

!minQtVersion(5, 14, 0) {
    message("Cannot build RW-Client with Qt version $${QT_VERSION}.")
    error("Use at least Qt 5.14.0.")
}

# Create your own build profile first, copy profile.pri.sample to profile.pri
# and adjust for your system. Don't change this line.
include(profile.pri)

HEADERS += \
    src/coloritem.h \
    src/colormodel.h \
    src/eanvalidator.h \
    src/organizationitem.h \
    src/organizationmodel.h \
    src/rvapi.h \
    src/itemlistmodel.h \
    src/productitem.h \
    src/locationitem.h \
    src/locationmodel.h \
    src/categorymodel.h src/settings.h \
    3rdparty/qexifimageheader/qexifimageheader.h \
    src/apputility.h \
    src/ordersmodel.h \
    src/baselistmodel.h \
    src/orderitem.h \
    src/orderlineitem.h \
    src/orderlineitemmodel.h \
    src/rwnetworkaccessmanagerfactory.h

SOURCES += src/main.cpp \
    src/coloritem.cpp \
    src/colormodel.cpp \
    src/eanvalidator.cpp \
    src/organizationitem.cpp \
    src/organizationmodel.cpp \
    src/rvapi.cpp \
    src/itemlistmodel.cpp \
    src/productitem.cpp \
    src/locationmodel.cpp \
    src/categorymodel.cpp src/settings.cpp \
    3rdparty/qexifimageheader/qexifimageheader.cpp \
    src/apputility.cpp \
    src/ordersmodel.cpp \
    src/baselistmodel.cpp \
    src/orderitem.cpp \
    src/orderlineitem.cpp \
    src/orderlineitemmodel.cpp \
    src/rwnetworkaccessmanagerfactory.cpp

lupdate_only {
    SOURCES +=  qml/*.qml qml/components/*.qml qml/pages/*.qml qml/delegates/*.qml qml/models/*.qml
}

include(3rdparty/barcodevideofilter/barcodevideofilter.pri)
INCLUDEPATH += 3rdparty/barcodevideofilter

# Generic mode
include(3rdparty/cutegenericmodel/libcutegenericmodel/cutegenericmodel-static.pri)

# Android specific stuff
include(android.pri)

# iOS specific stuff
include(ios/darwin.pri)

OTHER_FILES += \
    qml/*.qml qml/pages/*.qml qml/delegates/*.qml qml/models/*.qml qml/components/*.qml *.xml

RESOURCES += qml.qrc \
  images.qrc

RESOURCES += translations.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Default rules for deployment.
include(deployment.pri)

# Translation
# From: https://wiki.qt.io/Automating_generation_of_qm_files

#LANGUAGES = en fi sv
LANGUAGES = fi sv

defineReplace(prependAll) {
 for(a,$$1):result ''= $$2$${a}$$3
 return($$result)
}

TRANSLATIONS = \
    translations/rw-client_fi.ts \
    translations/rw-client_sv.ts

#TRANSLATIONS = $$prependAll(LANGUAGES, $$PWD/translations/rw-client_, .ts)
#TRANSLATIONS_FILES =
 
qtPrepareTool(LRELEASE, lrelease)
for(tsfile, TRANSLATIONS) {
 qmfile = $$shadowed($$tsfile)
 qmfile ~= s,.ts$,.qm,
 qmdir = $$dirname(qmfile)
 !exists($$qmdir) {
 mkpath($$qmdir)|error("Aborting.")
 }
 command = $$LRELEASE -removeidentical $$tsfile -qm $$qmfile
 system($$command)|error("Failed to run: $$command")
 TRANSLATIONS_FILES''= $$qmfile
}

#wd = $$replace(PWD, /, $$QMAKE_DIR_SEP)
 
#qtPrepareTool(LUPDATE, lupdate)
#LUPDATE ''= -locations relative -no-ui-lines
#TSFILES = $$files($$PWD/translations/rvtku_''''.ts) $$PWD/translations/rvtku_untranslated.ts
#for(file, TSFILES) {
# lang = $$replace(file, .''''_([^/]*).ts, 1)
# v = ts-$${lang}.commands
# $$v = cd $$wd && $$LUPDATE $$SOURCES $$APP_FILES -ts $$file
# QMAKE_EXTRA_TARGETS''= ts-$$lang
#}
#ts-all.commands = cd $$PWD && $$LUPDATE $$SOURCES $$APP_FILES -ts $$TSFILES
#QMAKE_EXTRA_TARGETS ''= ts-all

DISTFILES += \
    qml/components/BadgePrice.qml \
    qml/pages/PageCart.qml

ANDROID_ABIS = armeabi-v7a


android: include(/home/milang/Android/Sdk/android_openssl/openssl.pri)
