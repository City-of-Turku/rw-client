import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.1

ColumnLayout {
    id: c
    Layout.fillWidth: true

    property alias label: label.text
    property alias value: spinBox.value
    property alias from: spinBox.from
    property alias to: spinBox.to

    property string suffix: ""

    property string zeroSuffix: ""

    Label {
        id: label
        text: "" + spinBox.value===0 ? zeroSuffix : ""
        Layout.alignment: Layout.Center
    }
    SpinBox {
        id: spinBox
        from: 1
        to: 1
        Layout.fillWidth: true
        editable: true
        //textFromValue: function(value, locale) { return value+c.suffix; }
    }
}
