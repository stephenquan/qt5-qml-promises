import QtQuick 2.15

Item {
    id: qmlPromises
    property var errorHandler: null
    property var owner: null
    property bool aborted: false
    property double abortTime: 0
    property double startTime: 0
    property double finishTime: 0
    readonly property bool running: startTime > finishTime
    readonly property bool aborting: !aborted && (abortTime > startTime)

    function abort() {
        abortTime = Date.now();
        return Promise.resolve();
    }

    function start() {
        if (running) {
            return Promise.reject(new Error("Already Started"));
        }

        startTime = Date.now();
        aborted = false;
        return Promise.resolve();
    }

    function finish() {
        finishTime = Date.now();
        return Promise.resolve();
    }

    function pass() {
        if (aborting) {
            aborted = true;
            finishTime = Date.now();
            return Promise.reject(new Error("Abort"));
        }

        return new Promise(function (resolve, reject) {
            Qt.callLater(resolve);
        } );
    }

    function finishAbort(reject) {
        aborted = true;
        finishTime = Date.now();
        reject(new Error("Abort"));
    }

    function invoke(promiseComponent, props) {
        return new Promise(function (resolve, reject) {
            let _props = props ?? { };
            if (!("context" in _props)) {
                _props.context = qmlPromises;
            }
            _props.resolve = resolve;
            _props.reject = reject;
            let _owner = owner ?? qmlPromises;

            try {
                promiseComponent.createObject(_owner, _props);
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
            let _prop = properties ?? { };
            let method = _prop["method"] ?? "GET";
            let url = _prop["url"] ?? "https://www.arcgis.com";
            let body = _prop["body"] ?? null;
            let headers = _prop["headers"] ?? null;

            let xmlhttp = new XMLHttpRequest();
            xmlhttp.onreadystatechange = function() {
                if (aborted) {
                    return;
                }

                if (xmlhttp.readyState !== XMLHttpRequest.DONE) {
                    return;
                }

                if (aborting) {
                    finishAbort(reject);
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
