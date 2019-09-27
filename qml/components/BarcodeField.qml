import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3

TextField {
    id: barcodeText
    placeholderText: qsTr("Type or scan barcode")
    Layout.fillWidth: true
    selectByMouse: true
    leftPadding: 4
    rightPadding: 4
    inputMethodHints: Qt.ImhUppercaseOnly | Qt.ImhNoPredictiveText // | Qt.ImhPreferNumbers
    //inputMask: ">AAA999999999"
    validator: RegExpValidator { regExp: /[A-Z]{3}[0-9]{6,9}/ }

    property bool isOptional : false;

    background: Rectangle {
        color: "transparent"
        border.color: barcodeText.acceptableInput ? "green" : (isOptional ? "yellow" :  "red")
    }
    onPressAndHold: {
        clear()
    }
}
