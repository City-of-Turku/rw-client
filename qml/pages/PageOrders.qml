/**
 * Orders page
 *
 * Displays the current users orders with delivery status
 * or if user has enough priviledges, the system orders.
 *
 */
import QtQuick 2.8
import QtQml 2.2
import QtQuick.Controls 2.1
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import QtQuick.Controls.Material 2.1

import net.ekotuki 1.0

import "../delegates"
import "../components"

Page {
    id: ordersPage
    title: qsTr("Orders")

    objectName: "orders"

    property string searchString;

    property bool searchActive: false;

    property bool showTotalPrice: false;

    property alias model: orders.model

    Keys.onReleased: {
        if (event.key === Qt.Key_Back) {
            console.log("*** Back button")
            event.accepted = true;
            rootStack.pop()
        }
    }


    Component.onCompleted: {
        orderPage.forceActiveFocus();
        model=root.api.getOrdersModel();
    }

    Connections {
        target: api
    }

    MessagePopup {
        id: messagePopup
    }

    ColumnLayout {
        id: mainContainer
        anchors.fill: parent
        anchors.margins: 4

        Label {
            anchors.centerIn: parent
            visible: orderCart.model.count===0
            text: qsTr("No orders")
            wrapMode: Text.Wrap
            font.pixelSize: 32
        }

        ListView {
            id: orders
            enabled: !searchActive
            clip: true
            Layout.fillWidth: true
            Layout.fillHeight: true

            ScrollIndicator.vertical: ScrollIndicator { }

            delegate: Component {
                OrderItemDelegate {
                    width: parent.width
                    height: childrenRect.height
                    showImage: false
                    compact: true

                    function openProductAtIndex(index) {
                        var p=orderCart.model.get(index);
                        orderCart.currentIndex=index;
                        rootStack.push(productView, { "product": p })
                    }
                }
            }
        }
    }

    BusyIndicator {
        id: busyIndicator
        anchors.centerIn: mainContainer
        running: api.busy
        visible: running
        width: 64
        height: 64
    }
}
