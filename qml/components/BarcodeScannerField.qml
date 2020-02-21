import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3

import "../pages"

RowLayout {
    id: barcodeScannerField
    Layout.fillWidth: true
    Layout.fillHeight: false
    Layout.alignment: Qt.AlignTop
    Layout.margins: 8
    spacing: 8

    signal validateBarcode(string barcode)
    property bool scannerEnabled: true

    property alias isOptional: barcodeText.isOptional

    property alias text: barcodeText.text
    property alias placeholderText: barcodeText.placeholderText
    property alias validator: barcodeText.validator
    property alias acceptableInput: barcodeText.acceptableInput
    property alias inputMethodHints: barcodeText.inputMethodHints

    BarcodeField {
        id: barcodeText
        enabled: !hasProduct
        onAccepted: {
            console.debug("BarcodeAccepted")
            validateBarcode(text);
        }
        onAcceptableInputChanged: {
            console.debug("BarcodeAcceptableInput: "+acceptableInput)
            if (acceptableInput)
                validateBarcode(text);
        }
        onFocusChanged: {
            console.debug("BarcodeFocus: "+focus)
        }
    }

    RoundButton {
        text: qsTr("Scan")
        enabled: !barcodeText.acceptableInput && scannerEnabled
        visible: scannerEnabled
        icon.source: "qrc:/images/icon_camera.png"
        onClicked: {
            rootStack.push(cameraScanner);
        }
    }

    RoundButton {
        text: qsTr("Clear")
        visible: barcodeText.acceptableInput && scannerEnabled
        icon.source: "qrc:/images/icon_delete.png"
        onClicked: {
            barcodeText.clear()
        }
    }

    Component {
        id: cameraScanner
        PageCamera {
            id: scanCamera
            title: qsTr("Scan barcode")
            oneShot: true
            Component.onCompleted: {
                scanCamera.startCamera();
            }
            onBarcodeFound: {
                barcodeText.text=barcode;
            }
            onDecodeDone: {
                rootStack.pop();
            }
        }
    }
}
