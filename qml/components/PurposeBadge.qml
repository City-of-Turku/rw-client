import QtQuick 2.12

Image {
    id: purposeBadge
    sourceSize.width: 128
    width: size
    height: size
    smooth: true
    cache: true
    visible: purpose>0
    source: getPurposeBadge(purpose)
    fillMode: Image.PreserveAspectFit

    signal clicked();

    property int size;
    property int purpose: 0

    function getPurposeBadge(pid) {        
        switch (pid) {
        case 0:
            return ""
        case 1:
            return "/images/badges/kiertoon_512.png"
        case 2:
            return "/images/badges/kayttoon_512.png"
        case 3:
            return "/images/badges/lainaan_512.png"
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            purposeBadge.clicked();
        }
    }

}
