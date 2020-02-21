import QtQuick 2.12
import QtQuick.Controls 2.12

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
