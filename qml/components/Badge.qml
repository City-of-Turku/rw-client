import QtQuick 2.10

Rectangle {
    color: "#eaeaea"
    radius: 8
    height: v.height+8
    width: Math.max(v.width+8, v.height)

    property alias text: v.text

    Text {
        id: v
        font.pixelSize: 16
        //minimumPixelSize: 10
        //fontSizeMode: Text.HorizontalFit
        text: amount
        anchors.centerIn: parent
        anchors.rightMargin: 8
        anchors.leftMargin: 8
        anchors.topMargin: 4
        anchors.bottomMargin: 4
    }
}
