import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.1

ComboBox {
    id: barcodeText
    Layout.fillWidth: true
    editable: true
    inputMethodHints: Qt.ImhUppercaseOnly // | Qt.ImhPreferNumbers
    //inputMask: ">AAA999999"
    validator: RegExpValidator {
        regExp: /[A-Z]{3}[0-9]{6}/
    }
    background: Rectangle {
        color: "transparent"
        border.color: barcodeText.acceptableInput ? "green" : "red"
    }
}
