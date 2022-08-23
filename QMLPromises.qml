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

    function grabToImage(item, filePath) {
        return new Promise(function (resolve, reject) {
            try {
                item.grabToImage(function (result) {
                    try {
                        if (!result.saveToFile(filePath)) {
                            reject(new Error(qStr("grabToImage error: %1").arg(filePath)));
                            return;
                        }
                        resolve(filePath);
                    } catch (saveError) {
                        reject(saveError);
                    }
                } );
            } catch (grabError) {
                reject(grabError);
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
            property bool aborted: false

            running: true
            repeat: false

            onTriggered: {
                if (aborted) {
                    return;
                }

                stop();
                resolve();
                Qt.callLater(destroy);
            }

            onAbortingChanged: {
                if (aborting) {
                    if (running) {
                        aborted = true;
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
            property bool aborted: false
            loops: 1
            paused: false
            running: true

            onFinished: {
                if (aborted) {
                    return;
                }

                stop();
                resolve();
                Qt.callLater(destroy);
            }

            onAbortingChanged: {
                if (aborting) {
                    if (running) {
                        aborted = true;
                        stop();
                        reject(new Error("User Break"));
                        Qt.callLater(destroy);
                    }
                }
            }
        }
    }

    function asyncToGenerator(fn) {
        return _asyncToGenerator( function* () {
            try {
                yield *fn();
            } catch (err) {
                let fileName = err.fileName ?? "";
                let lineNumber = err.lineNumber ?? 1;
                let columnNumber = err.columnNumber ?? 1;
                let message = err.message ?? "";
                console.error(fileName + ":" + lineNumber + ":" + columnNumber + ": " + message);
                throw err;
            }
        } );
    }

    function _asyncToGenerator(fn) {
        return function() {
            var self = this,
            args = arguments
            return new Promise(function(resolve, reject) {
                var gen = fn.apply(self, args)
                function _next(value) {
                    _asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value)
                }
                function _throw(err) {
                    _asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err)
                }
                _next(undefined)
            })
        }
    }

    function _asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) {
        try {
            var info = gen[key](arg)
            var value = info.value
        } catch (error) {
            reject(error)
            return
        }
        if (info.done) {
            resolve(value)
        } else {
            Promise.resolve(value).then(_next, _throw)
        }
    }
}
