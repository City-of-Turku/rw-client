/**
 * Product list view page
 *
 * Displays a list of products, can be used for both searching and browsing
 *
 */
import QtQuick 2.9
import QtQml 2.2
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3

import net.ekotuki 1.0

import "../delegates"
import "../components"

Page {
    id: searchPage
    title: qsTr("Products")

    objectName: "search"

    property bool searchActive: false;

    property bool isInitialView: true

    property alias model: searchResults.model

    property ItemModel cartModel;

    signal searchRequested(string str, string category);
    signal searchBarcodeRequested(string barcode);
    signal searchCancel();

    signal requestLoadMore(string str, string category);

    property bool searchVisible: true

    property string categorySearchID: '';
    property string searchString: ''

    property double pageRatio: width/height
    //onPageRatioChanged: console.debug(pageRatio)

    property int itemsPerRow: pageRatio>1.0 ? 4 : 2;

    // searchRequested handler should call this
    function setSearchActive(a) {
        searchActive=a;
        if (a && Qt.inputMethod.visible)
            Qt.inputMethod.hide();
    }

    // searchCancel
    function searchCanceled() {
        searchActive=false;
    }

    function searchBarcodeNotFound() {
        messagePopup.show(qsTr("Not found"), qsTr("No product matched given barcode"));
        searchActive=false;
    }

    // Wrapper to select the appropriate search method
    function doSearch() {

    }

    function toggleSearch() {
        searchDrawer.open()
    }

    Keys.onReleased: {
        switch (event.key) {
        case Qt.Key_Back:
            //event.accepted=true;
            //rootStack.pop()
            break;
        case Qt.Key_Home:
            searchResults.positionViewAtBeginning()
            event.accepted=true;
            break;
        case Qt.Key_End:
            searchResults.positionViewAtEnd()
            searchResults.maybeTriggerLoadMore();
            event.accepted=true;
            break;
        case Qt.Key_Space:
            //searchResults.moveCurrentIndexDown()
            searchResults.flick(0, -searchResults.maximumFlickVelocity)
            event.accepted=true;
            break;
        case Qt.Key_PageDown:
            //searchResults.moveCurrentIndexDown()
            searchResults.flick(0, -searchResults.maximumFlickVelocity/2)
            event.accepted=true;
            break;
        case Qt.Key_PageUp:
            //searchResults.moveCurrentIndexUp()
            searchResults.flick(0, searchResults.maximumFlickVelocity/2)
            event.accepted=true;
            break;
        case Qt.Key_S:
            searchDrawer.open()
            event.accepted=true;
            break;
        }
    }

    Component.onCompleted: {
        console.debug("*** Completed: "+objectName)
        console.debug(searchString)
        console.debug(searchString.length)
        model=root.api.getItemModel();
        cartModel=root.api.getCartModel();
        searchResults.currentIndex=-1;
        if (searchString.length>0) {
            console.debug("Created with pre-populated search string: "+searchString)
            if (api.validateBarcode(searchString))
                searchBarcodeRequested(searchString);
            else
                searchRequested(searchString, -1)
        }
        searchPage.forceActiveFocus();
    }

    Component.onDestruction: {
        console.debug("*** Destroy: "+objectName)
        //model.clear();
    }

    footer: ToolBar {
        RowLayout {
            ToolButton {
                // XXX: Icons!
                id: tbViewType
                visible: searchResults.model.count>1
                text: searchResults.rowItems==1 ? qsTr("Grid") : qsTr("List")
                icon.source: searchResults.rowItems==1 ? "qrc:/images/icon_grid.png" : "qrc:/images/icon_list.png"
                onClicked: {
                    if (searchResults.rowItems==1)
                        searchResults.rowItems=itemsPerRow;
                    else
                        searchResults.rowItems=1;
                }
            }
            ToolButton {
                id: tbSortOrder
                visible: searchResults.model.count>1

            }
        }
    }

    Component {
        id: cameraScanner
        PageCamera {
            id: scanCamera
            oneShot: true
            Component.onCompleted: {
                scanCamera.startCamera();
            }
            onBarcodeFound: {
                searchString=barcode;
            }
            onDecodeDone: {
                if (api.validateBarcode(searchString)) {
                    searchBarcodeRequested(searchString);
                    rootStack.pop();
                } else {
                    invalidBarcodeMessage.show(qsTr("Barcode"), qsTr("Barcode format is not recognized. Please try again."));
                }
            }
        }
    }

    MessagePopup {
        id: invalidBarcodeMessage
    }

    ColumnLayout {
        id: mainContainer
        anchors.fill: parent
        anchors.margins: 4

        // Browse mode
        Label {
            visible: searchResults.count==0 && !searchVisible && !isInitialView
            text: qsTr("No products available in selected category")
            wrapMode: Text.Wrap
            font.pixelSize: 32
        }

        Label {
            visible: searchResults.count==0 && searchString.length!=0 && !searchActive && !isInitialView
            text: qsTr("No products found")
            wrapMode: Text.Wrap
            font.pixelSize: 32
        }

        Component {
            id: imageDisplayPageComponent
            PageImageDisplay {

            }
        }

        GridView {
            id: searchResults
            enabled: !searchActive
            clip: true
            Layout.fillWidth: true
            Layout.fillHeight: true
            footer: listFooter;
            highlightFollowsCurrentItem: true
            //spacing: 4
            currentIndex: -1;
            cellWidth: model.count>1 ? cellSize : searchResults.width
            cellHeight: model.count>1 ? cellSize : searchResults.width

            interactive: true

            // XXX: Does not trigger atYEnd so can't use this
            //highlightRangeMode: GridView.StrictlyEnforceRange
            snapMode: GridView.SnapToRow

            property int rowItems: itemsPerRow
            property int cellSize: searchResults.width/rowItems

            delegate: Component {
                ProductItemDelegate {
                    width: searchResults.cellWidth
                    height: searchResults.cellHeight
                    onClicked: {
                        openProductAtIndex(index)
                    }

                    onClickedImage: {
                        openProductAtIndex(index)
                    }

                    onPressandhold: {
                        //openProductImageAtIndex(index)
                        //searchResults.currentIndex=index;
                        //productMenu.open();
                        popupProductImageAtIndex(index);
                    }

                    onReleased: {
                        popupProductImageClose();
                    }

                    Menu {
                        id: productMenu
                        title: qsTr("Product")
                        modal: true
                        dim: true
                        x: parent.width/3
                        MenuItem {
                            text: qsTr("View images")
                            onClicked: {
                                openProductImageAtIndex(index)
                            }
                        }

                        MenuItem {
                            text: qsTr("Add to cart")
                            onClicked: {
                                addProductAtIndexToCart(index);
                            }
                        }
                    }

                    function addProductAtIndexToCart(index) {
                        var p=searchPage.model.get(index);
                        cartModel.appendProduct(p.barcode);
                    }

                    function openProductAtIndex(index) {
                        var p=searchPage.model.get(index);
                        searchResults.currentIndex=index;
                        rootStack.push(productView, { "product": p })
                    }

                    function openProductImageAtIndex(index) {
                        var p=searchPage.model.get(index);
                        searchResults.currentIndex=index;
                        rootStack.push(imageDisplayPageComponent, { image: p.thumbnail })
                    }

                    function popupProductImageAtIndex(index) {
                        var p=searchPage.model.get(index);
                        imagePopup.open();
                        imagePopup.source=p.thumbnail;
                    }

                    function popupProductImageClose() {
                        imagePopup.close();
                        imagePopup.source='';
                    }

                }
            }

            function maybeTriggerLoadMore() {
                var rt=false;
                var h=(contentHeight-height)
                if (h>0 && scrollingDown) {
                    var r=contentY/h
                    if (r>0.8)
                        rt=true;
                }

                if ((rt || atYEnd) && api.hasMore && !api.busy) {
                    console.debug("*** Near end, requesting more")
                    requestLoadMore(searchString, categorySearchID);
                    //searchResults.positionViewAtEnd();
                }
            }

            property bool scrollingDown: false

            onVerticalVelocityChanged: {
                if (verticalVelocity!=0)
                    scrollingDown=verticalVelocity>0;
            }

            onMovementEnded: {
                maybeTriggerLoadMore();
            }

            ScrollIndicator.vertical: ScrollIndicator { }

            Component {
                id: listFooter
                RowLayout {
                    Text {
                        id: name
                        Layout.fillWidth: true
                        visible: !api.busy && !api.hasMore && searchResults.count>1
                        text: qsTr("No more items.")
                        font.italic: true
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 16
                    }
                }
            }
        }
    }

    Popup {
        id: imagePopup
        padding: 0
        closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape
        modal: true
        bottomMargin: 32
        topMargin: 32
        leftMargin: 32
        rightMargin: 32

        property alias source: popupImage.source

        enter: Transition {
            NumberAnimation { property: "opacity"; duration: 200; easing.type: Easing.InQuad; from: 0.0; to: 1.0 }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; duration: 200; easing.type: Easing.OutQuad; from: 1.0; to: 0.0 }
        }

        //Behavior on x { NumberAnimation {} }
        //Behavior on y { NumberAnimation {} }
        Behavior on width { NumberAnimation {} }
        Behavior on height { NumberAnimation {} }

        Image {
            id: popupImage
            fillMode: Image.PreserveAspectFit
            anchors.fill: parent
            asynchronous: true
            cache: true
            smooth: true
            sourceSize.width: searchPage.width-64
            sourceSize.height: searchPage.height-64

            onStatusChanged: {
                if (popupImage.status==Image.Ready) {
                    // imagePopup.width=popupImage.paintedWidth
                    imagePopup.height=popupImage.paintedHeight
                    imagePopup.y=searchPage.height/2 // -imagePopup.height/2
                }
            }

            MouseArea {
                anchors.fill: parent
                onReleased: imagePopup.close()
            }
            ProgressBar {
                width: popupImage.width/2
                anchors.centerIn: parent
                visible: popupImage.status==Image.Loading
                value: popupImage.progress
            }
        }

        onOpened: {
            console.debug("popped")
        }

        onClosed: {
            imagePopup.height=undefined;

        }
    }

    Drawer {
        id: searchDrawer
        //parent: mainContainer
        edge: Qt.TopEdge
        interactive: visible
        height: searchDrawerContainer.height //parent.height/2
        width: parent.width
        ColumnLayout {
            id: searchDrawerContainer
            //anchors.fill: parent
            //width: parent.width
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 4
            RowLayout {
                TextField {
                    id: searchText
                    placeholderText: qsTr("Type search string here")
                    maximumLength: 64
                    Layout.fillWidth: true
                    focus: true
                    enabled: !searchActive

                    property bool validInput: length>0;

                    onAccepted: {
                        searchDrawerContainer.activateSearch();
                    }
                    onLengthChanged: {
                        if (length==0)
                            isInitialView=true;
                    }

                    Component.onCompleted: {
                        searchText.text=searchString
                    }
                }
                RoundButton {
                    text: "Clear"
                    onClicked: {
                        searchDrawerContainer.resetSearch();
                    }
                }
            }

            function activateSearch() {
                if (!searchText.validInput)
                    return false;

                searchString=searchText.text.trim()

                if (searchString.length==0)
                    return false;

                if (api.validateBarcode(searchString))
                    searchBarcodeRequested(searchString);
                else
                    searchRequested(searchString, categorySearchID);
            }

            function resetSearch() {
                searchText.text=''
                categorySelection.currentIndex=0;
            }

            ComboBox {
                id: categorySelection
                currentIndex: -1
                Layout.fillWidth: true
                textRole: "category"

                property string currentID: ''

                onActivated: {
                    var cdata=model.get(index);
                    categorySearchID=cdata.cid;

                    if (currentID==categorySearchID)
                        return;

                    currentID=categorySearchID                    
                }
                onCurrentIndexChanged: console.debug("Category currentIndex: "+currentIndex)
                onModelChanged: console.debug("Categories available: "+model.count)
                Component.onCompleted: {
                    model=root.api.getCategoryModel();
                    currentIndex=0;
                }
            }

            ColumnLayout {
                //enabled: false
                Layout.fillWidth: true
                ButtonGroup {
                    id: sortButtonGroup
                }

                Label {
                    text: qsTr("Sort order")
                }

                RadioButton {
                    id: sortButtonLatest
                    checked: true
                    text: qsTr("Latest first")
                    ButtonGroup.group: sortButtonGroup                    
                }
                RadioButton {
                    id: sortButtonOldest
                    text: qsTr("Oldest first")
                    ButtonGroup.group: sortButtonGroup
                }
            }

            RowLayout {
                RoundButton {                    
                    text: qsTr("Scan")
                    icon.source: "qrc:/images/icon_camera.png"
                    onClicked: {
                        searchDrawer.close()
                        rootStack.push(cameraScanner);
                    }
                }
                RoundButton {
                    // XXX: Icon!
                    text: qsTr("Clear")
                    onClicked: {
                        searchDrawerContainer.resetSearch();
                        searchRequested('', '');
                        searchDrawer.close()
                    }
                }
                RoundButton {
                    text: qsTr("Search")
                    icon.source: "qrc:/images/icon_search.png"
                    Layout.alignment: Qt.AlignRight
                    onClicked: {
                        searchDrawerContainer.activateSearch();
                        //searchDrawer.close()
                    }
                }
                RoundButton {
                    icon.source: "qrc:/images/icon_cancel.png"
                    Layout.alignment: Qt.AlignRight
                    onClicked: {
                        searchDrawer.close()
                    }
                }
            }
        }
    }

    Component {
        id: productView
        PageProductView {

        }
    }

    RowLayout {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 16
        anchors.bottomMargin: 16
        height: 48        
        RoundButton {
            id: buttonUp
            text: qsTr("Up")
            icon.source: "qrc:/images/icon_up.png"
            property bool maybeVisible: searchResults.model && searchResults.model.count>10 && !searchResults.atYBeginning
            visible: maybeVisible
            opacity: maybeVisible ? 1 : 0;
            onClicked: {
                searchResults.positionViewAtBeginning();
            }
        }
        RoundButton {
            id: buttonDown
            text: qsTr("Down")
            icon.source: "qrc:/images/icon_down.png"
            property bool maybeVisible: searchResults.model && searchResults.model.count>10 && !searchResults.atYEnd            
            visible: maybeVisible
            opacity: maybeVisible ? 1 : 0;
            onClicked: {
                searchResults.positionViewAtEnd();
                searchResults.maybeTriggerLoadMore();
            }
        }
    }        

    BusyIndicator {
        id: busyIndicator
        anchors.centerIn: mainContainer
        running: api.busy
        visible: running
        width: 64
        height: 64
    }
}
