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

    property Order order;

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

    footer: ToolBar {
        RowLayout {

        }
    }

    Connections {
        target: api
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
            label: "ID:"
            value: order.orderID
        }
        DetailItem {
            label: "Status:"
            value: order.status
        }
        DetailItem {
            label: "Created:"
            value: order.created
        }

        ListView {
            id: orderProducts
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
