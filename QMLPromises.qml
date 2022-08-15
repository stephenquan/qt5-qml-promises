pragma Singleton

import QtQuick 2.15

Item {
    QtObject {
        id: internal

        property double userBreakTime: 0
    }

    function userBreak() {
        internal.userBreakTime = Date.now();
    }

    function sleep(interval) {
        return new Promise(function (resolve, reject) {
            try {
                sleepComponent.createObject(null, { interval, resolve, reject } );
            } catch (err) {
                reject(err);
            }
        } );
    }

    function numberAnimation(target, properties, from, to, duration) {
        return new Promise(function (resolve, reject) {
            try {
                numberAnimationComponent.createObject(null, { target, properties, from, to, duration, resolve, reject } );
            } catch (err) {
                reject(err);
            }
        } );
    }

    Component {
        id: sleepComponent
        Timer {
            property var resolve
            property var reject
            property double startTime: Date.now()
            property bool aborting: internal.userBreakTime > startTime

            running: true
            repeat: false

            onTriggered: {
                stop();
                resolve();
                Qt.callLater(destroy);
            }

            onAbortingChanged: {
                if (aborting) {
                    if (running) {
                        stop();
                        reject(new Error("User Break"));
                        Qt.callLater(destroy);
                    }
                }
            }

        }
    }

    Component {
        id: numberAnimationComponent
        NumberAnimation {
            property var resolve
            property var reject
            property double startTime: Date.now()
            property bool aborting: internal.userBreakTime > startTime
            loops: 1
            paused: false
            running: true

            onFinished: {
                stop();
                resolve();
                Qt.callLater(destroy);
            }

            onAbortingChanged: {
                if (aborting) {
                    if (running) {
                        stop();
                        reject(new Error("User Break"));
                        Qt.callLater(destroy);
                    }
                }
            }
        }
    }
}
