import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.1
import "../components"

Rectangle {
    id: wrapper
    //width: parent.width
    //height: r.height+16
    color: ListView.isCurrentItem ? "#f0f0f0" : "#ffffff"

    signal clicked(variant index)
    signal clickedImage(variant index)
    signal pressandhold(variant index)

    property int imageSize: width-8 // 4px margins
    property bool compact: false

    property bool showImage: true

    Item {
        id: r
        //spacing: 4
        width: parent.width
        height: showImage ? imageItem.height : bgrect.height
        Rectangle {
            id: imageItem
            visible: showImage
            color: "#f0f0f0"
            width: imageSize
            height: imageSize
            Layout.minimumHeight: imageSize
            Layout.minimumWidth: imageSize
            Layout.maximumWidth: imageSize
            Layout.maximumHeight: imageSize
            anchors.horizontalCenter: parent.horizontalCenter
            Image {
                id: i
                asynchronous: true
                sourceSize.width: 512
                anchors.fill: parent
                smooth: false
                cache: true
                anchors.margins: 4
                source: (showImage && thumbnail!=='') ? api.getImageUrl(thumbnail) : ''
                opacity: status==Image.Ready ? 1 : 0
                Behavior on opacity { OpacityAnimator { duration: 300; } }                
            }
            PurposeBadge {
                id: purposeBadge
                anchors.top: i.top
                anchors.left: i.left
                anchors.margins: 4
                size: i.width/4
                purpose: model.purpose;
            }

            ProgressBar {
                width: i.width/2
                anchors.centerIn: i
                visible: i.status==Image.Loading
                value: i.progress
            }

            MouseArea {
                anchors.fill: imageItem
                onClicked: {
                    console.debug("ImageCL"+index);
                    wrapper.clickedImage(index)
                }
                onPressAndHold: {
                    console.debug("ImagePAH: "+index)
                    wrapper.pressandhold(index)
                }
            }
        }

        Rectangle {
            id: bgrect
            color: "white"
            opacity: 0.8
            anchors.bottom: r.bottom
            width: r.width
            height: ic.height+16
        }

        Column {
            id: ic
            spacing: 2
            width: r.width-32
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.margins: 8
            //leftPadding: 4
            //rightPadding: 4
            anchors.bottom: r.bottom

            Text {
                //Layout.alignment: Qt.AlignTop
                width: parent.width
                text: productTitle
                font.pixelSize: 18
                //wrapMode: Text.Wrap
                //maximumLineCount: 2
                elide: Text.ElideRight                
            }
            Text {
                text: barcode
                font.pixelSize: 14
                color: "#181818"
                maximumLineCount: 1
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: 12
            }            
            Text {
                visible: stock>1 && !compact
                font.pixelSize: 12
                minimumPixelSize: 10
                fontSizeMode: Text.HorizontalFit
                color: "#181818"
                text: qsTr("Stock: ")+stock
            }
        }

        MouseArea {
            anchors.fill: ic
            onClicked: {
                console.debug("CL"+index);
                wrapper.clicked(index)
            }
            onPressAndHold: {
                console.debug("PAH: "+index)
                wrapper.pressandhold(index)
            }
        }
    }
}

