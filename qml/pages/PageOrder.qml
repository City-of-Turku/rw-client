/**
 * Order page
 *
 * Displays a list of products to order with barcode input
 *
 */
import QtQuick 2.7
import QtQml 2.2
import QtQuick.Controls 2.0
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1

import net.ekotuki 1.0

import "../delegates"
import "../components"

Page {
    id: orderPage
    title: qsTr("Order")

    objectName: "order"

    property string searchString;


    property bool searchActive: false;
    property alias model: searchResults.model

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
        model.appendProduct(searchString);
        barcodeField.clear();
        searchResults.forceActiveFocus();
    }

    function orderCreated() {
        model.clear();
        rootStack.pop()
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

        onRejected: {

        }
    }

    footer: ToolBar {
        RowLayout {
            ToolButton {
                text: qsTr("Scan barcode")                
                enabled: !searchActive && searchString==''
                onClicked: {
                    rootStack.push(cameraScanner);
                }
            }
            ToolButton {
                text: qsTr("Send order")
                enabled: searchResults.count>0
                onClicked: {
                    confirmDialog.open();
                }
            }
        }
    }

    Component {
        id: cameraScanner
        CameraPage {
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

    Connections {
        target: api

        onSearchCompleted: {
            console.debug("SEARCH DONE")
            setSearchActive(false);
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

        Label {
            anchors.centerIn: parent
            visible: searchResults.model.count===0
            text: qsTr("Cart is empty")
            wrapMode: Text.Wrap
            font.pixelSize: 32
        }

        ListView {
            id: searchResults
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
                        openProductAtIndex(index)
                    }

                    onPressandhold: {
                        openProductImageAtIndex(index)
                    }

                    function openProductAtIndex(index) {
                        var p=searchPage.model.get(index);
                        searchResults.currentIndex=index;
                        rootStack.push(productView, { "product": p })
                    }

                    function openProductImageAtIndex(index) {
                        var p=searchPage.model.get(index);
                        searchResults.currentIndex=index;
                        rootStack.push(imageDisplayPageComponent, { image: p.thumbnail })
                    }
                }
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
