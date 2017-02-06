import QtQuick 2.0

Item {
    id: igs

    signal fileSelected(string src);

    function startSelector() {
        android.imagePicker();
    }

    Connections {
        target: android
        onImagePicked: {
            console.debug(src);
            fileSelected(src);
        }
    }
}
