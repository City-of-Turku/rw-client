import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3
import QtMultimedia 5.12
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
        switch (event.key) {
        case Qt.Key_Back:
            event.accepted = true
            rootStack.pop();
            break;
        case Qt.Key_Camera:
        case Qt.Key_Space:
            event.accepted = true
            camera.captureImage();            
            break;
        case Qt.Key_CameraFocus:
            event.accepted = true
            camera.focusCamera();
            break;
        case Qt.Key_PageDown:
            event.accepted = true
            camera.zoomIn()
            break;
        case Qt.Key_PageUp:
            event.accepted = true
            camera.zoomOut()
            break;
        }
    }

    Component.onCompleted: {
        camera.forceActiveFocus();
    }

    header: ToolbarBasic {
        id: toolbar
        enableBackPop: true
        enableMenuButton: true
        visibleMenuButton: true
        onMenuButton: cameraMenu.open();
    }

    Menu {
        id: cameraMenu
        x: toolbar.width - width
        transformOrigin: Menu.TopRight
        modal: true
        MenuItem {
            text: "Switch camera"
            enabled: camera.multipleCameras
            onTriggered: camera.selectCamera();
        }
    }

    footer: ToolBar {
        RowLayout {
            anchors.fill: parent

            ToolButton {                
                Layout.alignment: Qt.AlignLeft
                onClicked: camera.flash=!camera.flash                
                icon.source: "qrc:/images/icon_flash.png"
            }

            ToolButton {
                Layout.alignment: Qt.AlignCenter                
                visible: imageCapture && !scanOnly
                enabled: camera.captureEnabled
                onClicked: {
                    camera.captureImage();
                }
                highlighted: true
                icon.source: "qrc:/images/icon_capture.png"
            }       

            ToolButton {                
                Layout.alignment: Qt.AlignRight
                onClicked: {
                    camera.focusCamera();
                }
                icon.source: "qrc:/images/icon_focus.png"
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
        onScanFatalFailure: {
            messagePopup.show("Fatal scanner error", error)
        }
    }

    RoundButton {
        id: flashIcon
        icon.source: "qrc:/images/icon_flash.png"
        visible: camera.flash
        opacity: 0.9
        anchors.top: camera.top
        anchors.right: camera.right
        onClicked: {
            camera.flash=false;
        }
    }

    MessagePopup {
        id: messagePopup
    }

    function startCamera() {
        camera.startCamera();
    }

    function stopCamera() {
        camera.stopCamera();
    }
}
