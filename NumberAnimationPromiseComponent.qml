import QtQuick 2.15

Component {
    id: numberAnimationComponent

    NumberAnimation {
        property var context
        property var resolve
        property var reject
        property bool contextAborting: context ? context.aborting : false

        loops: 1
        paused: false
        running: true

        onFinished: {
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
