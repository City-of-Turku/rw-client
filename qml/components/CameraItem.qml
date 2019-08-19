import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3
import QtMultimedia 5.12
import net.ekotuki 1.0

Item {
    id: cameraItem
    focus: true;

    property bool scanOnly: true;
    property bool imageCapture: false
    property bool oneShot: false;

    property bool cameraSelectionEnabled: true

    property bool autoStart: false

    property bool externalControls: true

    property string barcode;

    // Metadata
    property string metaSubject;
    property variant metaLatitude;
    property variant metaLongitude;

    // Flash, for simplicity we just use Off/Auto
    property bool flash: false

    signal barcodeFound(string data);
    signal imageCaptured(string path)

    // Emit after oneshot decoding
    signal decodeDone()

    signal scanFatalFailure(string error)

    property bool hasOpticalZoom: false

    Camera {
        id: camera
        deviceId: "/dev/video0"
        captureMode: scanOnly ? Camera.CaptureViewfinder : Camera.CaptureStillImage;
        onErrorStringChanged: console.debug("Error: "+errorString)
        onCameraStateChanged: {
            console.debug("Camera State: "+cameraState)
            switch (cameraState) {
            case Camera.ActiveState:
                console.debug("DigitalZoom: "+maximumDigitalZoom)
                console.debug("OpticalZoom: "+maximumOpticalZoom)
                if (maximumOpticalZoom>1.0)
                    hasOpticalZoom=true;
                break;
            }
        }
        onCameraStatusChanged: console.debug("Status: "+cameraStatus)

        onDigitalZoomChanged: console.debug(digitalZoom)

        focus {
            focusMode: Camera.FocusContinuous
            focusPointMode: Camera.FocusPointCenter
        }

        metaData.subject: metaSubject
        metaData.gpsLatitude: metaLatitude
        metaData.gpsLongitude: metaLongitude

        imageCapture {
            onImageCaptured: {
                console.debug("Image captured!")
                console.debug(camera.imageCapture.capturedImagePath)
                previewImage.source=preview;
            }
            onCaptureFailed: {
                console.debug("Capture failed")
            }
            onImageSaved: {
                console.debug("Image saved: "+path)
                cameraItem.imageCaptured(path)
            }
        }

        onError: {
            console.log("Camera reports error: "+errorString)
            console.log("Error code: "+errorCode)
        }

        flash.mode: cameraItem.flash ? Camera.FlashAuto : Camera.FlashOff

        Component.onCompleted: {
            console.debug("Camera is: "+deviceId)
            console.debug("Camera orientation is: "+orientation)            
        }
    }

    BarcodeScanner {
        id: scanner
        //enabledFormats: BarcodeScanner.BarCodeFormat_2D | BarcodeScanner.BarCodeFormat_1D
        enabledFormats: BarcodeScanner.BarCodeFormat_1D
        rotate: camera.orientation!=0 ? true : false;
        onTagFound: {
            console.debug("TAG: "+tag);
            cameraItem.barcode=tag;
            barcodeFound(tag)
        }
        onDecodingStarted: {

        }
        onDecodingFinished: {
            if (succeeded && cameraItem.oneShot) {
                camera.stop();
                decodeDone();
            }
        }

        onUnknownFrameFormat: {
            console.debug("Unknown video frame format: "+format)
            console.debug(width + " x "+height)
            scanFatalFailure("Fatal: Unknown video frame format: "+format)
            camera.stop();
        }
    }

    ColumnLayout {
        spacing: 8
        anchors.fill: parent

        VideoOutput {
            id: videoOutput
            source: camera
            autoOrientation: true
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter
            Layout.minimumWidth: 320
            Layout.minimumHeight: 320
            fillMode: Image.PreserveAspectFit

            filters: imageCapture ? [] : [ scanner ]

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    console.debug("*** Camera click")
                    if (scanOnly)
                        return;
                    captureImage();
                }
                onPressAndHold: {
                    console.debug("*** Camera press'n'hold")
                    if (camera.lockStatus==Camera.Unlocked)
                        camera.searchAndLock();
                    else
                        camera.unlock();
                }
            }

        }

        Text {
            id: barcodeText
            visible: scanOnly
            Layout.fillWidth: true
            color: "red"
            text: cameraItem.barcode
            font.pointSize: 22
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Image {
        id: previewImage
        fillMode: Image.PreserveAspectFit
        width: Math.max(parent.width/6, 192)
        height: Math.max(parent.height/6, 192)
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 16
        opacity: zoomed ? 1 : 0.75
        scale: zoomed ? 2 : 1
        transformOrigin: Item.TopLeft

        property bool zoomed: false

        onStatusChanged: {
            if (previewImage.status == Image.Ready) {
                visible=true;
                zoomed=false;
            }
        }

        MouseArea {
            id: previewMouse
            anchors.fill: parent
            onPressAndHold: {
                previewImage.visible=false;
            }
            onClicked: {
                previewImage.zoomed=!previewImage.zoomed
            }
        }
        Behavior on scale {
            ScaleAnimator {
                duration: 200
            }
        }
    }

    Slider {
        id: zoomDigitalSlider
        anchors.right: parent.right
        anchors.rightMargin: 32
        anchors.topMargin: parent.height/12
        anchors.bottomMargin: parent.height/12
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        visible: camera.maximumDigitalZoom>1
        from: 1
        value: 1
        to: camera.maximumDigitalZoom
        onValueChanged: camera.digitalZoom=value;
        orientation: Qt.Vertical
        ToolTip {
            parent: zoomDigitalSlider.handle
            visible: zoomDigitalSlider.pressed || zoomDigitalSlider.value>1.0
            text: zoomDigitalSlider.value.toFixed(1)
        }
    }


    BusyIndicator {
        anchors.centerIn: parent
        visible: running
        running: camera.lockStatus==Camera.Searching
    }

    Popup {
        id: cameraPopup
        modal: true
        x: parent.width/6
        y: parent.width/4
        width: parent.width/1.5
        height: parent.height/2

        ListView {
            id: cameraList
            anchors.fill: parent
            clip: true
            model: QtMultimedia.availableCameras
            delegate: Text {
                id: c
                color: cmlma.pressed ? "#101060" : "#000000"
                text: modelData.displayName
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                font.pixelSize: 22
                leftPadding: 4
                rightPadding: 4
                topPadding: 8
                bottomPadding: 8
                width: parent.width
                MouseArea {
                    id: cmlma
                    anchors.fill: parent
                    onClicked: {
                        camera.stop();
                        camera.deviceId=modelData.deviceId
                        console.debug(modelData.deviceId)
                        console.debug(modelData.displayName)
                        console.debug(modelData.position)
                        camera.start();
                        cameraPopup.close();
                    }
                }
            }
        }
    }

    property bool captureEnabled: camera.cameraStatus==Camera.ActiveStatus && !scanOnly
    property bool multipleCameras: cameraList.count>1

    RowLayout {
        Layout.fillWidth: true
        Layout.minimumHeight: 32

        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        visible: !externalControls

        Button
        {
            enabled: captureEnabled
            visible: !scanOnly
            Layout.fillHeight: true
            Layout.fillWidth: true
            text: "Capture"
            onClicked: captureImage();
        }

        Button {
            text: "Try again"
            Layout.fillHeight: true
            Layout.fillWidth: true
            visible: !oneShot && scanOnly
            enabled: camera.cameraStatus!=Camera.ActiveStatus
            onClicked: camera.start()
        }

        Button {
            text: "Cameras"
            visible: cameraSelectionEnabled && multipleCameras
            onClicked: {
                cameraPopup.open();
            }
        }

        Button {
            text: cameraItem.flash ? "Auto" : "Off"
            onClicked: {
                cameraItem.flash=!cameraItem.flash
            }
        }

        Button {
            text: getFocusTitle(camera.lockStatus)
            enabled: camera.cameraStatus==Camera.ActiveStatus && Camera.lockStatus!=Camera.Searching
            onClicked: {
                focusCamera();
            }
            Layout.fillHeight: true
            Layout.fillWidth: true

            function getFocusTitle(cls) {
                switch (cls) {
                case Camera.Unlocked:
                    return qsTr("Focus")
                case Camera.Searching:
                    return qsTr("Focusing")
                default:
                    return qsTr("Unlock")
                }
            }
        }
    }

    Component.onCompleted: {
        console.debug("Camera standby")
        if (autoStart)
            startCamera();
    }

    Component.onDestruction: {
        stopCamera();
    }

    function captureImage() {
        camera.imageCapture.capture();
    }

    function focusCamera() {
        if (camera.lockStatus==Camera.Unlocked)
            camera.searchAndLock();
        else
            camera.unlock();
    }

    function startCamera() {
        console.debug("Start camera")
        camera.start();
    }

    function stopCamera() {
        console.debug("Stop camera")
        camera.stop();
    }

    function selectCamera() {
        if (cameraSelectionEnabled && multipleCameras)
            cameraPopup.open();
    }

    function zoomIn() {
        zoomDigitalSlider.increase();
    }

    function zoomOut() {
        zoomDigitalSlider.decrease();
    }

    function zoomReset() {
        zoomDigitalSlider.value=1.0;
    }

}
