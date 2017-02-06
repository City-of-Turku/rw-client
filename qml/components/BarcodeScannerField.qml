import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.1

RowLayout {
    id: barcodeField
    Layout.fillWidth: true
    Layout.fillHeight: false
    Layout.alignment: Qt.AlignTop
    Layout.margins: 8
    spacing: 8

    property string barcode: ""

    BarcodeField {
        id: barcodeText
        enabled: !hasProduct
        onAccepted: {
            validateBarcode(text);
        }
        onAcceptableInputChanged: {
            if (acceptableInput)
                validateBarcode(text);
        }
    }
    Button {
        text: qsTr("Scan")
        enabled: !barcodeText.acceptableInput
        onClicked: {
            rootStack.push(cameraScanner);
        }
    }
}
