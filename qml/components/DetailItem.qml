import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3

RowLayout {
    id: di
    property alias label: dil.text
    property alias value: div.text

    signal clicked();

    Layout.fillWidth: true

    Label {        
        id: dil
        font.pixelSize: 18
        font.bold: true
        Layout.alignment: Qt.AlignTop
        Layout.minimumWidth: parent.width/4
        Layout.maximumWidth: parent.width/2
    }
    Label {
        id: div
        font.pixelSize: 18
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        Layout.minimumWidth: parent.width/2
        Layout.alignment: Qt.AlignTop
        MouseArea {
            anchors.fill: parent
            onClicked: di.clicked();
        }
    }
}

