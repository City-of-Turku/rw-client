/**
 * Orders page
 *
 * Displays the current users orders with delivery status
 * or if user has enough priviledges, the system orders.
 *
 */
import QtQuick 2.9
import QtQml 2.2
import QtQuick.Controls 2.4
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.1

import net.ekotuki 1.0

import "../delegates"
import "../components"

Page {
    id: ordersPage
    title: qsTr("Orders")
    objectName: "orders"

    property alias model: orders.model
    property int orderStatus: ServerApi.OrderPending

    // Refresh Orders list when it gets activated
    StackView.onActivated: {
        refreshOrders(orderStatus);
    }

    function refreshOrders(f) {
        orderStatus=f;
        root.api.orders(f);
    }

    Keys.onReleased: {
        switch (event.key) {
        case Qt.Key_Back:
            event.accepted=true;
            rootStack.pop()
            break;
        case Qt.Key_Home:
            orders.positionViewAtBeginning()
            event.accepted=true;
            break;
        case Qt.Key_End:
            orders.positionViewAtEnd()
            event.accepted=true;
            break;
        case Qt.Key_Space:
            orders.flick(0, -orders.maximumFlickVelocity)
            event.accepted=true;
            break;
        case Qt.Key_PageDown:
            orders.flick(0, -orders.maximumFlickVelocity)
            event.accepted=true;
            break;
        case Qt.Key_PageUp:
            orders.flick(0, orders.maximumFlickVelocity)
            event.accepted=true;
            break;
        case Qt.Key_F5:
            root.api.orders();
            event.accepted=true;
            break;
        }
    }

    Component.onCompleted: {        
        ordersPage.forceActiveFocus();
        model=root.api.getOrderModel();        
    }

    header: ToolbarBasic {
        id: toolbar
        enableBackPop: true
        enableMenuButton: false
        visibleMenuButton: false        
    }

    footer: ToolBar {
        visible: false
        RowLayout {
            ToolButton {                
                text: qsTr("Pending")
                enabled: !api.busy
                onClicked: {
                    refreshOrders(ServerApi.OrderPending);
                }
            }
            ToolButton {
                text: qsTr("In progress")
                enabled: !api.busy
                onClicked: {                    
                    refreshOrders(ServerApi.OrderProcessing);
                }
            }
        }
    }

    MessagePopup {
        id: messagePopup
    }

    ColumnLayout {
        id: mainContainer
        anchors.fill: parent
        anchors.margins: 4

        TabBar {
            Layout.fillWidth: true
            enabled: !api.busy
            TabButton {
                text: qsTr("Pending")
                onClicked: {
                    refreshOrders(ServerApi.OrderPending);
                }
            }
            TabButton {
                text: qsTr("Processings")
                onClicked: {
                    refreshOrders(ServerApi.OrderProcessing);
                }
            }
            TabButton {
                text: qsTr("Complete")
                onClicked: {
                    refreshOrders(ServerApi.OrderComplete);
                }
            }
        }

        ListView {
            id: orders            
            clip: true
            Layout.fillWidth: true
            Layout.fillHeight: true
            enabled: !api.busy

            ScrollIndicator.vertical: ScrollIndicator { }

            header: Component {
                Text {
                    id: name
                    width: parent.width
                    text: api.getOrderFilterStatusString(orderStatus)
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            delegate: Component {
                OrderItemDelegate {
                    width: parent.width
                    //height: childrenRect.height

                    onClicked: openOrderAtIndex(index)

                    function openOrderAtIndex(index) {
                        var o=orders.model.getItem(index);
                        var p=orders.model.getItemLineItemModel(index);
                        orders.currentIndex=index;
                        rootStack.push(orderView, { "order": o, "products": p })
                    }
                }
            }
        }

        Label {
            visible: orders.model.count===0 && !api.busy
            text: qsTr("No orders")
            wrapMode: Text.Wrap
            font.pixelSize: 32
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignCenter
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
