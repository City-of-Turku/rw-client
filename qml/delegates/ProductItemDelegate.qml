import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3
import "../components"

Rectangle {
    id: wrapper
    //width: parent.width
    //height: r.height+16
    color: ListView.isCurrentItem ? "#f0f0f0" : "#ffffff"

    signal clicked(variant index)
    signal clickedImage(variant index)
    signal pressandhold(variant index)
    signal pressandholdDetails(variant index)
    signal released(variant index)

    property int imageSize: width-8 // 4px margins
    property bool compact: false

    property bool showImage: true

    Item {
        id: r
        //spacing: 4
        width: parent.width
        height: showImage ? imageItem.height : bgrect.height

        function myHeight() {
            return showImage ? imageItem.height : bgrect.height
        }

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
                fillMode: Image.PreserveAspectCrop
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
                purpose: model.purpose!=undefined ? model.purpose : 0;
            }
            ProgressBar {
                width: i.width/2
                anchors.centerIn: i
                visible: i.status==Image.Loading
                value: i.progress
            }
            Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: ima.pressed ? 0.4 : 0
            }
            MouseArea {
                id: ima
                anchors.fill: imageItem
                onClicked: {
                    console.debug("ImageCL"+index);
                    wrapper.clickedImage(index)
                }
                onPressAndHold: {
                    console.debug("ImagePAH: "+index)
                    wrapper.pressandhold(index)
                }
                onReleased: {
                    wrapper.released(index);
                }
            }
        }

        Rectangle {
            id: bgrect
            color: "white"
            opacity: 0.7
            anchors.bottom: r.bottom
            width: r.width
            height: ic.height+16
        }

        ColumnLayout {
            id: ic
            spacing: 2
            width: r.width-32
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.margins: 8
            anchors.bottom: r.bottom

            RowLayout {
                id: ns
                Text {
                    Layout.fillWidth: true
                    text: productTitle
                    font.pixelSize: 18
                    //wrapMode: Text.Wrap
                    //maximumLineCount: 2
                    elide: Text.ElideRight
                }
                Badge {
                    Layout.fillWidth: false
                    text: stock
                }
                BadgePrice {
                    Layout.fillWidth: false
                    amount: price
                    visible: price>0
                }
            }            
            Text {
                text: barcode
                font.pixelSize: 12
                color: "#181818"
                maximumLineCount: 1
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: 12
            }
        }

        MouseArea {
            id: ma
            anchors.fill: ic
            onClicked: wrapper.clicked(index)
            onPressAndHold: wrapper.pressandholdDetails(index)
            onReleased: wrapper.released(index)
        }
    }
}

