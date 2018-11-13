/**
 * Order details page
 *
 * Displays a list of products in order
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
    id: orderPage
    title: qsTr("Order")
    objectName: "order"

    property bool showTotalPrice: false;
    property alias model: orderProducts.model

    property OrderItem order;
    property OrderLineItemModel products;

    Keys.onReleased: {
        if (event.key === Qt.Key_Back) {
            console.log("*** Back button")
            event.accepted = true;
            rootStack.pop()
        }
    }

    Component.onCompleted: {
        orderPage.forceActiveFocus();
        model=products;

        console.debug("Cart contains: "+model.count)
    }

    header: ToolbarBasic {
        id: toolbar
        enableBackPop: true
        enableMenuButton: false
        visibleMenuButton: true
        onMenuButton: orderMenu.open();
    }

    Menu {
        id: orderMenu
        MenuItem {
            text: "Cancel order"
            onClicked: {
                api.updateOrderStatus(order, Order.Cancelled);
            }
        }
    }

    footer: ToolBar {
        RowLayout {

        }
    }

    Connections {
        target: api

        onProductFound: {
            console.debug("PageOrder: Product found!")
            rootStack.push(productView, { "product": product })
        }

        onProductNotFound: {
            console.debug("PageOrder: Product NOT found")
            messagePopup.show("Not found", "Product not found", 404);
        }
    }

    MessagePopup {
        id: messagePopup
    }

    Component {
        id: imageDisplayPageComponent
        PageImageDisplay {

        }
    }

    Component {
        id: productView
        PageProductView {

        }
    }

    ColumnLayout {
        id: mainContainer
        anchors.fill: parent
        anchors.margins: 4

        DetailItem {
            label: "Order:"
            value: order.orderID
        }
        DetailItem {
            label: "Status:"
            value: api.getOrderStatusString(order.status)
        }
        DetailItem {
            label: "Created:"
            value: order.created.toLocaleDateString();
        }
        DetailItem {
            label: "Products:"
            value: model.count
        }

        RowLayout {
            Button {
                visible: order.status==OrderItem.Pending
                text: "Start processing order"
                onClicked: {
                    api.updateOrderStatus(order, OrderItem.Processing);
                }
            }
            Button {
                visible: order.status==OrderItem.Processing
                text: "Back to pending"
                onClicked: {
                    api.updateOrderStatus(order, OrderItem.Pending);
                }
            }
            Button {
                visible: order.status==OrderItem.Processing
                text: "Mark as shipped"
//                enabled: order
                onClicked: {
                    api.updateOrderStatus(order, OrderItem.Shipped);
                }
            }
        }

        ListView {
            id: orderProducts
            clip: true
            Layout.fillWidth: true
            Layout.fillHeight: true

            ScrollIndicator.vertical: ScrollIndicator { }

            delegate: Component {
                OrderLineItemDelegate {
                    width: parent.width
                    height: childrenRect.height

                    onClicked: {
                        openProductAtIndex(index)
                    }

                    onPressandhold: {
                        console.debug("PAH")
                        productMenu.open();
                    }

                    Menu {
                        id: productMenu
                        title: qsTr("Product")
                        modal: true
                        dim: true
                        x: parent.width/3
                        MenuItem {
                            text: qsTr("Set Picked")
                            enabled: type=="product"
                            onClicked: {
                                //var o=orderProducts.model.get(index)
                                status=OrderItem.OrderItemPicked
                            }
                        }
                    }

                    function openProductAtIndex(index) {
                        orderProducts.currentIndex=index;
                        var o=orderProducts.model.get(index)

                        console.debug(o.type)
                        if (o.type=="product") {
                            var p=api.getProduct(o.sku, true)
                            if (!p)
                                messagePopup.show("Error", "Failed to request product", 500);
                        } else if (o.type=="shipping") {
                            messagePopup.show("Shipping", o.title);
                        }
                    }
                }
            }
        }


        RowLayout {
            visible: showTotalPrice && orderCart.count>0
            Layout.fillWidth: true
            Layout.fillHeight: false
            Label {
                text: qsTr("Total:")
                Layout.fillWidth: true
            }
            Label {
                id: totalPrice
            }
        }
    }

    Label {
        visible: orderProducts.model.count===0
        anchors.centerIn: mainContainer
        text: qsTr("Order is empty")
        wrapMode: Text.Wrap
        font.pixelSize: 32
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
