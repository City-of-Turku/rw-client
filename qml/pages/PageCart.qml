/**
 * Cart page
 *
 * Displays the users shopping cart with a list of products to order with barcode input
 *
 */
import QtQuick 2.12
import QtQml 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import net.ekotuki 1.0

import "../delegates"
import "../components"

Page {
    id: orderPage
    title: orderCart.model && orderCart.model.count>0 ? qsTr("Cart")+" ("+orderCart.model.count+")" : qsTr("Cart")

    objectName: "cart"

    property string searchString;

    property bool searchActive: false;

    property bool showTotalPrice: false;

    property alias model: orderCart.model

    signal searchBarcodeRequested(string barcode);
    signal searchCancel();

    StackView.onActivated: {
        refreshCart();
    }

    function refreshCart() {
        api.getUserCart();
    }

    function cartCheckedOut() {
        messagePopup.show(qsTr("Cart"), qsTr("Cart succesfully checked out!"));
        refreshCart();
    }

    // searchRequested handler should call this
    function setSearchActive(a) {
        searchActive=a;
        if (a && Qt.inputMethod.visible)
            Qt.inputMethod.hide();
    }

    function searchBarcode(barcode) {
        if (api.validateBarcode(barcode)) {
            searchString=barcode
            searchBarcodeRequested(barcode);
        } else {
            searchString=''
            messagePopup.show(qsTr("Barcode"), qsTr("Barcode format is not recognized. Please try again."));
        }
    }

    function searchBarcodeNotFound() {
        messagePopup.show(qsTr("Not found"), qsTr("No product matched given barcode"));
    }

    function searchComplete() {
        setSearchActive(false)
        var p=api.getProduct(searchString);
        if (!p)
            return;

        if (p.stock===0) {
            messagePopup.show(qsTr("No stock"), qsTr("Product is out of stock"));
        } else {
            model.appendProduct(searchString);                        
        }
        barcodeField.clear();
        orderCart.forceActiveFocus();
    }

    function orderCreated() {        
        rootStack.pop();
    }

    Keys.onReleased: {
        switch (event.key) {
        case Qt.Key_Back:
            event.accepted=true;
            rootStack.pop()
            break;
        case Qt.Key_Home:
            orderCart.positionViewAtBeginning()
            event.accepted=true;
            break;
        case Qt.Key_End:
            orderCart.positionViewAtEnd()
            event.accepted=true;
            break;
        case Qt.Key_Space:
            orderCart.flick(0, -orderCart.maximumFlickVelocity)
            event.accepted=true;
            break;
        case Qt.Key_PageDown:
            orderCart.flick(0, -orderCart.maximumFlickVelocity)
            event.accepted=true;
            break;
        case Qt.Key_PageUp:
            orderCart.flick(0, orderCart.maximumFlickVelocity)
            event.accepted=true;
            break;
        //case Qt.Key_B:
        //    scanBarcode();
        //    event.accepted=true;
        //    break;
        }
    }

    Component.onCompleted: {
        orderPage.forceActiveFocus();
        model=root.api.getCartModel();

        console.debug("Cart contains: "+model.count)
    }

    header: ToolbarBasic {
        id: toolbar
        enableBackPop: true
        enableMenuButton: !api.busy
        visibleMenuButton: true
        onMenuButton: cartMenu.open()
    }

    Menu {
        id: cartMenu
        x: toolbar.width - width
        transformOrigin: Menu.TopRight
        modal: true
        MenuItem {
            text: qsTr("Refresh")
            onTriggered: api.getUserCart()
        }
        MenuItem {
            text: qsTr("Clear")
            enabled: orderCart.model.count>0
            onTriggered: confirmClearDialog.open();
        }
    }

    MessageDialog {
        id: confirmDialog
        standardButtons: StandardButton.Ok | StandardButton.Cancel
        title: qsTr("Cart")
        text: qsTr("Checkout cart ?")

        onAccepted: {
            confirmDialog.close();
            if (!api.checkoutCart()) {
                messagePopup.show(qsTr("Cart"), qsTr("Failed to request cart checkout"));
            }
        }
    }

    MessageDialog {
        id: confirmClearDialog
        standardButtons: StandardButton.Ok | StandardButton.Cancel
        title: qsTr("Cart")
        text: qsTr("Clear shopping cart ?")

        onAccepted: {
            confirmDialog.close();
            api.clearUserCart()
        }
    }

    function scanBarcode() {
        rootStack.push(cameraScanner);
    }

    footer: ToolBar {
        RowLayout {
            ToolButton {
                text: qsTr("Scan")
                enabled: !searchActive && searchString==''
                onClicked: {
                    scanBarcode();
                }
            }

            ToolSeparator {

            }

            ToolButton {
                text: qsTr("Checkout")
                visible: api.hasRole("checkout")
                enabled: orderCart.count>0 && !api.busy
                onClicked: {
                    confirmDialog.open();
                }
            }
        }
    }

    Component {
        id: cameraScanner
        PageCamera {
            id: scanCamera
            oneShot: true
            Component.onCompleted: {
                scanCamera.startCamera();
            }
            onBarcodeFound: {
                searchString=barcode;
            }
            onDecodeDone: {
                searchBarcode(searchString)
            }
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

    Connections {
        target: api

        onProductFound: {
            console.debug("PageCart: Product found!")
            rootStack.push(productView, { "product": product, "cartDisabled": true })
        }

        onProductNotFound: {
            console.debug("PageCart: Product NOT found")
            messagePopup.show("Not found", "Product not found", 404);
        }
    }

    ColumnLayout {
        id: mainContainer
        anchors.fill: parent
        anchors.margins: 4

        Text {
            Layout.fillWidth: true
            visible: orderCart.model.count===0
            text: qsTr("Cart is empty")
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            font.pixelSize: 32
        }

        ListViewRefresh {
            id: orderCart
            enabled: !searchActive
            clip: true
            Layout.fillWidth: true
            Layout.fillHeight: true

            ScrollIndicator.vertical: ScrollIndicator { }

            onRefreshTriggered: {
                api.getUserCart();
            }

            delegate: Component {
                OrderLineItemDelegate {
                    width: parent.width
                    height: childrenRect.height
                    onClicked: {
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
                            text: qsTr("Details")
                            onClicked: {
                                openProductAtIndex(index)
                            }
                        }

                        MenuItem {
                            text: qsTr("Remove")
                            enabled: false
                            onClicked: {
                                orderCart.model.remove(index);
                            }
                        }
                    }

                    function openProductAtIndex(index) {
                        var o=orderCart.model.getItem(index);
                        orderCart.currentIndex=index;
                        var p=api.getProduct(o.sku, true)
                        // XXX: Check return value
                    }

                    function openProductImageAtIndex(index) {
                        var p=orderCart.model.get(index);
                        orderCart.currentIndex=index;
                        rootStack.push(imageDisplayPageComponent, { image: p.thumbnail })
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

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            BarcodeField {
                id: barcodeField
                enabled: !api.busy
                onAccepted: {
                    console.debug("BARCODESEARCH: "+text)
                    searchString=text
                    searchBarcode(searchString)
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
