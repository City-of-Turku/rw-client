import QtQuick 2.9
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3

RowLayout {
    id: di
    property alias label: dil.text
    property alias value: div.text

    Label {
        id: dil
        font.pixelSize: 18
        font.bold: true
    }
    Label {
        id: div
        font.pixelSize: 18
        Layout.fillWidth: true
    }
}

