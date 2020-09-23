android {
 message("Building for android target $${ANDROID_TARGET_ARCH}.")

 QT += androidextras
contains(ANDROID_TARGET_ARCH,armeabi-v7a) {
 QMAKE_CXXFLAGS += -mfpu=neon
}
 HEADERS += src/androidhelper.h
 SOURCES += src/androidhelper.cpp
}


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

#
#contains(ANDROID_TARGET_ARCH,armeabi-v7a) {
#    ANDROID_EXTRA_LIBS = \
#        $$PWD/3rdparty/openssl-armv7/libcrypto.so \
#        $$PWD/3rdparty/openssl-armv7/libssl.so
#}
#
#contains(ANDROID_TARGET_ARCH,arm64-v8a) {
#    ANDROID_EXTRA_LIBS = \
#        $$PWD/3rdparty/openssl-arm64v8/libcrypto.so \
#        $$PWD/3rdparty/openssl-arm64v8/libssl.so
#}
