import QtQuick 2.9
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3
import net.ekotuki 1.0
import "../components"

Rectangle {
    id: wrapper
    color: getColor(ListView.isCurrentItem, index, type)

    signal clicked(variant index)
    signal pressandhold(variant index)

    height: c.height

    function getColor(ci, index, type) {
        if (type=='product')
            return ListView.isCurrentItem ? "#00aeef" : (index % 2) ? "#ffffff" : "#fafafa"
        return "#efae00";
    }

    RowLayout {
        id: c
        width: parent.width
        ColumnLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: parent.width-attrCol.width
            spacing: 2
            Text {
                text: title
                font.pixelSize: 18
                font.bold: true
                elide: Text.ElideRight
            }
            Text {
                text: sku
                font.pixelSize: 16
                maximumLineCount: 1
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: 12
            }
        }
        ColumnLayout {
            id: attrCol
            Layout.alignment: Qt.AlignRight
            Badge {
                text: amount
            }
            Badge {
                visible: type=="product"
                text: getPickedStatus(status)
                function getPickedStatus(s) {
                    switch (s) {
                    case OrderItem.OrderItemPending:
                        return "Pending"
                    case OrderItem.OrderItemPicked:
                        return "Picked"
                    case OrderItem.OrderItemNotFound:
                        return "Not found"
                    }
                }
            }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        onClicked: wrapper.clicked(index)
        onPressAndHold: wrapper.pressandhold(index)
    }
}

