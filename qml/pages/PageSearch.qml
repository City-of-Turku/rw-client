/**
 * Product list view page
 *
 * Displays a list of products, can be used for both searching and browsing
 *
 */
import QtQuick 2.12
import QtQml 2.2
import QtQuick.Controls 2.12
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

    signal searchRequested(string str, string category, int sort);
    signal searchBarcodeRequested(string barcode);
    signal searchCancel();

    signal requestLoadMore();

    property bool searchVisible: true

    property string categorySearchID: '';
    property string searchString: ''
    property int sortOrder: ServerApi.SortDateDesc

    //onSearchStringChanged: console.debug("SearchString: "+searchString)
    //onCategorySearchIDChanged: console.debug("SearchCategory: "+categorySearchID)
    //onSortOrderChanged: console.debug("SearchSort: "+sortOrder)

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

    function resetSearch() {
        searchDrawerContainer.resetSearch();
        searchRequested('', '', sortOrder);
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
            searchResults.flick(0, -searchResults.maximumFlickVelocity)
            event.accepted=true;
            break;
        case Qt.Key_PageDown:
            searchResults.flick(0, -searchResults.maximumFlickVelocity)
            event.accepted=true;
            break;
        case Qt.Key_PageUp:
            searchResults.flick(0, searchResults.maximumFlickVelocity)
            event.accepted=true;
            break;
        case Qt.Key_S:
            searchDrawer.open()
            event.accepted=true;
            break;
        }
    }

    Component.onCompleted: {
        model=root.api.getItemModel();
        searchResults.currentIndex=-1;
        if (searchString.length>0) {
            console.debug("Created with pre-populated search string: "+searchString)
            if (api.validateBarcode(searchString))
                searchBarcodeRequested(searchString);
            else
                searchRequested(searchString, '', sortOrder)
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
                //text: searchResults.rowItems==1 ? qsTr("Grid") : qsTr("List")
                icon.source: searchResults.rowItems!=1 ? "qrc:/images/icon_grid.png" : "qrc:/images/icon_list.png"
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
                //text: qsTr("Sort")
                icon.source: sortOrder==ServerApi.SortDateDesc ? "qrc:/images/icon_sort_asc.png" : "qrc:/images/icon_sort_desc.png"
                onClicked: {
                    sortOrder=sortOrder==ServerApi.SortDateDesc ? ServerApi.SortDateAsc : ServerApi.SortDateDesc;
                    searchRequested('', '', sortOrder);
                }
            }
            ToolButton {
                id: tbRefresh
                //text: qsTr("Refresh")
                icon.source: "qrc:/images/icon_refresh.png"
                onClicked: {
                    searchRequested('', '', sortOrder);
                }
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
            visible: searchResults.count==0 && !searchVisible && !isInitialView && !api.busy
            text: qsTr("No products available in selected category")
            wrapMode: Text.Wrap
            font.pixelSize: 32
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }

        Label {
            visible: searchResults.count==0 && searchString.length!=0 && !searchActive && !isInitialView && !api.busy
            text: qsTr("No products found")
            wrapMode: Text.Wrap
            font.pixelSize: 32
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }

        Label {
            visible: searchResults.count==0 && isInitialView && !api.busy
            text: qsTr("No products available")
            wrapMode: Text.Wrap
            font.pixelSize: 32
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }

        Component {
            id: imageDisplayPageComponent
            PageImageDisplay {

            }
        }

        GridView {
            id: searchResults
            enabled: !searchActive
            // Note: We open the popup from a press'n'hold, if don't disable then the list will continue scrolling in the bg
            interactive: !imagePopup.opened
            //interactive: true
            clip: true
            Layout.fillWidth: true
            Layout.fillHeight: true
            footer: listFooter;
            highlightFollowsCurrentItem: true
            //spacing: 4
            currentIndex: -1;
            cellWidth: model.count>1 ? cellSize : searchResults.width
            cellHeight: model.count>1 ? cellSize : searchResults.width

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
                        productMenu.popup();
                    }

                    onClickedImage: {
                        openProductAtIndex(index)
                    }

                    onPressandhold: {
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
                        MenuItem {
                            text: qsTr("View image")
                            onClicked: {
                                openProductImageAtIndex(index)
                            }
                        }
                        MenuItem {
                            text: qsTr("View product")
                            onClicked: {
                                openProductAtIndex(index)
                            }
                        }
                        MenuItem {
                            text: qsTr("Add to cart")
                            enabled: searchPage.model.get(index).stock>0
                            onClicked: {
                                addProductAtIndexToCart(index);
                            }
                        }
                    }

                    function addProductAtIndexToCart(index) {
                        var p=searchPage.model.get(index);
                        if (!api.addToCart(p.barcode, 1)) {

                        }
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
                        imagePopup.showPopupImage(p.title, p.thumbnail)
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
                    requestLoadMore();
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
        property alias title: popupTitle.text

        function showPopupImage(t, s) {
            console.debug("PopupImage: "+s)
            popupTitle.text=t;
            popupImage.source=s;
            imagePopup.open();
        }

        enter: Transition {
            NumberAnimation { property: "opacity"; duration: 200; easing.type: Easing.InQuad; from: 0.0; to: 1.0 }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; duration: 200; easing.type: Easing.OutQuad; from: 1.0; to: 0.0 }
        }

        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)

        ColumnLayout {
            anchors.fill: parent

            Text {
                id: popupTitle
                Layout.fillWidth: true
                text: productTitle
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 18
                elide: Text.ElideMiddle
            }

            Image {
                id: popupImage
                //anchors.fill: parent
                Layout.fillWidth: true
                asynchronous: true
                cache: false
                smooth: true
                sourceSize.width: searchPage.width-64
                sourceSize.height: searchPage.height-64

                property double ratio: width/height

                onStatusChanged: {
                    console.debug("popupImage:"+status)
                    switch (status) {
                    case Image.Ready:
                        console.debug("Loaded")
                        imagePopup.y=searchPage.height/2-imagePopup.height/2
                        break;
                    case Image.Error:
                        console.debug("Failed to load")
                        //imagePopup.close();
                        break;
                    case Image.Loading:
                        console.debug("Loading")
                        break;
                    }

                }

                MouseArea {
                    anchors.fill: parent
                    onReleased: imagePopup.close()
                }
                ProgressBar {
                    width: popupImage.width/2
                    height: 64
                    anchors.centerIn: parent
                    visible: popupImage.status==Image.Loading
                    value: popupImage.progress
                }
            }

        }

        onOpened: {
            console.debug("popped")
            forceActiveFocus();
        }

        onClosed: {
            popupImage.source='';
        }
    }

    Drawer {
        id: searchDrawer
        //parent: mainContainer
        edge: Qt.TopEdge
        interactive: visible
        height: searchDrawerContainer.height //parent.height/2
        width: parent.width

        onOpened: {
            searchText.forceActiveFocus();
        }

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
                    enabled: !api.busy
                    inputMethodHints: Qt.ImhNoPredictiveText;

                    property bool validInput: length>0 && text.trim()!='';

                    onAccepted: {
                        if (searchDrawerContainer.activateSearch())
                            searchDrawer.close()
                    }
                    onLengthChanged: {
                        if (length==0)
                            isInitialView=true;
                    }

                    onTextChanged: searchString=text;

                    Component.onCompleted: {
                        searchText.text=searchString
                    }
                }
                RoundButton {
                    text: qsTr("Clear")
                    enabled: searchText.length>0
                    onClicked: {
                        searchDrawerContainer.resetSearch();
                        searchText.forceActiveFocus();
                    }
                }
            }

            property bool validSearchCriterias: categorySearchID!='' || searchText.validInput

            onValidSearchCriteriasChanged: console.debug("CanSearch: "+validSearchCriterias)

            function activateSearch() {
                if (!validSearchCriterias) {
                    return false;
                }

                console.debug("A: "+searchString)
                if (api.validateBarcode(searchString))
                    searchBarcodeRequested(searchString);
                else
                    searchRequested(searchString, categorySearchID, sortOrder);
                return true;
            }

            function resetSearch() {
                searchText.text=''
                sortOrder=ServerApi.SortDateDesc
                categorySelection.currentIndex=0;
            }

            ComboBox {
                id: categorySelection
                currentIndex: -1
                Layout.fillWidth: true
                textRole: "category"
                onActivated: {
                    var cdata=model.get(index);
                    categorySearchID=cdata.cid;
                }
                // XXX visible: model.count>0 ? true : false;
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
                    onClicked: {
                        console.debug("SortOrder: "+sortOrder)
                    }
                }

                Label {
                    text: qsTr("Sort order")
                }

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.alignment: Qt.AlignTop
                        RadioButton {
                            id: sortButtonLatest
                            checked: true
                            text: qsTr("Latest first")
                            ButtonGroup.group: sortButtonGroup
                            onClicked: sortOrder=ServerApi.SortDateDesc
                        }
                        RadioButton {
                            id: sortButtonOldest
                            text: qsTr("Oldest first")
                            ButtonGroup.group: sortButtonGroup
                            onClicked: sortOrder=ServerApi.SortDateAsc
                        }
                    }
                    ColumnLayout {
                        Layout.alignment: Qt.AlignTop
                        RadioButton {
                            id: sortButtonTitleAsc
                            text: qsTr("Title A-Z")
                            ButtonGroup.group: sortButtonGroup
                            onClicked: sortOrder=ServerApi.SortTitleAsc
                        }
                        RadioButton {
                            id: sortButtonTitleDesc
                            text: qsTr("Title Z-A")
                            ButtonGroup.group: sortButtonGroup
                            onClicked: sortOrder=ServerApi.SortTitleDesc
                        }
                    }
                    ColumnLayout {
                        Layout.alignment: Qt.AlignTop
                        visible: false
                        RadioButton {
                            id: sortButtonPriceDesc
                            text: qsTr("Price high-low")
                            ButtonGroup.group: sortButtonGroup
                            onClicked: sortOrder=ServerApi.SortPriceDesc
                        }
                        RadioButton {
                            id: sortButtonPriceAsc
                            text: qsTr("Price low-high")
                            ButtonGroup.group: sortButtonGroup
                            onClicked: sortOrder=ServerApi.SortPriceAsc
                        }
                    }
                }
            }

            RowLayout {
                RoundButton {
                    text: qsTr("Search")
                    icon.source: "qrc:/images/icon_search.png"
                    enabled: searchDrawerContainer.validSearchCriterias
                    Layout.alignment: Qt.AlignLeft
                    onClicked: {
                        if (searchDrawerContainer.activateSearch())
                            searchDrawer.close()
                    }
                }
                RoundButton {
                    text: qsTr("Scan")
                    icon.source: "qrc:/images/icon_camera.png"
                    Layout.alignment: Qt.AlignCenter
                    onClicked: {
                        searchDrawer.close()
                        rootStack.push(cameraScanner);
                    }
                }
                RoundButton {
                    // XXX: Icon!
                    text: qsTr("Reset")
                    onClicked: {
                        resetSearch();
                        searchDrawer.close()
                    }
                }

                // XXX: Not really needed
                RoundButton {
                    icon.source: "qrc:/images/icon_cancel.png"
                    visible: false
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
