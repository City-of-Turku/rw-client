import QtQuick 2.10
import QtQuick.Window 2.2
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3
import net.ekotuki 1.0

import "../components"

Page {
    id: productView
    title: product ? product.title : ''

    property Product product: null;
    property bool landscape: height<width

    property bool toolsEnabled: true
    property bool editEnabled: false
    property bool cartDisabled: false
    property bool cartEnabled: api.hasRole("order") && !cartDisabled

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
                    rootStack.push(productEdit)
                }
            }
            ToolButton {
                text: qsTr("Add to cart")
                icon.source: "qrc:/images/icon_cart.png"
                visible: enabled
                enabled: cartEnabled
                onClicked: {
                    if (!api.addToCart(product.barcode, 1)) {
                        messagePopup.show(qsTr("Cart error"), qsTr("Failed to add product to cart"))
                    } else {

                    }
                }
            }
        }
    }

    Component {
        id: productEdit
        PageProductEdit {
            product: productView.product
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
            width: productView.width
            flickableDirection: Flickable.VerticalFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            ScrollIndicator.vertical: ScrollIndicator { }
            ScrollIndicator.horizontal: ScrollIndicator { }

            ColumnLayout {
                id: c
                Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                width: parent.width

                RowLayout {
                    id: imageRow
                    Layout.minimumHeight: productView.height/2
                    Layout.maximumHeight: productView.height/1.5
                    width: parent.width
                    Layout.fillHeight: true

                    ListView {
                        id: productImagesList
                        clip: true
                        Layout.fillWidth: true
                        Layout.minimumHeight: productView.height/2
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
                                sourceSize.width: 512
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

                Pane {
                    //title: "Product description"
                    visible: product.description!==''
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Text {
                        id: productDescription
                        Layout.fillWidth: true
                        text: product.description
                        maximumLineCount: 10
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {

                            }
                        }
                    }
                }

                Pane {
                    id: attributes
                    // title: qsTr("Product attributes")
                    visible: product.hasAttributes();
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    ColumnLayout {
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true
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
                            label: qsTr("Stock")
                            visible: product.stock!=1
                            value: product.stock
                        }
                        DetailItem {
                            label: qsTr("Size (WxHxD)")
                            visible: product.hasAttribute("depth") && product.hasAttribute("width") && product.hasAttribute("height")
                            value: product.getAttribute("width")+"cm x " + product.getAttribute("height")+"cm x " + product.getAttribute("depth")+"cm"
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
                            value: product.getAttribute("color") // XXX
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
