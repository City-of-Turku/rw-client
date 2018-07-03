import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.1
import "../components"

Rectangle {
    id: wrapper
    color: ListView.isCurrentItem ? "#f0f0f0" : "#ffffff"

    signal clicked(variant index)
    signal clickedImage(variant index)
    signal pressandhold(variant index)

    property bool showImage: true

    Item {
        id: r
        //spacing: 4
        width: parent.width
        height: showImage ? imageItem.height : bgrect.height

        Rectangle {
            id: bgrect
            color: "white"
            opacity: 0.7
            anchors.bottom: r.bottom
            width: r.width
            height: ic.height+16
        }

        Column {
            id: ic
            spacing: 2
            width: r.width-32
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.margins: 8
            anchors.bottom: r.bottom

            Text {
                width: parent.width
                text: orderID
                font.pixelSize: 18
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: orderStatus
                font.pixelSize: 18
                elide: Text.ElideRight
            }
        }

        MouseArea {
            anchors.fill: ic
            onClicked: {
                wrapper.clicked(index)
            }
            onPressAndHold: {
                wrapper.pressandhold(index)
            }
        }
    }
}

