import QtQuick 2.9
import QtQuick.Controls 2.4

ComboBox {
    id: cb
    currentIndex: -1

    property alias placeHolder: cbph.text

    property int invalidIndex: -1

    Label {
        id: cbph
        anchors.centerIn: cb
        visible: cb.currentIndex==invalidIndex
        // visible: !cb.enabled && cb.currentIndex==-1
        color: "grey"
    }
}
