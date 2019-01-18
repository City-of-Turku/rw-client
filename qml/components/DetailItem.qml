import QtQuick 2.10
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3

RowLayout {
    id: di
    property alias label: dil.text
    property alias value: div.text

    signal clicked();

    Label {        
        id: dil
        font.pixelSize: 18
        font.bold: true
        Layout.alignment: Qt.AlignTop
    }
    Label {
        id: div
        font.pixelSize: 18
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
        MouseArea {
            anchors.fill: parent
            onClicked: di.clicked();
        }
    }
}

