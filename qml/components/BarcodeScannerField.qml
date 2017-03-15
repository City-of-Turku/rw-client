import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.1

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

    property alias text: barcodeText.text
    property alias placeholderText: barcodeText.placeholderText

    property alias validator: barcodeText.validator

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

    Button {
        text: qsTr("Scan")
        enabled: !barcodeText.acceptableInput && !scannerEnabled
        contentItem: ItemIcon {
            source: "qrc:/images/icon_camera.png"
        }
        onClicked: {
            rootStack.push(cameraScanner);
        }
    }

    Component {
        id: cameraScanner
        CameraPage {
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
