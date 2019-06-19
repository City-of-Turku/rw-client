/**
 * Product edit view page
 * Used for adding new products and editing existing ones
 *
 * Displays a list of products, can be used for both searching and browsing
 *
 * XXX!!!
 * Re-think handling of Product, perhaps instead use a empty product and bind the properties, with a isValid flag ?
 */
import QtQuick 2.11
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

    property string colorsIdentifiers: productColor.colorID+";"+productColor2.colorID+";"+productColor3.colorID

    onColorsIdentifiersChanged: console.debug(colorsIdentifiers)

    property int locationID;
    property string locationDetail: ""   

    // Are we adding/editing multiple entries of the same product ? If so
    // we need to enable a bit more complex interface for barcodes.
    property bool multiBarcodeEntry: false

    // Do we enable adding images from the FS ? XXX Not yet available
    property bool hasFileView: true

    // Ask to add more similar items
    property bool addMoreEnabled: true

    // The requestProductSave() handler should call this function to signal if the operation was a success or not
    function confirmProductSave(saved, product, msg) {
        isSaving=false;
        if (saved) {
            savingPopup.close();
            if (addMoreEnabled) {
                addMoreProducts.open();
                return false;
            }
            messagePopup.show(qsTr("Product saved"), qsTr("Product saved succesfully"), 200); // XXX
            rootStack.pop();
            return true;
        }
        console.debug("*** Saved failed")
        messagePopup.show(qsTr("Saving failed"),msg, 500); //XXX
        savingPopup.close();
        return false;
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
            editorSwipeView.currentIndex=0;
            break;
        case Qt.Key_F2:
            event.accepted = true;
            editorSwipeView.currentIndex=1;
            break;
        case Qt.Key_F3:
            event.accepted = true;
            editorSwipeView.currentIndex=2;
            break;
        case Qt.Key_F4:
            event.accepted = true;
            editorSwipeView.currentIndex=3;
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
                editorSwipeView.currentIndex--;
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

    header: ToolbarBasic {
        enableBackPop: false
        onBackButton: {
            confirmBackDialog.open();
        }
        enableActionButton: validEntry && !isSaving
        visibleActionButton: true
        actionIcon: "qrc:/images/icon_down_box.png"
        onActionButton: {
            bar.currentIndex=0
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

    Component.onCompleted: {
        barcodeText.forceActiveFocus();
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
                rootStack.pop();
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
                onCurrentIndexChanged: {
                    console.debug("CurrentViewIndex: "+currentIndex)
                    // bar.currentIndex=currentIndex
                }

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

                                // XXX lets allow always?
                                // enabled: barcodeText.acceptableInput
                                textRole: "category"
                                Component.onCompleted: {
                                    model=root.api.getCategoryModel();
                                }
                                onCurrentIndexChanged: {
                                    console.debug("CategoryIndex: "+currentIndex)
                                    updateCategoryData();
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
                                visible: enabled && model && model.count>0
                                enabled: categorySelection.enabled && categorySelection.currentIndex>0 && model
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
                            }

                            ComboBoxLabel {
                                id: purposeSelection
                                model: root.purposeModel
                                enabled: categoryHasPurpose
                                visible: categoryHasPurpose
                                textRole: "purpose"
                                placeHolder: qsTr("Usage")
                                Layout.fillWidth: true
                                onCurrentIndexChanged: {
                                    var pdata=model.get(currentIndex)
                                    purposeID=pdata.pid;
                                }
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
                                    width: parent.width
                                    placeholderText: qsTr("Enter product description")
                                }
                            }
                            SpinBoxLabel {
                                id: productStock
                                visible: categoryHasStock
                                value: hasProduct ? product.stock : 1
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

                            Menu {
                                id: imageMenu
                                title: "Product image"
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
                                    onClicked: {
                                        // XXX: Remove the file itself too
                                        imageModel.remove(index)
                                    }
                                }

                                MenuItem {
                                    enabled: false
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
                    Layout.fillWidth: true
                    Layout.fillHeight: false
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
                            Layout.minimumWidth: 120
                            Layout.maximumWidth: 200

                            id: productPrice
                            text: hasProduct ? product.price : ''
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
                            Layout.fillWidth: true
                            id: productValue
                            text: hasProduct ? product.value : ''
                            placeholderText: qsTr("Product value")
                        }
                    }

                    ColorSelector {
                        id: productColor
                        visible: categoryHasColor
                        model: root.colorModel
                    }
                    ColorSelector {
                        id: productColor2
                        visible: categoryHasColor && productColor.colorIndex>0
                        model: root.colorModel
                    }
                    ColorSelector {
                        id: productColor3
                        visible: categoryHasColor && productColor2.colorIndex>0
                        model: root.colorModel
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
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.alignment: Qt.AlignTop

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
                                placeholderText: qsTr("Type or scan EAN")
                                validator: RegExpValidator {
                                    regExp: /[0-9]{10,13}/
                                }
                            }
                        }
                        RowLayout {
                            BarcodeScannerField {
                                id: productISBN
                                visible: categoryHasISBN
                                placeholderText: qsTr("Type or scan ISBN")
                                scannerEnabled: categoryHasISBN
                                validator: RegExpValidator {
                                    regExp: /[0-9]{10,13}/
                                }
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
        property bool maybeVisible: images.isActive && canAddImages
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

    function createProduct() {
        var p=productTemplate.createObject(null, {
                                               title: productTitle.text,
                                               description: productDescription.text,
                                               barcode: barcodeText.text,
                                               category: categoryID,
                                               subCategory: categorySubID
                                           })
        p.keepImages=keepImages;

        for (var i=0;i<imageModel.count;i++) {
            var s=imageModel.get(i);
            p.addImage(s.image, s.source);
        }

        if (categoryHasPurpose)
            p.setAttribute("purpose", purposeID)

        if (categoryHasLocation) {
            p.setAttribute("location", locationID)
            if (categoryHasLocationDetail && locationDetail!='')
                p.setAttribute("locationdetail", locationDetail)
        }

        if (categoryHasColor) {
            var c;
            if (productColor.colorID!='') {
                c=productColor.colorID;
                if (productColor2.colorID!='')
                    c+=";"+productColor2.colorID;
                if (productColor2.colorID!='' && productColor3.colorID!='')
                    c+=";"+productColor3.colorID;

                p.setAttribute("color", c)
            }
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
            if (productMake.editText!='') {
                p.setAttribute("manufacturer", productMake.editText)
                if (find(productMake.editText) === -1)
                    productMake.model.append({text: productMake.editText})
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
