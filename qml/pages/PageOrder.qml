/**
 * Order details page
 *
 * Displays a list of products in order
 *
 */
import QtQuick 2.12
import QtQml 2.2
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.1

import net.ekotuki 1.0

import "../delegates"
import "../components"

Page {
    id: orderPage
    title: qsTr("Order")+" ("+order.id+")"
    objectName: "order"

    property bool showTotalPrice: true;
    property alias model: orderProducts.model

    property OrderItem order;
    property OrderLineItemModel products;

    function scanBarcode() {
        rootStack.push(cameraScanner);
    }

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
        enableMenuButton: true
        visibleMenuButton: true
        onMenuButton: orderMenu.open();
    }

    Menu {
        id: orderMenu
        x: toolbar.width - width
        transformOrigin: Menu.TopRight
        modal: true
        MenuItem {
            text: qsTr("Cancel order")
            enabled: order.status==OrderItem.Pending
            onClicked: {
                confirmCancelDialog.open();
            }
        }
    }

    MessageDialog {
        id: confirmCancelDialog
        standardButtons: StandardButton.Ok | StandardButton.Cancel
        icon: StandardIcon.Question
        title: qsTr("Cancel Order ?")
        text: qsTr("Are you sure ?")

        onAccepted: {
            api.updateOrderStatus(order, OrderItem.Cancelled);
        }
    }

    footer: ToolBar {
        RowLayout {
            ToolButton {
                text: qsTr("Scan")
                onClicked: scanBarcode();
            }
        }
    }

    Connections {
        target: products

        onIsPicked: {
            console.debug("Order "+isPicked)
            if (isPicked) {

            }
        }
    }

    Connections {
        target: api

        onProductFound: {
            console.debug("PageOrder: Product found!")
            rootStack.push(productView, { "product": product, "cartDisabled": true })
        }

        onProductNotFound: {
            console.debug("PageOrder: Product NOT found")
            messagePopup.show("Not found", "Product not found", 404);
        }

        onOrderStatusUpdated: {
            messagePopup.show("Order status", "Order status changed");
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

    Component {
        id: cameraScanner
        PageCamera {
            id: scanCamera
            oneShot: false
            Component.onCompleted: {
                scanCamera.startCamera();
            }
            onBarcodeFound: {
                if (!setLineItemPickedByBarcode(barcode)) {
                    messagePopup.show(barcode, "No such product in order");
                } else {
                    messagePopup.show(barcode, "Product marked as picked");
                }
            }
            onDecodeDone: {

            }
        }
    }

    function setLineItemPickedByBarcode(barcode) {
        for (var i=0;i<model.count;i++) {
            var o=model.getItem(i);
            if (o.sku==barcode) {
                o.status=OrderLineItem.OrderItemPicked
                model.refresh(i);
                return true;
            }
        }
        return false;
    }

    ColumnLayout {
        id: mainContainer
        anchors.fill: parent
        spacing: 4

        SwipeView {
            id: orderSwipe
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: orderPage.height/4
            Layout.maximumHeight: orderPage.height/3
            Layout.minimumHeight: orderPage.height/5

            ColumnLayout {
                DetailItem {
                    label: "Status:"
                    value: api.getOrderStatusString(order.status)
                }
                DetailItem {
                    label: "Created:"
                    value: order.created.toLocaleDateString();
                }
                DetailItem {
                    label: "Changed:"
                    value: order.changed.toLocaleDateString();
                }
                DetailItem {
                    label: "Products:"
                    value: model.count
                }
            }

            ColumnLayout {
                Text {
                    text: "Shipping"
                    font.bold: true
                }
                DetailItem {
                    label: "Name:"
                    value: order.shipping["name"];
                }
                DetailItem {
                    label: "Organisation:"
                    value: order.shipping["org"];
                }
                DetailItem {
                    label: "Address:"
                    value: order.shipping["address"]+"\n"+order.shipping["postal_code"]+" "+order.shipping["city"] + "\n" +order.shipping["country"];
                }
                DetailItem {
                    label: "Phone"
                    value: order.shipping["phone"];
                }
                DetailItem {
                    label: "E-Mail"
                    value: order.shipping["email"];
                }
            }
        }

        PageIndicator {
            id: swipeIndicator
            count: orderSwipe.count
            currentIndex: orderSwipe.currentIndex
            //anchors.horizontalCenter: orderSwipe.horizontalCenter
            Layout.alignment: Qt.AlignHCenter
        }

        ListView {
            id: orderProducts
            clip: true
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: orderPage.height/3

            ScrollIndicator.vertical: ScrollIndicator { }

            delegate: Component {
                OrderLineItemDelegate {
                    width: parent.width
                    height: childrenRect.height

                    enablePickStatus: order.status!=OrderItem.Shipped

                    onClicked:  {
                        if (orderProducts.currentIndex==index)
                            openProductAtIndex(index)
                        else
                            orderProducts.currentIndex=index
                    }

                    onDoubleClicked: {
                        openProductAtIndex(index)
                    }

                    onPressAndHold: {
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
                            enabled: type=="product" && status!=OrderLineItem.OrderItemPicked && order.status!=OrderItem.Shipped
                            onClicked: {
                                status=OrderLineItem.OrderItemPicked
                            }
                        }
                        MenuItem {
                            text: qsTr("View product")
                            onClicked: openProductAtIndex(index)
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
            Layout.fillWidth: true
            Button {
                Layout.fillWidth: true
                visible: order.status==OrderItem.Cancelled
                text: qsTr("Redo cancelled order")
                onClicked: {
                    api.updateOrderStatus(order, OrderItem.Pending);
                }
            }
            Button {
                Layout.fillWidth: true
                visible: order.status==OrderItem.Pending
                text: qsTr("Start processing order")
                onClicked: {
                    api.updateOrderStatus(order, OrderItem.Processing);
                }
            }
            Button {
                Layout.fillWidth: true
                visible: order.status==OrderItem.Processing
                text: qsTr("Cancel order processing")
                onClicked: {
                    api.updateOrderStatus(order, OrderItem.Pending);
                }
            }
            Button {
                Layout.fillWidth: true
                visible: order.status==OrderItem.Processing
                text: qsTr("Mark order shipped")
                onClicked: {
                    api.updateOrderStatus(order, OrderItem.Shipped);
                }
            }
        }

        RowLayout {
            visible: showTotalPrice && products.count>0
            Layout.fillWidth: true
            Layout.fillHeight: false
            Label {
                text: qsTr("Total:")
                Layout.fillWidth: true
            }
            Badge {
                id: totalPrice
                text: order.amount.toFixed(2) +" "+ order.currency
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
