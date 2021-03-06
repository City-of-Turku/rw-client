import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
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

    // Flash off or on/auto
    property bool flash: camera.flash.mode!=Camera.FlashOff

    property bool hasFlashOptions: camera.flash.supportedModes.length>1

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

                console.debug(imageCapture.resolution)
                console.debug(camera.flash.supportedModes.length)

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

        flash {
            // mode: Camera.FlashOff
            onFlashModeChanged: {
                flashModes.refresh()
            }
        }

        Component.onCompleted: {
            console.debug("Camera is: "+deviceId)
            console.debug("Camera orientation is: "+orientation)

            if (scanOnly) {
                camera.exposure.exposureMode=Camera.ExposureBarcode
            } else {
                camera.exposure.exposureMode=Camera.ExposureAuto
            }
            flashModes.refresh()
        }
    }

    // Sigh, Flash mode list is just a bunch of enums instead of camera or resolution lists,
    // so create a model manually. Skip the modes that are not needed.
    ListModel {
        id: flashModes

        function refresh(fm) {
            flashModes.clear()
            for (var i=0;i<camera.flash.supportedModes.length;i++) {
                console.debug(camera.flash.supportedModes[i])
                switch (camera.flash.supportedModes[i]) {
                case Camera.FlashOff:
                    flashModes.append({"mode": Camera.FlashOff, "name": "Off"})
                    break;
                case Camera.FlashOn:
                    flashModes.append({"mode": Camera.FlashOn, "name": "On"})
                    break;
                case Camera.FlashAuto:
                    flashModes.append({"mode": Camera.FlashAuto, "name": "Auto"})
                    break;
                case Camera.FlashFill:
                    flashModes.append({"mode": Camera.FlashFill, "name": "Shadow fill"})
                    break;
                }
            }
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
        id: flashPopup
        modal: true

        width: parent.width/2
        height: parent.height/3
        ListView {
            id: flashList
            anchors.fill: parent
            clip: true
            model: flashModes
            ScrollIndicator.vertical: ScrollIndicator { }
            delegate: Text {
                text: name
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                font.pixelSize: 22
                leftPadding: 4
                rightPadding: 4
                topPadding: 8
                bottomPadding: 8
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        console.debug("FlashMode: "+mode)
                        camera.flash.setFlashMode(mode)
                        flashPopup.close();
                    }
                }
            }
        }
    }

    Popup {
        id: isoPopup
        modal: true
        dim: false

        ButtonGroup {
            id: isoButtonGroup
            onCheckedButtonChanged: {
                var iso=checkedButton.text;
                switch (iso) {
                case 'Auto':
                    camera.exposure.setAutoIsoSensitivity();
                    break;
                case '100':
                    camera.exposure.manualIso=100;
                    break;
                case '200':
                    camera.exposure.manualIso=200;
                    break;
                case '400':
                    camera.exposure.manualIso=400;
                    break;
                case '800':
                    camera.exposure.manualIso=800;
                    break;
                }
                console.debug(camera.exposure.manualIso)
            }
        }

        ColumnLayout {
            RadioButton {
                checked: true
                text: "Auto"
                ButtonGroup.group: isoButtonGroup
            }
            RadioButton {
                text: "100"
                ButtonGroup.group: isoButtonGroup
            }
            RadioButton {
                text: "200"
                ButtonGroup.group: isoButtonGroup
            }
            RadioButton {
                text: "400"
                ButtonGroup.group: isoButtonGroup
            }
            RadioButton {
                text: "800"
                ButtonGroup.group: isoButtonGroup
            }
        }
    }

    Popup {
        id: resolutionPopup
        modal: true
        width: parent.width/1.5
        height: parent.height/1.5

        function getResolutionText(w,h) {
            var m=Math.floor(w*h/1000/1000);
            if (m>0) {
                return w + " x " + h + " " + m + "Mbit"
            } else {
                return w + " x " + h
            }
        }

        ListView {
            id: resolutionList
            anchors.fill: parent
            clip: true
            model: camera.imageCapture.supportedResolutions
            ScrollIndicator.vertical: ScrollIndicator { }
            delegate: Text {
                color: resma.pressed ? "#101060" : "#000000"
                text: resolutionPopup.getResolutionText(modelData.width, modelData.height)
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
                    id: resma
                    anchors.fill: parent
                    onClicked: {
                        console.debug(modelData)
                        camera.imageCapture.resolution=modelData
                        resolutionPopup.close();
                    }
                }
            }
        }
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
            ScrollIndicator.vertical: ScrollIndicator { }
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
            text: "ISO"
            visible: true
            onClicked: {
                isoPopup.open();
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

    function selectISO() {
        isoPopup.open();
    }

    function selectFlash() {
        flashPopup.open();
    }

    function flashOff() {
        camera.flash.setFlashMode(Camera.FlashOff)
    }

    function selectResolution() {
        resolutionPopup.open();
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

    function setFullAuto() {
        camera.exposure.setAutoAperture()
        camera.exposure.setAutoIsoSensitivity()
        camera.exposure.setAutoShutterSpeed()
        camera.flash.setFlashMode(Camera.FlashAuto)
        camera.exposure.exposureMode=Camera.ExposureAuto
    }

}
