import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

PageSearch {
    id: pageBrowse
    title: qsTr("Products")
    objectName: "browse"
    searchVisible: false;

    Component.onCompleted: {
        root.api.products(1);
    }
}
