import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

PageSearch {
    id: pageBrowse
    title: qsTr("Products")
    objectName: "browse"
    searchVisible: false;

    Component.onCompleted: {
        root.api.products(1);
    }
}
