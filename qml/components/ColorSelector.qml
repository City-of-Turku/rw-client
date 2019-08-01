import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3

RowLayout {
    Layout.fillHeight: false
    Layout.alignment: Qt.AlignTop
    spacing: 8

    property alias model: productColor.model
    property string colorID;
    property alias colorIndex: productColor.currentIndex

    Rectangle {
        id: colorIndicator
        height: productColor.height
        width: height
        Behavior on color {
            ColorAnimation {
                easing.type: Easing.InOutQuad
                duration: 200
            }
        }
        border.color: "black"
        MouseArea {
            anchors.fill: parent
            onClicked: productColor.popup.open();
        }
    }

    ComboBox {
        id: productColor
        Layout.fillWidth: true
        textRole: "color"
        onCurrentIndexChanged: {
            var tmp=model.get(currentIndex);
            colorIndicator.color=tmp.code;
            colorID=tmp.cid;
        }
    }
}
