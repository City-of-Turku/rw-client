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

    onProductChanged: {        
        if (product) {
            productAttributeModel.refresh();
            productImagesModel.refresh();
        } else {
            productAttributeModel.clear();
            productImagesModel.clear();
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

    ListModel {
        id: productAttributeModel
        dynamicRoles: true

        function refresh() {
            productAttributeModel.clear();

            productAttributeModel.append({"label": qsTr("Added"), "value": product.getCreated().toLocaleDateString() })
            productAttributeModel.append({"label": qsTr("Modified"), "value": product.getModified().toLocaleDateString() })

            if (product.price>0)
                productAttributeModel.append({"label": qsTr("Price"), "value": product.price.toFixed(2)+" €" })

            if (product.stock>0)
                productAttributeModel.append({"label": qsTr("Stock"), "value": product.stock })

            if (product.hasAttribute("width"))
                productAttributeModel.append({"label": qsTr("Size (WxDxH)"), "value": product.getAttribute("width")+"cm x " + product.getAttribute("depth")+"cm x " + product.getAttribute("height")+"cm" })

            if (product.hasAttribute("weight"))
                productAttributeModel.append({"label": qsTr("Weight"), "value": product.getAttribute("weight")+ "Kg" })

            if (product.hasAttribute("ean"))
                productAttributeModel.append({"label": qsTr("EAN"), "value": product.getAttribute("ean", "") })
            if (product.hasAttribute("isbn"))
                productAttributeModel.append({"label": qsTr("ISBN"), "value": product.getAttribute("isbn", "") })
            if (product.hasAttribute("manufacturer"))
                productAttributeModel.append({"label": qsTr("Manufacturer"), "value": product.getAttribute("manufacturer", "")  })
            if (product.hasAttribute("model"))
                productAttributeModel.append({"label": qsTr("Model"), "value": product.getAttribute("model", "") })
            if (product.hasAttribute("color"))
                productAttributeModel.append({"label": qsTr("Color"), "value": getColorString(product.getAttribute("color")) })

        }

        function getColorString(ca) {
            if (!ca)
                return 'N/A'
            else
                return ca.join(); // XXX
        }
    }

    Component {
        id: productEdit
        PageProductEdit {
            id: modifyPage
            keepImages: true
            addMoreEnabled: false

            onRequestProductSave: {
                product.clearAttributes();
                product=modifyPage.fillProduct(product);

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
                        // refresh our current product with the saved one
                        productView.product=product
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
                                source: api.getImageUrl(productImage.image)
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
                        Repeater {
                            model: productAttributeModel
                            delegate: DetailItem {
                                label: model.label
                                value: model.value
                            }
                        }

                        DetailItem {
                            label: qsTr("Color");
                            visible: product && product.hasAttribute("color")
                            value: ""
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
                                    console.debug(c.code)
                                    console.debug(c.color)
                                    console.debug(c.cid)
                                    if (c)
                                        return c.code;
                                    return '';
                                }
                            }
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

        function refresh() {
            productImagesModel.clear();
            for (var i=0;i<product.images.length;i++) {
                productImagesModel.append({"productImage": product.images[i]});
            }
        }
    }

    Component.onCompleted: {
        productImagesModel.refresh();
        f.forceActiveFocus();
    }
}
