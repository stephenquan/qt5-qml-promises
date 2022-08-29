import QtQuick 2.15

Item {
    id: qmlPromises

    property var errorHandler: null
    property bool aborted: false
    readonly property bool running: internal.startTime > internal.finishTime
    readonly property bool aborting: !aborted && (internal.abortTime > internal.startTime)

    QtObject {
        id: internal

        property double abortTime: 0
        property double startTime: 0
        property double finishTime: 0

        function abort(reject) {
            Qt.callLater(function() {
                aborted = true;
                finishTime = Date.now();
                reject(new Error("Abort"));
            } );
        }
    }

    function start() {
        if (running) {
            return Promise.reject(new Error("Already Started"));
        }

        internal.startTime = Date.now();
        aborted = false;
        return Promise.resolve();
    }

    function finish() {
        internal.finishTime = Date.now();
        return Promise.resolve();
    }

    function abort() {
        internal.abortTime = Date.now();
        return Promise.resolve();
    }

    function pass() {
        if (aborting) {
            aborted = true;
            internal.finish();
            return Promise.reject(new Error("Abort"));
        }

        return new Promise(function (resolve, reject) {
            Qt.callLater(resolve);
        } );
    }

    function invoke(promiseComponent, props) {
        return new Promise(function (resolve, reject) {
            let _props = props ?? { };
            _props._resolve = resolve;
            _props._reject = reject;
            _props._abort = internal.abort;
            _props._aborted = Qt.binding( () => aborted );
            _props._aborting = Qt.binding( () => aborting );

            try {
                promiseComponent.createObject(qmlPromises, _props);
            } catch (err) {
                reject(err);
            }
        } );
    }

    function sleep(interval) {
        return invoke(sleepComponent, { interval } );
    }

    function numberAnimation(properties) {
        return invoke(numberAnimationComponent, properties);
    }

    function waitUntil(properties) {
        return invoke(waitUntilComponent, properties);
    }

    function waitUntilFinished() {
        if (!running) {
            return Promise.resolve();
        }

        return waitUntil( {
                             context: null,
                             target: qmlPromises,
                             property: "running",
                             value: false
                         } );
    }

    function abortIfRunning() {
        if (!running) {
            return Promise.resolve();
        }

        return new Promise(function (resolve, reject) {
            abort()
            .then( () => waitUntilFinished() )
            .then( () => resolve() )
            .catch( err => reject(err) )
            ;
        } );
    }

    function fetch(properties) {
        return new Promise(function (resolve, reject) {
            let _prop = Object.assign({}, properties);
            let method = _prop["method"] ?? "GET";
            let url = _prop["url"] ?? "https://www.arcgis.com";
            let body = _prop["body"] ?? null;
            let headers = Object.assign({}, _prop["headers"]);

            let xmlhttp = new XMLHttpRequest();
            xmlhttp.onreadystatechange = function() {
                if (aborted) {
                    return;
                }

                if (xmlhttp.readyState !== XMLHttpRequest.DONE) {
                    return;
                }

                if (aborting) {
                    internal.abort(reject);
                    return;
                }

                let responseJson = null;
                try {
                    responseJson = JSON.parse(xmlhttp.responseText);
                } catch (parseErr) {
                    console.info(xmlhttp.responseText);
                    reject(parseErr);
                }

                let obj = {
                    response: responseJson,
                    responseText: xmlhttp.responseText
                };

                Qt.callLater(resolve, obj);
            };

            let _url = url;
            let payload = null;

            if (body) {
                let query = [ ];
                for (let key in body) {
                    let value = body[key];
                    query.push(key + "=" + encodeURIComponent(value));
                }
                let queryString = query.join("&");
                payload = queryString;

                if (method === "GET") {
                    _url = url + "?" + queryString;
                    payload = null;
                }
            }

            xmlhttp.open(method, _url);

            if (method !== "GET" && payload) {
                headers["Content-type"] = "application/x-www-form-urlencoded";
            }

            if (headers) {
                for (let header in headers) {
                    xmlhttp.setRequestHeader(header, headers[header]);
                }
            }

            if (payload) {
                xmlhttp.send(payload);
            } else {
                xmlhttp.send();
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

    SleepPromiseComponent {
        id: sleepComponent
    }

    NumberAnimationPromiseComponent {
        id: numberAnimationComponent
    }

    WaitUntilPromiseComponent {
        id: waitUntilComponent
    }

    function asyncToGenerator(fn) {
        return _asyncToGenerator( function* () {
            try {
                yield start();
                yield *fn();
                yield finish();
            } catch (err) {
                finish();
                let _errorHandler = errorHandler ?? defaultErrorHandler;
                _errorHandler(err);
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

    function defaultErrorHandler(err) {
        let fileName = err.fileName ?? "";
        let lineNumber = err.lineNumber ?? 1;
        let columnNumber = err.columnNumber ?? 1;
        let message = err.message ?? "";
        console.error(fileName + ":" + lineNumber + ":" + columnNumber + ": " + message);
        throw err;
    }
}
