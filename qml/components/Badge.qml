import QtQuick 2.12

Rectangle {
    color: "#eaeaea"
    radius: 8
    height: v.height+8
    implicitWidth: Math.max(v.width+8, v.height)

    property alias text: v.text
    property alias pixelSize: v.font.pixelSize

    Text {
        id: v
        font.pixelSize: 16        
        text: amount
        anchors.centerIn: parent
        anchors.rightMargin: 4
        anchors.leftMargin: 4
        anchors.topMargin: 4
        anchors.bottomMargin: 4
    }
}
