import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.1

PageSearch {
    id: pageBrowse
    title: qsTr("Browse")
    objectName: "browse"
    searchVisible: false;

    Component.onCompleted: {
        root.api.products(1);
    }
}
