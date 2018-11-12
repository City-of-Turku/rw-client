/**
 * Cart page
 *
 * Displays the users shopping cart with a list of products to order with barcode input
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
    title: qsTr("Cart")

    objectName: "cart"

    property string searchString;

    property bool searchActive: false;

    property bool showTotalPrice: false;

    property alias model: orderCart.model

    signal searchBarcodeRequested(string barcode);
    signal searchCancel();

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
        api.clearProductStore();
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
        case Qt.Key_B:
            scanBarcode();
            event.accepted=true;
            break;
        }
    }


    Component.onCompleted: {
        orderPage.forceActiveFocus();
        model=root.api.getCartModel();

        console.debug("Cart contains: "+model.count)
    }

    MessageDialog {
        id: confirmDialog
        standardButtons: StandardButton.Ok | StandardButton.Cancel
        title: qsTr("Confirm order")
        text: qsTr("Commit product order ?")

        onAccepted: {
            confirmDialog.close();
            var r=api.createOrder(true);
            if (!r) {
                messagePopup.show("Order", "Failed to create order");
            } else {

            }
        }
    }

    MessageDialog {
        id: confirmClearDialog
        standardButtons: StandardButton.Ok | StandardButton.Cancel
        title: qsTr("Clear order")
        text: qsTr("Clear product order ?")

        onAccepted: {
            confirmDialog.close();
            orderPage.model.clear();
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

            ToolButton {
                text: qsTr("Send order")
                enabled: orderCart.count>0 && !api.busy
                onClicked: {
                    confirmDialog.open();
                }
            }

            ToolSeparator {

            }

            ToolButton {
                text: qsTr("Clear")
                enabled: orderCart.count>0 && !api.busy
                onClicked: {
                    confirmClearDialog.open();
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

    ColumnLayout {
        id: mainContainer
        anchors.fill: parent
        anchors.margins: 4

        ListView {
            id: orderCart
            enabled: !searchActive
            clip: true
            Layout.fillWidth: true
            Layout.fillHeight: true

            ScrollIndicator.vertical: ScrollIndicator { }

            delegate: Component {
                ProductItemDelegate {
                    width: parent.width
                    height: childrenRect.height
                    showImage: false
                    compact: true
                    onClicked: {
                        openProductAtIndex(index)
                    }

                    onClickedImage: {
                        //openProductAtIndex(index)
                    }

                    onPressandhold: {
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
                            onClicked: {
                                orderCart.model.remove(index);
                            }
                        }
                    }

                    function openProductAtIndex(index) {
                        var p=orderCart.model.get(index);
                        orderCart.currentIndex=index;
                        rootStack.push(productView, { "product": p })
                    }

                    function openProductImageAtIndex(index) {
                        var p=orderCart.model.get(index);
                        orderCart.currentIndex=index;
                        rootStack.push(imageDisplayPageComponent, { image: p.thumbnail })
                    }
                }
            }
        }

        Label {
            visible: orderCart.model.count===0
            text: qsTr("Cart is empty")
            wrapMode: Text.Wrap
            font.pixelSize: 32
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
