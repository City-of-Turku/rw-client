TEMPLATE = app

QT += qml quick widgets multimedia svg quickcontrols2 webview
QT += positioning

CONFIG += c++11

# Create your own build profile first, copy profile.pri.sample to profile.pri
# and adjust for your system. Don't change this line.
include(profile.pri)

HEADERS += \
    src/rvapi.h \
    src/itemlistmodel.h \
    src/productitem.h \
    src/locationitem.h \
    src/locationmodel.h \
    src/categorymodel.h src/settings.h \
    3rdparty/qexifimageheader/qexifimageheader.h \
    src/apputility.h

SOURCES += src/main.cpp \
    src/rvapi.cpp \
    src/itemlistmodel.cpp \
    src/productitem.cpp \
    src/locationmodel.cpp \
    src/categorymodel.cpp src/settings.cpp \
    3rdparty/qexifimageheader/qexifimageheader.cpp \
    src/apputility.cpp

lupdate_only {
    SOURCES +=  qml/*.qml qml/components/*.qml qml/pages/*.qml qml/delegates/*.qml qml/models/*.qml
}

android {
 QT += androidextras
 QMAKE_CXXFLAGS += -mfpu=neon
 HEADERS += src/androidhelper.h
 SOURCES += src/androidhelper.cpp
}

OTHER_FILES += \
    qml/*.qml qml/pages/*.qml qml/delegates/*.qml qml/models/*.qml qml/components/*.qml *.xml

RESOURCES += qml.qrc \
  images.qrc

RESOURCES += translations.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Default rules for deployment.
include(deployment.pri)

include(3rdparty/barcodevideofilter/barcodevideofilter.pri)

INCLUDEPATH += 3rdparty/barcodevideofilter

# Translation
# From: https://wiki.qt.io/Automating_generation_of_qm_files

#LANGUAGES = en fi sv
LANGUAGES = fi sv

defineReplace(prependAll) {
 for(a,$$1):result ''= $$2$${a}$$3
 return($$result)
}

TRANSLATIONS = $$prependAll(LANGUAGES, $$PWD/translations/rvtku_, .ts)

TRANSLATIONS_FILES =
 
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

wd = $$replace(PWD, /, $$QMAKE_DIR_SEP)
 
qtPrepareTool(LUPDATE, lupdate)
LUPDATE ''= -locations relative -no-ui-lines
TSFILES = $$files($$PWD/translations/rvtku_''''.ts) $$PWD/translations/rvtku_untranslated.ts
for(file, TSFILES) {
 lang = $$replace(file, .''''_([^/]*).ts, 1)
 v = ts-$${lang}.commands
 $$v = cd $$wd && $$LUPDATE $$SOURCES $$APP_FILES -ts $$file
 QMAKE_EXTRA_TARGETS''= ts-$$lang
}
ts-all.commands = cd $$PWD && $$LUPDATE $$SOURCES $$APP_FILES -ts $$TSFILES
QMAKE_EXTRA_TARGETS ''= ts-all

DISTFILES += \
    android/AndroidManifest.xml \
    android/gradle/wrapper/gradle-wrapper.jar \
    android/gradlew \
    android/res/values/libs.xml \
    android/build.gradle \
    android/gradle/wrapper/gradle-wrapper.properties \
    android/gradlew.bat \
    qml/components/BarcodeScannerField.qml \
    qml/components/LocationListView.qml \
    qml/components/LocationPopup.qml \
    qml/components/ToolbarBasic.qml

ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android

contains(ANDROID_TARGET_ARCH,armeabi-v7a) {
    ANDROID_EXTRA_LIBS = \
        $$PWD/3rdparty/openssl-armv7/libcrypto.so \
        $$PWD/3rdparty/openssl-armv7/libssl.so
}
