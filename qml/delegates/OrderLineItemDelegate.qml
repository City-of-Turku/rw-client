import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3
import net.ekotuki 1.0
import "../components"

Rectangle {
    id: wrapper
    color: getColor(ListView.isCurrentItem, index, type, status)

    signal clicked(variant index)
    signal doubleClicked(variant index)
    signal pressAndHold(variant index)

    property bool enablePickStatus: true

    height: c.height

    function getColor(ci, index, type, status) {
        if (type=='product' && status!=OrderLineItem.OrderItemPicked)
            return ListView.isCurrentItem ? "#00aeef" : (index % 2) ? "#f0f0f0" : "#fbfbfb"

        if (type=='product' && status==OrderLineItem.OrderItemPicked)
            return ListView.isCurrentItem ? "#00ae90" : (index % 2) ? "#00ae20" : "#00ae50"

        return "#efae00";
    }

    RowLayout {
        id: c
        width: parent.width
        spacing: 4
        ColumnLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: parent.width-attrCol.width
            spacing: 4
            Text {
                text: title
                font.pixelSize: 18
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Text {
                text: sku
                font.pixelSize: 18
                maximumLineCount: 1
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: 14
                Layout.fillWidth: true
            }
        }
        ColumnLayout {
            id: attrCol
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: false
            spacing: 4
            Badge {
                text: amount
            }
            Badge {
                visible: type=="product" && enablePickStatus
                text: getPickedStatus(status)
                function getPickedStatus(s) {
                    switch (s) {
                    case OrderLineItem.OrderItemPending:
                        return qsTr("Pending")
                    case OrderLineItem.OrderItemPicked:
                        return qsTr("Picked")
                    case OrderLineItem.OrderItemNotFound:
                        return qsTr("Not found")
                    }
                    return ""
                }
            }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        onClicked: wrapper.clicked(index)
        // onDoubleClicked: wrapper.
        onPressAndHold: wrapper.pressAndHold(index)
    }
}

