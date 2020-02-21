import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3

RowLayout {
    Layout.fillHeight: false
    Layout.alignment: Qt.AlignTop
    Layout.margins: 4
    spacing: 8

    property alias model: productColor.model
    property string colorID;
    property alias colorIndex: productColor.currentIndex

    function setColor(cid) {        
        for (var i=0;i<model.count;i++) {
            var tmp=model.get(i);
            if (tmp.cid===cid) {
                colorID=tmp.cid;
                productColor.currentIndex=i;
                return i;
            }
        }
        return -1;
    }

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
            onPressAndHold: productColor.currentIndex=0
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
        Text {
            visible: productColor.currentIndex==0
            anchors.centerIn: parent
            color: "#d0d0d0"
            text: qsTr("Pick a color")
        }
    }
}
