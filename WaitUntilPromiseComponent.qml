import QtQuick 2.15

Component {
    QtObject {
        property var context
        property var resolve
        property var reject
        property var target
        property string property
        property var value
        property bool finished: target[property] === value
        property bool contextAborting: context ? context.aborting : false

        onFinishedChanged: {
            if (context && context.aborted) {
                return;
            }

            if (!finished) {
                return;
            }

            resolve();
            Qt.callLater(destroy);
        }

        onContextAbortingChanged: {
            if (contextAborting) {
                if (running) {
                    userAborted = true;
                    stop();
                    context.finishAbort(reject);
                    Qt.callLater(destroy);
                }
            }
        }
    }
}
