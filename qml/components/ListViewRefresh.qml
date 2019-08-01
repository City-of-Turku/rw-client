import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3

ListView {
    id: lvr
    clip: true
    //spacing: 8
    //Layout.fillWidth: true;
    //Layout.fillHeight: true;
    boundsMovement: Flickable.StopAtBounds

    property bool triggerRefresh: false
    signal refreshTriggered();

    onTriggerRefreshChanged: console.debug("Refresh trigger is armed: "+triggerRefresh)

    onVerticalOvershootChanged: {
        //console.debug(verticalOvershoot)
        if (verticalOvershoot < -(r.height*2.3))
            triggerRefresh=true;
        else
            triggerRefresh=false;
    }

    onDraggingVerticallyChanged: {
        if (!draggingVertically && triggerRefresh) {
            console.debug("REFRESH TRIGGERED!")
            refreshTriggered();
            triggerRefresh=false;
        }
    }

    Rectangle {
        id: r
        y: Math.min(Math.abs(parent.verticalOvershoot)/1.2, parent.height/4)-height
        anchors.horizontalCenter: parent.horizontalCenter
        width: 48
        height: 48
        radius: 24
        color: "lightgrey"
        border.color: "grey"
        border.width: 2
        visible: parent.verticalOvershoot<0 && parent.draggingVertically               

        Image {
            id: i
            anchors.fill: parent
            anchors.margins: 8
            fillMode: Image.PreserveAspectFit
            source: "qrc:/images/icon_refresh.png"
            rotation: Math.min(Math.abs(lvr.verticalOvershoot)*1.5, 360)
        }
    }
}
