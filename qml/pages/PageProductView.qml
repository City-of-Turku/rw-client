import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3
import net.ekotuki 1.0

import "../components"

Page {
    id: productView
    title: product ? product.title : ''

    property Product product: null;
    property bool landscape: height<width

    property bool toolsEnabled: true
    property bool editEnabled: api.hasRole("products")
    property bool cartDisabled: false
    property bool cartEnabled: api.hasRole("cart") && !cartDisabled

    Keys.onReleased: {
        if (event.key === Qt.Key_Back) {
            console.log("*** Back button")
            event.accepted = true;
            rootStack.pop();
        }
    }

    header: ToolbarBasic {
        enableMenuButton: false
    }

    footer: ToolBar {
        visible: toolsEnabled
        RowLayout {
            ToolButton {
                text: qsTr("Edit")
                visible: enabled
                enabled: editEnabled
                onClicked: {
                    rootStack.push(productEdit, { "product": product, "locationsModel": api.getLocationsModel() })
                }
            }
            ToolButton {
                text: qsTr("Add to cart")
                icon.source: "qrc:/images/icon_cart.png"
                visible: cartEnabled
                enabled: cartEnabled && product.stock>0
                onClicked: {
                    if (!api.addToCart(product.barcode, 1)) {
                        messagePopup.show(qsTr("Cart error"), qsTr("Failed to add product to cart"))
                    } else {
                        editEnabled=false;
                    }
                }
            }
        }
    }

    Component {
        id: productEdit
        PageProductEdit {
            id: modifyPage
            product: productView.product
            keepImages: true
            addMoreEnabled: false            

            onRequestProductSave: {
                console.debug("*** Product update save")
                product=modifyPage.fillProduct(product);

                console.debug(product.getAttributes())

                console.debug("*** Updating product to API")
                var rs=api.updateProduct(product);
                if (rs)
                    modifyPage.saveInProgress();
                else
                    modifyPage.saveFailed();
            }

            Connections {
                target: api
                onProductSaved: {
                    if (modifyPage.confirmProductSave(true, null, "")) {

                    }
                }
                onProductFail: {
                    modifyPage.confirmProductSave(false, null, msg);
                }
            }

            Component.onCompleted: {
                api.getLocationsModel().clearFilter();
            }
        }
    }

    Component {
        id: imageDisplayPageComponent
        PageImageDisplay {

        }
    }

    MessagePopup {
        id: purposeMessage
    }

    ColumnLayout {
        id: main
        anchors.fill: parent
        anchors.topMargin: 8
        spacing: 8

        RowLayout {
            id: headerRow
            Layout.minimumWidth: parent.width
            spacing: 8

            PurposeBadge {
                Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                id: purposeBadge
                //size: parent.width/8
                Layout.maximumWidth: parent.width/8
                Layout.maximumHeight: parent.width/8
                Layout.minimumHeight: titleHeader.height
                Layout.minimumWidth: titleHeader.height
                purpose: product ? product.getAttribute("purpose") : 0;
                onClicked: {
                    switch (purpose) {
                    case 1:
                        purposeMessage.show("Kiertoon", "Kiertoon menevä ... ???")
                        break;
                    case 2:
                        purposeMessage.show("Käyttöön", "Käyttöön menevä ... ???")
                        break;
                    case 3:
                        purposeMessage.show("Lainaan", "Lainaan menevän tuotteen voi lainata määräajaksi jonka jälkeen tuote palautetaan omistajalle.")
                        break;
                    }
                }
            }

            ColumnLayout {
                id: titleHeader
                Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 4
                spacing: 4
                Text {
                    text: product.title
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font.pixelSize: 20
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                Text {
                    text: product.barcode
                    Layout.fillWidth: true
                    font.pixelSize: 14
                }
            }
        }

        Flickable {
            id: f
            clip: true
            contentHeight: c.height
            //contentWidth: c.width
            //width: productView.width
            flickableDirection: Flickable.VerticalFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            ScrollIndicator.vertical: ScrollIndicator { }
            ScrollIndicator.horizontal: ScrollIndicator { }

            ColumnLayout {
                id: c
                Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                width: parent.width
                spacing: 4

                RowLayout {
                    id: imageRow
                    Layout.minimumHeight: productView.height/3
                    Layout.maximumHeight: productView.height/1.5
                    Layout.fillHeight: true                    

                    ListView {
                        id: productImagesList
                        clip: true
                        Layout.fillWidth: true
                        Layout.minimumHeight: productView.height/3
                        Layout.maximumHeight: productView.height/1.4
                        orientation: ListView.Horizontal
                        model: productImagesModel
                        delegate: imageDelegate
                        snapMode: ListView.SnapOneItem
                        highlightRangeMode: ListView.StrictlyEnforceRange
                        ScrollIndicator.horizontal: ScrollIndicator { }
                        PageIndicator {
                            count: productImagesList.model.count
                            currentIndex: productImagesList.currentIndex
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: productImagesList.bottom
                        }
                    }

                    Component {
                        id: imageDelegate
                        Item {
                            width: productImagesList.width
                            height: parent.height

                            Image {
                                id: thumbnail
                                asynchronous: true
                                sourceSize.width: 1024
                                anchors.fill: parent
                                //fillMode: Image.PreserveAspectCrop
                                fillMode: Image.PreserveAspectFit
                                source: api.getImageUrl(productImage)
                                opacity: status==Image.Ready ? 1 : 0;
                                Behavior on opacity { OpacityAnimator { duration: 400; } }
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: thumbnail.status==Image.Ready
                                    onClicked: {
                                        rootStack.push(imageDisplayPageComponent, { image: thumbnail.source })
                                    }
                                    onPressAndHold: {

                                    }
                                }
                                onProgressChanged: console.debug("Loading... "+progress)
                            }
                            ProgressBar {
                                anchors.centerIn: parent
                                width: parent.width/2
                                value: thumbnail.progress
                                visible: thumbnail.status==Image.Loading
                            }
                        }
                    }
                }

                Frame {
                    visible: product.description!==''
                    Layout.fillWidth: true
                    Layout.margins: 8
                    ColumnLayout {
                        width: parent.width
                        Text {
                            Layout.fillWidth: true
                            id: productDescription
                            text: product.description
                            maximumLineCount: 3
                            anchors.margins: 16
                            font.pixelSize: 18
                            wrapMode: Text.WordWrap
                            elide: Text.ElideRight
                            textFormat: Text.PlainText                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    productDescription.maximumLineCount=(productDescription.maximumLineCount==3 ? undefined : 3);
                                }
                            }
                        }
                    }
                }

                Frame {
                    id: attributes
                    Layout.fillWidth: true
                    Layout.margins: 8
                    visible: product.hasAttributes();
                    ColumnLayout {
                        width: parent.width
                        DetailItem {
                            label: qsTr("Price")
                            visible: product.price>0
                            value: product.price.toFixed(2)+" €"
                        }
                        DetailItem {
                            label: qsTr("Added")
                            //visible: product.price>0
                            value: product.getCreated().toLocaleDateString();
                        }
                        DetailItem {
                            label: qsTr("Modified")
                            visible: product.getCreated()<product.getModified()
                            value: product.getModified().toLocaleDateString();
                        }
                        DetailItem {
                            label: qsTr("Stock")
                            visible: product.stock>0
                            value: product.stock
                        }
                        // Physical size display, in Width/Depth/Height order
                        DetailItem {
                            label: qsTr("Size (WxDxH)")
                            visible: product.hasAttribute("depth") && product.hasAttribute("width") && product.hasAttribute("height")
                            value: product.getAttribute("width")+"cm x " + product.getAttribute("depth")+"cm x " + product.getAttribute("height")+"cm"
                        }
                        DetailItem {
                            label: qsTr("Weight")
                            property int weight: product.hasAttribute("weight") ? product.getAttribute("weight") : 0;
                            visible: weight>0;
                            value: weight+" Kg"
                        }
                        DetailItem {
                            label: qsTr("Color");
                            visible: product.hasAttribute("color")
                            value: "" // getColorString(product.getAttribute("color"))
                            function getColorString(ca) {
                                console.debug(ca)
                                if (!ca)
                                    return 'N/A'
                                else
                                    return ca.join(); // XXX
                            }
                            Repeater {
                                id: colorRepeater
                                model: product.getAttribute("color")
                                delegate: Rectangle {
                                    width: 20
                                    height: 20
                                    color: colorRepeater.getColorCode(modelData)
                                }
                                function getColorCode(cid) {
                                    var c=api.getColorModel().getKey(cid);
                                    if (c)
                                        return c.code;
                                    return '';
                                }
                            }
                        }
                        DetailItem {
                            label: qsTr("EAN")
                            visible: product.hasAttribute("ean") && product.getAttribute("ean")!==''
                            value: product.getAttribute("ean")
                        }
                        DetailItem {
                            label: qsTr("ISBN")
                            visible: product.hasAttribute("isbn")
                            value: product.getAttribute("isbn")
                        }
                        DetailItem {
                            label: qsTr("Manufacturer")
                            visible: product.hasAttribute("manufacturer")
                            value: product.getAttribute("manufacturer")
                        }
                        DetailItem {
                            label: qsTr("Model")
                            visible: product.hasAttribute("model")
                            value: product.getAttribute("model")
                        }
                    }
                }
            }
        }
    }

    BusyIndicator {
        id: busyIndicator
        visible: running
        running: false
    }

    ListModel {
        id: productImagesModel
    }

    Component.onCompleted: {
        console.debug("*** Adding product image to model: "+product.images.length)
        for (var i=0;i<product.images.length;i++) {
            console.debug("Image: "+product.images[i]);
            productImagesModel.append({"productImage": product.images[i]});
        }
        f.forceActiveFocus();
    }
}
