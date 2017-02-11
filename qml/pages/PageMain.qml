import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

import "../delegates"

Page {
    id: pageMain
    property alias columnLayout1: columnLayout1
    property alias newsModel: listLatestNews.model
    property alias latestModel: listLatestProducts.model

    signal productClicked(string sku);

    title: appName

    Rectangle {
        color: "#e8e8e8"
        anchors.fill: parent
        Image {
            fillMode: Image.PreserveAspectCrop
            anchors.fill: parent
            opacity: 0.4
            source: "qrc:/images/bg/bg.jpg"
        }
    }

    ColumnLayout {
        id: columnLayout1
        anchors.fill: parent

        Image {
            id: image1
            fillMode: Image.PreserveAspectFit
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            opacity: 0.9
            source: "/images/logo.png"
            //Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.margins: 16
        }

        TabBar {
            id: bar
            opacity: 0.9
            Layout.fillWidth: true
            TabButton {
                text: qsTr("News")
            }

            TabButton {
                text: qsTr("Latest")
            }

        }

        SwipeView {
            id: mainSwipeView
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: bar.currentIndex
            clip: true
            onCurrentIndexChanged: {
                bar.currentIndex=currentIndex
            }

            ListView {
                id: listLatestNews
                clip: true
                delegate: NewsItemDelegate {

                }
                ScrollIndicator.vertical: ScrollIndicator { }
            }

            ListView {
                id: listLatestProducts
                enabled: root.isLogged
                visible: root.isLogged
                delegate: LatestItemDelegate {
                    onProductClicked: pageMain.productClicked(sku);
                }

                ScrollIndicator.vertical: ScrollIndicator { }
            }

        }
    }

    BusyIndicator {
        id: busyIndicator
        visible: running
        anchors.centerIn: parent
        running: api.busy
    }

}
