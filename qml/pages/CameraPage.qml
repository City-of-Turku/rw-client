import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3
import QtMultimedia 5.5
import net.ekotuki 1.0

import "../components"

Page {
    id: cameraPage
    focus: true;

    objectName: "cameraPage"

    property alias scanOnly: camera.scanOnly
    property alias imageCapture: camera.imageCapture
    property alias oneShot: camera.oneShot
    property alias autoStart: camera.autoStart

    property alias barcode: camera.barcode

    signal barcodeFound(string data);
    signal imageCaptured(string path)

    // Emit after oneshot decoding
    signal decodeDone()

    Keys.onReleased: {
        console.debug("*** Key released! "+event.key)
        if (event.key == Qt.Key_Back) {
                console.log("*** Back button")
                event.accepted = true
                rootStack.pop();
        }
    }

    Component.onCompleted: {
        camera.forceActiveFocus();
    }

    footer: ToolBar {
        RowLayout {
            anchors.fill: parent
            ToolButton {
                Layout.alignment: Qt.AlignCenter
                text: "Capture"
                visible: imageCapture
                enabled: camera.captureEnabled
                contentItem: ItemIcon {
                    source: "qrc:/images/icon_camera.png"
                }
                onClicked: {
                    camera.captureImage();
                }
            }
            ToolButton {
                text: "Flash"
                onClicked: camera.flash=!camera.flash
            }

            ToolButton {
                text: "Focus"
                onClicked: {
                    camera.focusCamera();
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    CameraItem {
        id: camera
        anchors.fill: parent

        onBarcodeFound: {
            cameraPage.barcodeFound(data)
        }

        onImageCaptured: {
            cameraPage.imageCaptured(path)
        }

        onDecodeDone: {
            cameraPage.decodeDone();
        }
    }

    Image {
        id: flashIcon
        source: "qrc:/images/icon_flash.png"
        visible: camera.flash
        anchors.top: camera.top
        anchors.right: camera.right
    }

    function startCamera() {
        camera.startCamera();
    }

    function stopCamera() {
        camera.stopCamera();
    }
}
