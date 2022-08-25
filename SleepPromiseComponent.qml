import QtQuick 2.15

Component {
    id: sleepComponent

    Timer {
        property var context
        property var resolve
        property var reject
        property bool contextAborting: context ? context.aborting : false

        running: true
        repeat: false

        onTriggered: {
            if (context && context.aborted) {
                return;
            }

            stop();
            resolve();
            Qt.callLater(destroy);
        }

        onContextAbortingChanged: {
            if (contextAborting) {
                if (running) {
                    stop();
                    context.finishAbort(reject);
                    Qt.callLater(destroy);
                }
            }
        }
    }
}
