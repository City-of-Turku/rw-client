import QtQuick 2.8
import QtQml 2.2
import QtQuick.Controls 2.2

RoundButton {
    id: button
    property alias source: image.source
    contentItem: Image {
        id: image
        fillMode: Image.Pad
        horizontalAlignment: Image.AlignHCenter
        verticalAlignment: Image.AlignVCenter
    }
    Behavior on opacity {
        NumberAnimation { duration: 250 }
    }
}
