import QtQuick 2.9
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3
import net.ekotuki 1.0
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
        height: bgrect.height

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
                text: orderID + " " + created
                font.pixelSize: 18                
                font.bold: true
            }
            Text {                
                text: ic.getStatus(status)
                font.pixelSize: 16
            }            
            Text {
                text: "Products: "+count
                font.pixelSize: 18
            }

            function getStatus(s) {
                switch (s) {
                case Order.Pending:
                    return qsTr("Pending");
                case Order.Shipped:
                    return qsTr("Shipped");
                case Order.Cart:
                    return qsTr("Cart");
                case Order.Unknown:
                    return qsTr("Unknown");
                }
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

