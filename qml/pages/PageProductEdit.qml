/**
 * Product edit view page
 * Used for adding new products and editing existing ones
 *
 * Displays a list of products, can be used for both searching and browsing
 *
 * XXX!!!
 * Re-think handling of Product, perhaps instead use a empty product and bind the properties, with a isValid flag ?
 */
import QtQuick 2.6
import QtQuick.Controls 2.3
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
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
    property bool validAttributes: validPrice && validCategory
    property bool validCategory: categoryID!='' // && ((subCategorySelection.model && categorySubID!='') || !subCategorySelection.model)

    // What does the current category need
    // Required input
    property bool categoryHasPurpose: categoryFlags & CategoryModel.HasPurpose
    property bool categoryHasPrice: categoryFlags & CategoryModel.HasPrice
    property bool categoryHasStock: categoryFlags & CategoryModel.HasStock

    // Optional input
    property bool categoryHasColor: categoryFlags & CategoryModel.HasColor
    property bool categoryHasSize: categoryFlags & CategoryModel.HasSize
    property bool categoryHasWeight: categoryFlags & CategoryModel.HasWeight
    property bool categoryHasISBN: categoryFlags & CategoryModel.HasISBN
    property bool categoryHasEAN: categoryFlags & CategoryModel.HasEAN
    property bool categoryHasMakeAndModel: categoryFlags & CategoryModel.HasMakeAndModel
    property bool categoryHasAuthor: categoryFlags & CategoryModel.HasAuthor

    property bool hasTax: true
    property bool hasLocation: true
    property int defaultWarehouse;

    property int maxImages: 5;

    property bool canAddImages: imageModel.count<maxImages;
    property bool hasImages: imageModel.count>0;

    // Handler needs to requst the Product object and save it.
    signal requestProductSave()

    property bool isSaving: false;

    property bool keepImages: true;

    property alias locationsModel: productWarehouse.model

    property int categoryFlags: 0
    property string categoryID: ""
    property string categorySubID: ""
    property int purposeID: 0
    property string colorID: ""
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
            messagePopup.show(qsTr("Product saved"), qsTr("Product saved succesfully"));
            rootStack.pop();
            return true;
        }
        console.debug("*** Saved failed")
        messagePopup.show(qsTr("Save failed"), qsTr("Saving item failed")+"\n"+"(Error '"+msg+"')");
        savingPopup.close();
        return false;
    }

    onLocationsModelChanged: {        
        console.debug("Pre-selecting location: "+defaultWarehouse)

        if (defaultWarehouse!=0) {
            var i=locationsModel.findLocationByID(defaultWarehouse);
            console.debug(i)
            if (i>-1) {
                productWarehouse.currentIndex=i;
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

    Keys.onReleased: {
        if (event.key === Qt.Key_Back) {
            console.log("*** Back button")
            event.accepted = true;
            confirmBackDialog.open();
        }
    }

    header: ToolbarBasic {
        enableBackPop: false
        onBackButton: {
            confirmBackDialog.open();
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

    footer: ToolBar {
        RowLayout {
            ToolButton {
                text: "Save"
                enabled: validEntry && !isSaving
                contentItem: ItemIcon {
                    source: "qrc:/images/icon_down_box.png"
                }
                onClicked: {
                    bar.currentIndex=0
                    confirmDialog.open();
                }
            }
            ToolButton {
                text: "Capture"
                contentItem: ItemIcon {
                    source: "qrc:/images/icon_camera.png"
                }

                enabled: canAddImages // && validEntry
                onClicked: {
                    bar.currentIndex=1 // image view
                    rootStack.push(pictureCamera)
                }
            }
            ToolButton {
                text: "Add image"
                contentItem: ItemIcon {
                    source: "qrc:/images/icon_gallery.png"
                }
                enabled: canAddImages && hasFileView
                visible: canAddImages && hasFileView
                onClicked: {
                    bar.currentIndex=1 // image view
                    igs.startSelector();
                }
            }
        }
    }

    Component {
        id: pictureCamera
        CameraPage {
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

                // Basedata
                TabButton {                                        
                    background: Rectangle {
                        color: validBaseEntry ? "green" : "red"
                        border.width: 1

                    }                    
                    icon.source: "qrc:/images/icon_home.png"
                }
                // Images
                TabButton {                    
                    background: Rectangle {
                        color: hasImages ? "green" : "red"
                        border.color: "#000"
                        border.width: 1                       
                    }
                    icon.source: "qrc:/images/icon_camera.png"
                }
                // Location
                TabButton {                    
                    background: Rectangle {
                        color: validWarehouse ? "green" : "red"
                        border.color: "#000"
                        border.width: 1                       
                    }
                    icon.source: "qrc:/images/icon_location.png"
                }
                // Attributes
                TabButton {
                    background: Rectangle {
                        color: validAttributes ? "green" : "#d9e006"
                        border.color: "#000"
                        border.width: 1                       
                    }
                    icon.source: "qrc:/images/icon_tag.png"
                }
                // Extras
                TabButton {
                    background: Rectangle {
                        color: productDescription.text!='' ? "green" : "#d9e006"
                        border.color: "#000"
                        border.width: 1                       
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
                    bar.currentIndex=currentIndex
                }

                // Base information view
                ColumnLayout {
                    id: basicData

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

                            enabled: barcodeText.acceptableInput
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
                                if (scm)
                                    subCategorySelection.model=scm;
                                else
                                    subCategorySelection.model=false;
                            }

                        }

                        // This is the specific category
                        ComboBoxLabel {
                            id: subCategorySelection
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
                            enabled: true
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
                            rootStack.push(pictureCamera)
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

                            Button {
                                enabled: canAddImages
                                visible: imageModel.count==0
                                text: qsTr("Add images")
                                onClicked: {
                                    rootStack.push(pictureCamera)
                                }
                            }
                        }
                    }

                    ListView {
                        id: productImages
                        clip: true
                        visible: imageModel.count>0
                        spacing: 4
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        highlightFollowsCurrentItem: true
                        model: imageModel
                        delegate: imageDelegate
                        header: listHeaderImages
                        ScrollIndicator.vertical: ScrollIndicator { }
                    }

                    Component {
                        id: listHeaderImages
                        Rectangle {
                            width: parent.width
                            height: ht.height
                            Text {
                                id: ht
                                color: "#ffffff"
                                anchors.centerIn: parent
                                text: qsTr("Images: ")+imageModel.count+" / " + maxImages;
                                font.pixelSize: 16
                            }
                        }
                    }

                    Component {
                        id: imageDelegate
                        Rectangle {
                            color: ListView.isCurrentItem ? "#f0f0f0" : "#ffffff"
                            id: imageDelegateItem
                            width: parent.width
                            height: Math.min(productEditPage.width/2, productEditPage.height/2)
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

                // Location/Warehouse
                ColumnLayout {
                    id: warehouse
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.alignment: Qt.AlignTop

                    RowLayout {
                        Layout.alignment: Qt.AlignTop
                        TextField {
                            id: productWarehouseSearch
                            Layout.fillWidth: true
                            placeholderText: qsTr("Search for locations")
                            onAccepted: {
                                productWarehouse.currentIndex=-1
                                productWarehouse.model.search(text);
                            }
                        }

                        Button {
                            text: qsTr("Clear")
                            //enabled: productWarehouseSearch.text!=''
                            onClicked: {
                                productWarehouseSearch.text='';
                                productWarehouse.model.clearFilter();
                            }
                        }
                    }

                    LocationListView {
                        id: productWarehouse
                        // headerPositioning: ListView.PullBackHeader
                        header: Text {
                            Layout.alignment: Qt.AlignTop
                            text: qsTr("Locations found: ")+productWarehouse.model.count
                            Layout.fillWidth: true
                        }
                        onLocationChanged: {
                            console.debug("productWarehouse "+location)
                            locationID=location;
                        }
                        onLocationPressAndHold: {

                        }
                    }                    

                    TextField {
                        id: productWarehouseLocation
                        enabled: productWarehouse.currentIndex>=0
                        Layout.fillWidth: true
                        placeholderText: qsTr("Enter storage location")
                        onTextChanged: {
                            locationDetail=text;
                        }
                    }
                }

                // Extra attributes
                ColumnLayout {
                    id: attributes
                    Layout.fillHeight: false

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
                        TextField {
                            id: productPrice
                            text: hasProduct ? product.price : ''
                            inputMethodHints: Qt.ImhPreferNumbers | Qt.ImhFormattedNumbersOnly
                            placeholderText: qsTr("Price")
                            background: Rectangle {
                                color: "transparent"
                                border.color: parent.acceptableInput ? "green" : "red"
                            }
                            leftPadding: 4
                            rightPadding: 4
                            verticalAlignment: TextInput.AlignVCenter
                            Layout.minimumWidth: 120
                            Layout.maximumWidth: 200

                            property double price;

                            signal invalidPrice();

                            validator: DoubleValidator {
                                bottom: 0.0
                                top: 99999.0
                                decimals: 2
                                notation: DoubleValidator.StandardNotation
                            }
                            onAccepted: {
                                parsePrice();
                            }
                            onEditingFinished: {

                            }
                            onFocusChanged: {
                                console.debug("Focus: "+focus)
                                if (!focus)
                                    parsePrice();
                            }
                            onInvalidPrice: {
                                messagePopup.show(qsTr("Product price"), qsTr("Invalid price entry"));
                                price=0.0;
                            }

                            function parsePrice() {
                                var price;
                                try {
                                    price=Number.fromLocaleString(productPrice.text);
                                    if (isNaN(price)) {
                                        invalidPrice();
                                    }
                                } catch(err) {
                                    price=0.0;
                                    invalidPrice();
                                }
                                console.debug("Price is: "+price)
                                productPrice.price=price;
                            }
                        }
                        ComboBox {
                            id: productTax
                            visible: hasTax                            
                            displayText: qsTr("Tax: ")+currentText
                            model: api.getTaxModel();
                            textRole: "display"
                        }
                    }

                    RowLayout {
                        visible: categoryHasStock
                        SpinBoxLabel {
                            id: productStock
                            value: hasProduct ? product.stock : 1
                            from: 1
                            to: 500
                            label: qsTr("Stock amount")
                            // enabled: categoryHasStock
                        }
                    }

                    RowLayout {
                        visible: categoryHasColor
                        Rectangle {
                            id: colorIndicator
                            height: productColor.height
                            width: height
                            Behavior on color {
                                ColorAnimation {
                                    easing.type: Easing.InOutQuad
                                    duration: 200
                                }
                            }
                            border.color: "black"
                        }
                        ComboBox {
                            id: productColor
                            Layout.fillWidth: true
                            textRole: "color"
                            model: root.colorModel
                            onCurrentIndexChanged: {
                                var tmp=model.get(currentIndex);
                                colorIndicator.color=tmp.code;
                                colorID=tmp.cid;
                            }
                        }
                    }

                    Switch {
                        id: sizeSwitch
                        text: qsTr("Size (WxHxD)")
                        visible: categoryHasSize
                        enabled: categoryHasSize
                    }
                    SizeField {
                        id: productSize
                        visible: categoryHasSize
                        enabled: sizeSwitch.checked
                        Layout.fillWidth: true
                    }
                }

                // Extras
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Flickable {
                        clip: true
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        Layout.minimumHeight: productTitle.height*2
                        Layout.maximumHeight: productTitle.height*4
                        TextArea.flickable: TextArea {
                            id: productDescription
                            textFormat: TextEdit.PlainText
                            wrapMode: TextEdit.Wrap
                            placeholderText: qsTr("Enter product description")
                        }
                        flickableDirection: Flickable.VerticalFlick
                        ScrollBar.vertical: ScrollBar { }
                    }

                    ColumnLayout {
                        id: makeAndModel
                        visible: categoryHasMakeAndModel
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Layout.alignment: Qt.AlignTop
                        TextField {
                            id: productMake
                            Layout.fillWidth: true
                            enabled: false
                            placeholderText: qsTr("Product manufacturer")
                        }
                        TextField {
                            id: productModel
                            Layout.fillWidth: true
                            enabled: false
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

    Popup {
        id: savingPopup
        modal: true
        contentHeight: pc.height
        x: parent.width/2-width/2
        y: parent.height/2-height/2
        width: parent.width/2
        //height: parent.height/4
        closePolicy: Popup.NoAutoClose

        Column {
            id: pc
            spacing: 16
            Label {
                id: name
                text: qsTr("Saving...")
                font.bold: true
            }
            BusyIndicator {
                id: busyIndicator
                running: isSaving
                visible: true
                anchors.horizontalCenter: parent.horizontalCenter
            }
            ProgressBar {
                id: savingProgress
                from: 0
                to: 100
                indeterminate: value==0.0
                value: api.uploadProgress
            }
        }
    }

    LocationPopup {
        id: locationPopup
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

        if (hasLocation) {
            p.setAttribute("location", locationID)
            if (locationDetail!='')
                p.setAttribute("locationdetail", locationDetail)
        }

        if (categoryHasColor && colorID!='')
            p.setAttribute("color", colorID)

        if (categoryHasEAN && productEAN.text!='')
            p.setAttribute("ean", productEAN.text)

        if (categoryHasISBN && productISBN.text!='')
            p.setAttribute("isbn", productISBN.text)

        if (categoryHasSize && sizeSwitch.checked) {
            p.setAttribute("width", productSize.itemWidth)
            p.setAttribute("height", productSize.itemHeight)
            p.setAttribute("depth", productSize.itemDepth)
            if (categoryHasWeight) {
                p.setAttribute("weight", productSize.itemWeight)
            }
        }

        if (categoryHasPrice) {
            p.setPrice(parseFloat(productPrice.text));
            if (hasTax) {
                p.setTax(productTax.currentIndex)
            }
        }

        if (categoryHasMakeAndModel) {
            if (productModel.text!='')
                p.setAttribute("model", productModel.text)
            if (productMake.text!='')
                p.setAttribute("manufacturer", productMake.text)
        }

        if (categoryHasAuthor && productAuthor.text!='') {
            p.setAttribute("author", productAuthor.text)
        }

        if (categoryHasStock) {
            console.debug("Setting stock to "+productStock.value)
            p.setStock(productStock.value);
        } else {
            p.setStock(1);
        }

        if (categoryHasPrice && validPrice) {
            p.setPrice(productPrice.price)
        } else {
            p.setPrice(0.0);
        }

        // XXX: Hmm...
        if (categoryHasPrice && hasTax)
            p.setTax(productTax.currentIndex)

        return p;
    }

    MessageDialog {
        id: confirmDialog
        standardButtons: StandardButton.Ok | StandardButton.Cancel
        title: qsTr("Save product ?")
        text: qsTr("Save product:")+"\n"+productTitle.text

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

}
