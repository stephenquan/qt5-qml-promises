import QtQuick 2.15

Component {
    id: sleepComponent

    Timer {
        property var resolve
        property var reject
        property double startTime: Date.now()
        property double userAbortTime: 0
        property bool userAborting: userAbortTime > startTime
        property bool userAborted: false

        running: true
        repeat: false

        onTriggered: {
            if (userAborted) {
                return;
            }

            stop();
            resolve();
            Qt.callLater(destroy);
        }

        onUserAbortingChanged: {
            if (userAborting) {
                if (running) {
                    userAborted = true;
                    stop();
                    reject(new Error("User Abort"));
                    Qt.callLater(destroy);
                }
            }
        }
    }
}
