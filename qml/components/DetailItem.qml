import QtQuick 2.9
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3

RowLayout {
    id: di
    property string label: ""
    property string value: ""
    Label {
        text: di.label
        font.pixelSize: 18
        width: parent.width/3
    }
    Label {
        text: di.value
        font.pixelSize: 16
        Layout.fillWidth: true
    }
}

