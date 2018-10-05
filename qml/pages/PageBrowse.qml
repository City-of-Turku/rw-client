import QtQuick 2.9
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3

PageSearch {
    id: pageBrowse
    title: qsTr("Products")
    objectName: "browse"
    searchVisible: false;

    Component.onCompleted: {
        root.api.products(1);
    }
}
