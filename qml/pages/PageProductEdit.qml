/**
 * Product edit view page
 * Used for adding new products and editing existing ones
 *
 * Displays a list of products, can be used for both searching and browsing
 *
 * XXX!!!
 * Re-think handling of Product, perhaps instead use a empty product and bind the properties, with a isValid flag ?
 */
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.3
import net.ekotuki 1.0

import "../components"

Page {
    id: productEditPage
    title: hasProduct ? qsTr("Edit Product") : qsTr("Add Product");
    objectName: "productEdit"

    width: parent ? parent.width : 0

    // The product we are editing, if we are adding then this is undefined (and is set after successfull save as then we are in editing mode)
    property Product product;
    property bool hasProduct: product ? true : false;
    // The minimum amount of data that needs to be entered toggles this

    property bool validBaseEntry: barcodeText.acceptableInput && validCategory && productTitle.acceptableInput && validPurpose
    property bool validEntry: validBaseEntry && validWarehouse && validPurpose && validPrice && hasImages;
    property bool validWarehouse: locationID>0
    property bool validPurpose: (categoryHasPurpose && purposeSelection.currentIndex>0) || !categoryHasPurpose
    property bool validPrice: (categoryHasPrice && productPrice.price>0.0 && productPrice.acceptableInput) || !categoryHasPrice
    property bool validValue: (categoryHasValue && productValue.price>0.0 && productValue.acceptableInput) || !categoryHasValue
    property bool validAttributes: validPrice && validCategory
    property bool validCategory: categoryID!='' // && ((subCategorySelection.model && categorySubID!='') || !subCategorySelection.model)

    // What attributes does the current category need ?
    // Base properties: basic details
    property bool categoryHasPrice: categoryFlags & CategoryModel.HasPrice
    property bool categoryHasValue: categoryFlags & CategoryModel.HasValue
    property bool categoryHasStock: categoryFlags & CategoryModel.HasStock

    // Base properties: Our special details
    property bool categoryHasPurpose: categoryFlags & CategoryModel.HasPurpose

    // Physical properties
    property bool categoryHasColor: categoryFlags & CategoryModel.HasColor
    property bool categoryHasSize: categoryFlags & CategoryModel.HasSize
    property bool categoryHasWeight: categoryFlags & CategoryModel.HasWeight

    // Category specific properties
    property bool categoryHasISBN: categoryFlags & CategoryModel.HasISBN
    property bool categoryHasEAN: categoryFlags & CategoryModel.HasEAN
    property bool categoryHasMakeAndModel: categoryFlags & CategoryModel.HasMakeAndModel
    property bool categoryHasAuthor: categoryFlags & CategoryModel.HasAuthor

    property bool categoryHasTax: true
    property bool categoryHasLocation: true
    property bool categoryHasLocationDetail: true

    property int defaultWarehouse;

    // Techincally a product can have as many images as there is space but we limit it to someting sane.
    // XXX property int minImages:
    property int maxImages: 6;

    property bool canAddImages: imageModel.count<maxImages;
    property bool hasImages: imageModel.count>0;

    // Handler needs to requst the Product object and save it.
    signal requestProductSave()

    property bool isSaving: false;

    property bool keepImages: true;

    property alias locationsModel: locationPopup.model

    property int categoryFlags: 0
    property string categoryID: ""
    property string categorySubID: ""
    property int purposeID: 0
    property string colorID: ""

    property string colorsIdentifiers: makeColorIdentified(productColor.colorID, productColor2.colorID, productColor3.colorID);

    function makeColorIdentified(c1,c2,c3) {
        if (c1=='')
            return '';
        return c1+";"+c2+";"+c3;
    }

    property int locationID;
    property string locationDetail: ""   

    // Are we adding/editing multiple entries of the same product ? If so
    // we need to enable a bit more complex interface for barcodes.
    property bool multiBarcodeEntry: false

    // Do we enable adding images from the FS ? XXX Not yet available
    property bool hasFileView: true

    // Ask to add more similar items
    property bool addMoreEnabled: true

    property variant colorEditors: []

    // The requestProductSave() handler should call this function to signal if the operation was a success or not
    function confirmProductSave(saved, product, msg) {
        isSaving=false;
        savingPopup.close();

        if (saved) {            
            // Ask for more only if it was a new product
            if (addMoreEnabled && !hasProduct) {
                addMoreProducts.open();
                return false;
            }
            messagePopup.show(qsTr("Product saved"), qsTr("Product saved succesfully"), 200); // XXX
            rootStack.pop();
            return true;
        }
        console.debug("*** Saved failed")
        messagePopup.show(qsTr("Saving failed"), msg, 500); //XXX

        return false;
    }

    Component.onCompleted: {        
        colorEditors[0]=productColor;
        colorEditors[1]=productColor2;
        colorEditors[2]=productColor3;

        if (product) {
            if (populateProduct(product)==false) {
                messagePopup.show(qsTr("Internal error"), qsTr("Failed to populate product fields"), 0);
            }
        }

        barcodeText.forceActiveFocus();
    }

    onLocationIDChanged: {
        var l=locationPopup.model.getId(locationID)
        console.debug(l)
        locationName.text=l.name;
        locationAddress.text=l.zip + " " + l.street
    }

    onLocationsModelChanged: {
        console.debug("Pre-selecting location: "+defaultWarehouse)

        if (defaultWarehouse!=0) {
            var i=locationsModel.findLocationByID(defaultWarehouse);
            console.debug("Location index is: "+i)
            if (i>-1) {
                locationPopup.currentIndex=i;
                locationID=defaultWarehouse;
            }
        }
    }        

    function saveInProgress() {
        isSaving=true;
        savingPopup.open();
    }

    function saveFailed() {
        isSaving=false;
        savingPopup.close();
    }

    function startCamera() {
        rootStack.push(pictureCamera)
    }

    Keys.onReleased: {
        switch (event.key) {
        case Qt.Key_F1:
            event.accepted = true;
            editorSwipeView.setCurrentIndex(0);
            break;
        case Qt.Key_F2:
            event.accepted = true;
            editorSwipeView.setCurrentIndex(1);
            break;
        case Qt.Key_F3:
            event.accepted = true;
            editorSwipeView.setCurrentIndex(2);
            break;
        case Qt.Key_F4:
            event.accepted = true;
            editorSwipeView.setCurrentIndex(3);
            break;
        case Qt.Key_Escape:
            console.log("*** ESC")
            event.accepted = true;
            confirmBackDialog.open();
            break;
        case Qt.Key_Back:
            console.log("*** Back button")
            event.accepted = true;
            if (editorSwipeView.currentIndex>0)
                editorSwipeView.decrementCurrentIndex();
            else
                confirmBackDialog.open();
            break;
        case Qt.Key_Camera:
            event.accepted = true;
            if (canAddImages)
                startCamera();
            break;
        }
    }

    onValidValueChanged: {
        console.debug("*** ValidValue: "+validValue)
        console.debug(productValue.price)
    }

    header: ToolbarBasic {
        enableBackPop: false
        onBackButton: {
            confirmBackDialog.open();
        }
        enableActionButton: validEntry && !isSaving
        visibleActionButton: true
        //actionIcon: "qrc:/images/icon_down_box.png"
        actionText: qsTr("Save")
        onActionButton: {
            editorSwipeView.setCurrentIndex(0);
            confirmDialog.open();
        }
    }

    MessageDialog {
        id: confirmBackDialog
        standardButtons: StandardButton.Ok | StandardButton.Cancel
        icon: StandardIcon.Question
        title: qsTr("Discard product ?")
        text: qsTr("Discard product modifications ?")

        onAccepted: {
            rootStack.pop();
        }

        onRejected: {
            console.debug("*** Back canceled");
        }
    }

    MessageDialog {
        id: addMoreProducts
        standardButtons: StandardButton.Yes | StandardButton.No
        icon: StandardIcon.Question
        title: qsTr("Product saved succesfully")
        text: qsTr("Add similar product with new barcode ?")
        onYes: {
            barcodeText.text=''
        }
        onNo: {
            rootStack.pop();
        }
    }

    MessageDialog {
        id: confirmDialog
        icon: StandardIcon.Question
        standardButtons: StandardButton.Save | StandardButton.Cancel
        title: qsTr("Save product ?")
        text: qsTr("Save product:")
        informativeText: productTitle.text

        onAccepted: {
            console.debug("*** Save accepted");
            confirmDialog.close();
            requestProductSave();
        }

        onRejected: {
            console.debug("*** Save canceled");
        }
    }

    MessagePopup {
        id: messagePopup
    }

    ImageGallerySelector {
        id: igs

        onFileSelected: {
            imageModel.addImage(src, Product.GallerySource);
        }
    }

    onCategoryIDChanged: {
        console.debug(categoryID)
    }

    onCategorySubIDChanged: {
        console.debug(categorySubID)
    }        

    Component {
        id: pictureCamera
        PageCamera {
            id: pCamera
            title: qsTr("Take picture")
            oneShot: false
            scanOnly: false
            imageCapture: true
            Component.onCompleted:  {
                pCamera.startCamera();
            }
            onImageCaptured: {
                imageModel.addImage("file:/"+path, Product.CameraSource);
                if (imageModel.count<maxImages) {
                    captureAnimation.start()
                } else {
                    rootStack.pop();
                }
            }
            Row {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                Text {
                    id: captureCount
                    text: imageModel.count+"/"+maxImages
                    style: Text.Outline
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 26
                    color: imageModel.count<maxImages-1 ? "white" : "yellow"
                    opacity: 0.9
                    transformOrigin: Item.Center
                    SequentialAnimation {
                        id: captureAnimation
                        ScaleAnimator {
                            target: captureCount
                            from: 1
                            to: 1.5
                            duration: 300
                            easing.type: Easing.InOutElastic;
                            easing.amplitude: 2.0;
                            easing.period: 1.2
                        }
                        ScaleAnimator {
                            target: captureCount
                            from: 1.5
                            to: 1
                            duration: 200
                            easing.type: Easing.InOutElastic;
                            easing.amplitude: 2.0;
                            easing.period: 1.4
                        }
                    }
                }
            }
        }
    }

    ListModel {
        id: imageModel
        function addImage(file, src) {
            imageModel.append({
                                  "image": file,
                                  "source": src
                              })
        }
    }

    Component {
        id: imageDisplayPageComponent
        PageImageDisplay {

        }
    }

    function validateBarcode(barcode) {

    }

    ListModel {
        id: productBarcodesModel

        function addBarcode(bc) {

        }
        function removeBarcode(bc) {

        }

    }

    ColumnLayout {
        anchors.fill: parent
        enabled: !isSaving
        spacing: 4

        ColumnLayout {
            id: c
            Layout.fillWidth: true
            Layout.margins: 4

            TabBar {
                id: bar
                Layout.fillWidth: true
                currentIndex: editorSwipeView.currentIndex
                topPadding: 4
                bottomPadding: 4

                // Basedata
                TabButton {
                    background: Rectangle {
                        color: validBaseEntry ? "#19e600" : "#b92929"
                    }
                    icon.source: "qrc:/images/icon_home.png"
                }
                // Images
                TabButton {
                    background: Rectangle {
                        color: hasImages ? "#19e600" : "#b92929"
                    }
                    icon.source: "qrc:/images/icon_camera.png"
                }                
                // Attributes
                TabButton {
                    background: Rectangle {
                        color: validAttributes ? "#19e600" : "#d9e006"
                    }
                    icon.source: "qrc:/images/icon_tag.png"                    
                }
                // Extras
                TabButton {
                    background: Rectangle {
                        color: "#19e600"
                    }
                    icon.source: "qrc:/images/icon_plus.png"                    
                }
            }

            SwipeView {
                id: editorSwipeView
                clip: true
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignTop
                currentIndex: bar.currentIndex                

                ScrollView {
                    id: basicDataSV
                    clip: true
                    contentHeight: basicData.height

                    // Base information view
                    ColumnLayout {
                        id: basicData
                        width: basicDataSV.width

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.alignment: Qt.AlignTop

                            BarcodeScannerField {
                                id: barcodeText
                                scannerEnabled: !hasProduct
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: !barcodeText.acceptableInput
                                horizontalAlignment: Qt.AlignHCenter
                                font.pixelSize: 14
                                text: qsTr("Valid barcode format: AAA123456789")
                            }
                        }

                        // XXX
                        /*
                    RowLayout {
                        Layout.fillWidth: true
                        id: barcodeMultiControl
                        enabled: false;
                        visible: false
                        ComboBox {
                            Layout.fillWidth: true
                        }

                        Button {
                            text: "+"
                            enabled: false
                            onClicked: {

                            }
                        }
                        Button {
                            text: "-"
                            enabled: false
                            onClicked: {

                            }
                        }
                    }
                    */

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.alignment: Qt.AlignTop
                            Layout.margins: 8

                            // This is the "main" category
                            ComboBoxLabel {
                                id: categorySelection
                                currentIndex: 0
                                invalidIndex: 0
                                placeHolder: qsTr("Category")
                                Layout.fillWidth: true
                                // Main category can NOT be changed so don't allow it when editing existing product
                                enabled: !hasProduct
                                model: root.api.getCategoryModel();                                
                                textRole: "category"
                                onCurrentIndexChanged: {
                                    console.debug("onCurrentIndexChanged: "+currentIndex)
                                    updateCategoryData();
                                }

                                function selecteCategory(cid, scid) {
                                    var cmc=model.count;

                                    for (var i=0;i<cmc;i++) {
                                        var c=model.get(i);

                                        console.debug(i+" "+cid+" "+c.cid)

                                        if (c.cid===cid) {
                                            console.debug("CategoryFound! "+c.category)
                                            categorySelection.currentIndex=i;
                                            updateCategoryData();
                                            break;
                                        }
                                    }

                                    if (subCategorySelection.model) {
                                        console.debug("Sub category model is available and sub category is: "+scid)
                                        subCategorySelection.selecteCategory(scid)
                                    } else {

                                    }
                                }

                                function updateCategoryData() {
                                    var cdata=categorySelection.model.get(currentIndex);
                                    if (!cdata || currentIndex==0) {
                                        console.debug("Category de-selected, clearing")
                                        categoryFlags=0;
                                        categoryID=''
                                        categorySubID=''
                                        subCategorySelection.model=false;
                                        return;
                                    }

                                    categoryFlags=cdata.flags;
                                    categoryID=cdata.cid;

                                    var scm=root.api.getSubCategoryModel(cdata.cid);
                                    if (scm) {
                                        subCategorySelection.model=scm;
                                        subCategorySelection.forceActiveFocus();
                                    } else {
                                        subCategorySelection.model=false;
                                    }
                                }

                            }

                            // This is the specific category
                            ComboBoxLabel {
                                id: subCategorySelection
                                visible: model && model.count>0
                                enabled: (hasProduct || categorySelection.enabled) && categorySelection.currentIndex>0 && model
                                textRole: "category"
                                placeHolder: qsTr("Subcategory")
                                Layout.fillWidth: true
                                onCurrentIndexChanged: {
                                    updateSubcategory()
                                }
                                onModelChanged: {
                                    updateSubcategory();
                                }
                                function updateSubcategory() {
                                    if (!model) {
                                        categorySubID=''
                                        return;
                                    }
                                    var cdata=subCategorySelection.model.get(currentIndex)
                                    if (!cdata.cid)
                                        return;
                                    categoryFlags=cdata.flags;
                                    categorySubID=cdata.cid;
                                    productTitle.setDefaultProductTitle("", cdata.category)
                                }
                                function selecteCategory(cid) {
                                    var cmc=model.count;

                                    for (var i=0;i<cmc;i++) {
                                        var c=model.get(i);

                                        console.debug(i+" "+cid+" "+c.cid)

                                        if (c.cid===cid) {
                                            console.debug("SubCategoryFound: "+c.category)
                                            subCategorySelection.currentIndex=i;
                                            updateSubcategory();
                                            break;
                                        }
                                    }
                                }
                            }

                            ComboBoxLabel {
                                id: purposeSelection
                                model: root.purposeModel
                                enabled: categoryHasPurpose
                                visible: categoryHasPurpose
                                textRole: "purpose"
                                placeHolder: qsTr("Usage")
                                Layout.fillWidth: true
                                currentIndex: 0 //xxx
                                invalidIndex: 0
                                onCurrentIndexChanged: {
                                    var pdata=model.get(currentIndex)
                                    purposeID=pdata.pid;
                                }
                                /*
                                  XXX: Fix this
                                contentItem: Row {
                                    width: parent.width
                                    PurposeBadge {
                                        size: pst.height+16
                                        purpose: purposeID
                                    }
                                    Text {
                                        id: pst
                                        leftPadding: 8
                                        rightPadding: purposeSelection.indicator.width + purposeSelection.spacing
                                        text: purposeSelection.displayText
                                        font: purposeSelection.font
                                        //color: purposeSelection.pressed ? "#17a81a" : "#21be2b"
                                        horizontalAlignment: Text.AlignLeft
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                    }
                                }
                                */
                            }

                            RowLayout {
                                Layout.alignment: Qt.AlignTop
                                ColumnLayout  {
                                    visible: validWarehouse
                                    Layout.fillWidth: true
                                    Label {
                                        id: locationName
                                        Layout.fillWidth: true
                                    }
                                    Label {
                                        id: locationAddress
                                        font.pixelSize: 14
                                        Layout.fillWidth: true
                                    }
                                }
                                ColumnLayout {
                                    visible: !validWarehouse
                                    Label {
                                        text: qsTr("Select a location")
                                        Layout.fillWidth: true
                                        background: Rectangle {
                                            color: "transparent"
                                            border.color: "red"
                                        }
                                    }
                                }

                                RoundButton {
                                    icon.source: "qrc:/images/icon_location.png"
                                    onClicked: {
                                        locationPopup.open();
                                    }
                                }
                            }

                            TextField {
                                id: productTitle
                                Layout.fillWidth: true
                                selectByMouse: true
                                leftPadding: 4
                                inputMethodHints: Qt.ImhNoPredictiveText
                                placeholderText: qsTr("Product summary, title")
                                validator: RegExpValidator {
                                    regExp: /.{4,}/
                                }
                                maximumLength: 200
                                background: Rectangle {
                                    color: "transparent"
                                    border.color: parent.acceptableInput ? "green" : "red"
                                }
                                property bool wasModified: false;
                                onEditingFinished: {
                                    if (acceptableInput)
                                        wasModified=true;
                                }

                                // XXX: Expand on this!
                                function setDefaultProductTitle(mc, sc) {
                                    if (hasProduct || productTitle.wasModified)
                                        return;

                                    if (sc)
                                        productTitle.text=sc;
                                }
                            }
                            ScrollView {
                                Layout.fillWidth: true
                                ScrollBar.horizontal.interactive: true
                                Layout.minimumHeight: productTitle.height*2
                                Layout.maximumHeight: productTitle.height*4
                                ScrollBar.vertical.policy: ScrollBar.AlwaysOn
                                ScrollBar.vertical.interactive: true
                                clip: true
                                TextArea {
                                    id: productDescription
                                    textFormat: TextEdit.PlainText
                                    wrapMode: TextEdit.Wrap
                                    selectByMouse: true
                                    width: parent.width
                                    placeholderText: qsTr("Enter product description")
                                }
                            }
                            SpinBoxLabel {
                                id: productStock
                                visible: categoryHasStock
                                value: 1
                                from: 1
                                to: 500
                                label: qsTr("Stock amount")
                                // enabled: categoryHasStock
                            }

                        }
                    }
                }

                // Images and capture interface
                ColumnLayout {
                    id: images
                    Layout.margins: 4

                    property bool isActive: SwipeView.isCurrentItem;
                    property bool isFirstVisit: true;

                    onIsActiveChanged: {
                        if (isActive && canAddImages && imageModel.count===0 && isFirstVisit) {
                            isFirstVisit=false;
                            startCamera();
                        }
                    }

                    Item {
                        visible: imageModel.count==0
                        Layout.fillHeight: true
                        Layout.fillWidth: true

                        Column {
                            anchors.centerIn: parent
                            Text {
                                text: qsTr("No images have been assigned")
                                font.pointSize: 18
                                wrapMode: Text.Wrap
                                horizontalAlignment: Text.AlignHCenter
                            }                            

                            RoundButton {                                
                                text: qsTr("Take picture")
                                icon.source: "qrc:/images/icon_camera.png"
                                enabled: canAddImages && imageModel.count==0
                                anchors.horizontalCenter: parent.horizontalCenter
                                onClicked: {
                                    startCamera();
                                }
                            }

                            RoundButton {
                                text: qsTr("Pick from gallery")
                                icon.source: "qrc:/images/icon_gallery.png"
                                enabled: canAddImages && hasFileView
                                visible: canAddImages && hasFileView && imageModel.count==0
                                anchors.horizontalCenter: parent.horizontalCenter
                                onClicked: {
                                    igs.startSelector();
                                }
                            }
                        }
                    }

                    GridView {
                        id: productImages
                        clip: true
                        visible: imageModel.count>0                        
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        highlightFollowsCurrentItem: true
                        model: imageModel
                        delegate: imageDelegate
                        header: listHeaderImages
                        ScrollIndicator.vertical: ScrollIndicator { }
                        cellWidth: productImages.width/2
                        cellHeight: productImages.height/3
                        snapMode: GridView.SnapToRow
                    }

                    Component {
                        id: listHeaderImages
                        Rectangle {
                            width: parent.width
                            height: ht.height
                            Text {
                                id: ht                                
                                anchors.centerIn: parent
                                text: qsTr("Images: ")+imageModel.count+" / " + maxImages;
                                font.pixelSize: 16
                            }
                        }
                    }

                    Component {
                        id: imageDelegate
                        Rectangle {
                            color: ListView.isCurrentItem ? "#e0e0e0" : "#fafafa"
                            id: imageDelegateItem
                            width: productImages.cellWidth
                            height: productImages.cellHeight
                            clip: true

                            Image {
                                id: thumb
                                sourceSize.height: 512
                                anchors.fill: parent;
                                anchors.margins: 8
                                asynchronous: true;
                                smooth: true
                                fillMode: Image.PreserveAspectFit
                                source: image
                                anchors.horizontalCenter: parent.horizontalCenter
                                rotation: appUtil.getImageRotation(image);
                            }

                            // Visualy show image load error, for example on Android if storage permissions arent granted properly
                            Rectangle {
                                anchors.fill: parent;
                                color: "red"
                                visible: thumb.status==Image.Error
                                Text {
                                    anchors.centerIn: parent
                                    text: qsTr("Image load error")
                                }
                            }

                            Menu {
                                id: imageMenu
                                title:  qsTr("Image")
                                modal: true
                                dim: true
                                x: parent.width/3
                                MenuItem {
                                    text: qsTr("View image")
                                    onClicked: {
                                        rootStack.push(imageDisplayPageComponent, { "image": thumb.source } )
                                    }
                                }

                                MenuItem {
                                    text: qsTr("Remove image")
                                    enabled: !hasProduct
                                    onClicked: {
                                        // XXX: Remove the file itself too
                                        imageModel.remove(index)
                                    }
                                }

                                MenuItem {
                                    enabled: false && !hasProduct
                                    text: "Edit"
                                    onClicked: {

                                    }
                                }

                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    productImages.currentIndex=index;
                                    rootStack.push(imageDisplayPageComponent, { "image": thumb.source } )
                                }
                                onPressAndHold: {
                                    console.debug("*** Image PH")
                                    productImages.currentIndex=index;
                                    imageMenu.open();
                                }
                            }
                        }
                    }

                }

                // Extra attributes
                ColumnLayout {
                    id: attributes
                    Layout.alignment: Qt.AlignTop

                    Text {
                        visible: categoryID=='';
                        Layout.fillWidth: true
                        text: qsTr("Please select a category first")
                        font.pointSize: 18
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                    }

                    RowLayout {
                        visible: categoryHasPrice
                        Layout.alignment: Layout.Center

                        PriceField {
                            id: productPrice
                            Layout.minimumWidth: 120
                            Layout.maximumWidth: 200                                                        
                        }
                        ComboBox {
                            id: productTax
                            visible: categoryHasTax
                            displayText: qsTr("Tax: ")+currentText
                            model: api.getTaxModel();
                            textRole: "display"
                        }
                    }

                    RowLayout {
                        visible: categoryHasValue
                        Layout.alignment: Layout.Center

                        PriceField {
                            id: productValue
                            Layout.fillWidth: true
                            isOptional: true;
                            placeholderText: qsTr("Product value")
                        }
                    }

                    ColorSelector {
                        id: productColor
                        visible: categoryHasColor
                        model: api.colorModel
                    }
                    ColorSelector {
                        id: productColor2
                        visible: categoryHasColor && productColor.colorIndex>0
                        model: api.colorModel
                    }
                    ColorSelector {
                        id: productColor3
                        visible: categoryHasColor && productColor2.colorIndex>0
                        model: api.colorModel
                    }

                    SizeField {
                        id: productSize
                        Layout.alignment: Qt.AlignTop
                        visible: categoryHasSize
                        //enabled: sizeSwitch.checked
                        Layout.fillWidth: true                        
                    }
                }

                // Extras
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    Layout.margins: 4

                    ColumnLayout {
                        id: makeAndModel
                        visible: categoryHasMakeAndModel
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Layout.alignment: Qt.AlignTop
                        Label {
                            text: qsTr("Product manufacturer")
                        }
                        ComboBox {
                            id: productMake
                            Layout.fillWidth: true
                            editable: true
                            model: manufacturerModel
                            textRole: "manufacturer"
                            Component.onCompleted: console.debug("*** MODEL HAS MANUFACTURERS: "+model.length)
                            onAccepted: {
                                productModel.forceActiveFocus()
                            }
                        }
                        TextField {
                            id: productModel
                            Layout.fillWidth: true
                            placeholderText: qsTr("Product model")
                        }
                    }

                    ColumnLayout {
                        id: author
                        Layout.fillWidth: true
                        visible: categoryHasAuthor
                        TextField {
                            id: productAuthor
                            Layout.fillWidth: true
                            enabled: false
                            placeholderText: qsTr("Product author")
                        }
                    }
                    // EAN/ISBN
                    ColumnLayout {
                        id: eanCode
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        RowLayout {
                            BarcodeScannerField {
                                id: productEAN
                                visible: categoryHasEAN
                                scannerEnabled: categoryHasEAN
                                isOptional: true
                                placeholderText: qsTr("Type or scan EAN")
                                inputMethodHints:  Qt.ImhNoPredictiveText | Qt.ImhPreferNumbers
                                validator: EanValidator { }
                            }
                        }
                        RowLayout {
                            BarcodeScannerField {
                                id: productISBN
                                visible: categoryHasISBN
                                isOptional: true
                                placeholderText: qsTr("Type or scan ISBN")
                                scannerEnabled: categoryHasISBN
                                inputMethodHints:  Qt.ImhNoPredictiveText | Qt.ImhPreferNumbers
                                validator: EanValidator { }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: productTemplate
        Product {

        }
    }

    RowLayout {
        id: cameraActionButtons
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 32
        anchors.bottomMargin: 32
        height: 32
        property bool maybeVisible: images.isActive && canAddImages && !hasProduct
        visible: maybeVisible && imageModel.count>0
        opacity: maybeVisible ? 1 : 0;
        RoundButton {
            icon.source: "qrc:/images/icon_gallery.png"
            enabled: canAddImages && hasFileView
            visible: canAddImages && hasFileView
            onClicked: {
                // XXX: Don't go there bar.currentIndex=1 // image view
                igs.startSelector();
            }
        }
        RoundButton {            
            icon.source: "qrc:/images/icon_camera.png"
            enabled: canAddImages
            onClicked: {
                startCamera();
            }
        }
    }

    PopupProgress {
        id: savingPopup
        label: qsTr("Saving product")
        description: api.uploadProgress<100 ? qsTr("Uploading") : qsTr("Waiting for response")
        value: api.uploadProgress
    }

    LocationPopup {
        id: locationPopup        
        onLocationDetailChanged: productEditPage.locationDetail=locationDetail;
        onLocationIDChanged: productEditPage.locationID=locationID
        onRefresh: api.requestLocations();
        hasLocationDetail: categoryHasLocationDetail
    }

    function populateProduct(p) {
        productTitle.text=p.title;
        productDescription.text=p.description;
        barcodeText.text=p.barcode;

        p.getAttributes();

        // We let the magic do it
        //categoryID=p.category;
        //categorySubID=p.subCategory;

        categorySelection.selecteCategory(p.category, p.subCategory)

        for (var i=0;i<p.images.length;i++) {
            console.debug("Image: "+p.images[i]);
            imageModel.addImage(p.images[i], Product.RemoteSource);
        }

        if (categoryHasPurpose && p.hasAttribute("purpose"))
            purposeID=p.getAttribute("purpose")

        if (categoryHasLocation) {
            locationID=p.getWarehouse();
            var i=locationsModel.findLocationByID(locationID);
            console.debug("Location index is: "+i)
            if (i>-1)
                locationPopup.currentIndex=i;

            if (categoryHasLocationDetail && p.hasAttribute("locationdetail"))
                locationDetail=p.getAttribute("locationdetail")
        }

        // XXX
        if (categoryHasColor && p.hasAttribute("color")) {
            var col=p.getAttribute("color");
            console.debug(col)
            console.debug(col.length)
            for (var i=0;i<col.length;i++) {
                console.debug(i+" "+col[i])
                var ri=colorEditors[i].setColor(col[i]);
                console.debug(ri)
            }
        }

        if (categoryHasMakeAndModel) {
            productMake.editText=p.getAttribute("manufacturer")
            productModel.text=p.getAttribute("model")
        }

        if (categoryHasEAN && p.hasAttribute("ean"))
            productEAN.text=p.getAttribute("ean")

        if (categoryHasISBN && p.hasAttribute("isbn"))
            productISBN.text=p.getAttribute("isbn")

        if (categoryHasAuthor && p.hasAttribute("author")) {
            productAuthor.text=p.getAttribute("author")
        }

        if (categoryHasSize && p.hasAttribute("width")) {
            productSize.itemWidth=p.getAttribute("width")
            productSize.itemHeight=p.getAttribute("height")
            productSize.itemDepth=p.getAttribute("depth")
        }
        if (categoryHasWeight && p.hasAttribute("weight")) {
            productSize.itemWeight=p.getAttribute("weight")
        }

        if (categoryHasValue && p.hasAttribute("value")) {
            productValue.price=p.getAttribute("value")
        }

        if (categoryHasStock) {
            productStock.value=p.getStock();
        } else {
            productStock.value=1;
        }

        return true;
    }

    // Create a new product from filled data
    function createProduct() {
        var p=newProduct();
        fillProduct(p);
        return p;
    }

    // Create a new product item
    function newProduct() {
        return productTemplate.createObject(null, {});
    }

    function addProductImages(p) {
        for (var i=0;i<imageModel.count;i++) {
            var s=imageModel.get(i);
            p.addImage(s.image, s.source);
        }
    }

    // Fill product with filled data
    function fillProduct(p) {

        p.getAttributes();

        p.title=productTitle.text;
        p.description=productDescription.text;

        // Set information that can be changed only for new items
        if (p.isNew()) {
            p.barcode=barcodeText.text;
            p.category=categoryID;            
            p.keepImages=keepImages;
            addProductImages(p)
        }

        // Sub category can be changed
        p.subCategory=categorySubID;

        if (categoryHasPurpose && purposeID>0) {
            p.setAttribute("purpose", purposeID)
        }

        if (categoryHasLocation) {
            p.setAttribute("location", locationID)
            if (categoryHasLocationDetail && locationDetail!='')
                p.setAttribute("locationdetail", locationDetail)
        }

        if (categoryHasColor) {
            p.setAttribute("color", colorsIdentifiers)
        }

        if (categoryHasEAN && productEAN.text!='')
            p.setAttribute("ean", productEAN.text)

        if (categoryHasISBN && productISBN.text!='')
            p.setAttribute("isbn", productISBN.text)

        if (categoryHasSize) {
            p.setAttribute("width", productSize.itemWidth)
            p.setAttribute("height", productSize.itemHeight)
            p.setAttribute("depth", productSize.itemDepth)            
        }
        if (categoryHasWeight) {
            p.setAttribute("weight", productSize.itemWeight)
        }

        if (categoryHasPrice && validPrice) {
            p.setPrice(productPrice.price)
            if (hasTax) {
                p.setTax(productTax.currentIndex)
            }
        } else {
            p.setPrice(0.0);
        }

        if (categoryHasValue && validValue) {            
            p.setAttribute("value", productValue.price)            
        }

        if (categoryHasMakeAndModel) {
            if (productMake.currentText!='') {
                p.setAttribute("manufacturer", productMake.currentText)
                if (find(productMake.currentText) === -1)
                    productMake.model.append({text: productMake.currentText})
            }

            if (productModel.text!='')
                p.setAttribute("model", productModel.text)
        }

        if (categoryHasAuthor && productAuthor.text!='') {
            p.setAttribute("author", productAuthor.text)
        }

        if (categoryHasStock) {            
            p.setStock(productStock.value);
        } else {
            p.setStock(1);
        }     

        return p;
    }

}
