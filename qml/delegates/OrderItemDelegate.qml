import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import net.ekotuki 1.0
import "../components"

Rectangle {
    id: wrapper
    color: ListView.isCurrentItem ? "#00aeef" : (index % 2) ? "#ffffff" : "#f0f0f0"

    signal clicked(variant index)
    signal pressandhold(variant index)

    height: c.height+8
    width: ListView.view.width

    RowLayout {
        id: c
        spacing: 8
        anchors.centerIn: parent
        width: parent.width
        ColumnLayout {
            id: cl
            spacing: 4
            Layout.fillWidth: true
            Text {
                text: model.id
                font.pixelSize: 18
                font.bold: true
            }
            Text {
                text: created.toLocaleDateString()
                font.pixelSize: 14
            }
        }
        ColumnLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 4

            Badge {
                text: api.getOrderStatusString(status)
            }
            Badge {
                text: count
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            wrapper.clicked(index)
        }
        onPressAndHold: {
            wrapper.pressandhold(index)
        }
    }
}

