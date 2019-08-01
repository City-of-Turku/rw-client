import QtQuick 2.12

Image {
    fillMode: Image.Pad
    horizontalAlignment: Image.AlignHCenter
    verticalAlignment: Image.AlignVCenter
    opacity: parent.enabled ? 1.0 : 0.8
}
