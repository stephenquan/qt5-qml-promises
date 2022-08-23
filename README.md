# qt5-qml-promises

Implements JavaScript Promise wrapper for chaining QML events together.

The QMLPromises singleton implements the following methods:

 - QMLPromises.userBreak() - cancel previous running QMLPromises.
 - QMLPromises.sleep(interval) - introduce a pause in the promise chain specified in milliseconds
 - QMLPromises.numberAnimation(target, proprerties, from, to, duration) - change a property from one value to another over a duration specified in milliseconds
 - QMLPromises.grabToImage(item, filePath) - saves a screen grab of an item to file
 - QMLPromises.asyncToGenerator(fn) - transcode async/await syntax to generator/iterator syntax

The following animates an SVG bicycle moving along a square permiter.

```qml
import "qt5-qml-promises"

Page {
    anchors.fill: parent

    footer: Frame {
        Button {
            id: button
            anchors.centerIn: parent
            text: qsTr("Go")

            onClicked: {
                bicycle.x = 100;
                bicycle.y = 300;
                bicycle.rotation = 0;

                // Cancel previously running Promises.

                QMLPromises.userBreak();

                // Bicycle animation.

                QMLPromises.asyncToGenerator( function* () {
                    message.text = qsTr("On your marks!");
                    message.color = "black";
                    messageFrame.background.color = "red";
                    yield QMLPromises.numberAnimation(messageFrame, "opacity", 1.0, 0.0, 1000);
                    message.text = qsTr("Get set!");
                    message.color = "black";
                    messageFrame.background.color = "yellow";
                    yield QMLPromises.numberAnimation(messageFrame, "opacity", 1.0, 0.0, 1000);
                    message.text = qsTr("Go!");
                    message.color = "white";
                    messageFrame.background.color = "green";
                    yield QMLPromises.numberAnimation(messageFrame, "opacity", 1.0, 0.0, 1000);
                    yield QMLPromises.numberAnimation(bicycle, "x", 100, 300, 1000);
                    yield QMLPromises.numberAnimation(bicycle, "rotation", 0, -90, 500);
                    yield QMLPromises.numberAnimation(bicycle, "y", 300, 100, 1000);
                    yield QMLPromises.numberAnimation(bicycle, "rotation", -90, -180, 500);
                    yield QMLPromises.numberAnimation(bicycle, "x", 300, 100, 1000);
                    yield QMLPromises.numberAnimation(bicycle, "rotation", 180, 90, 500);
                    yield QMLPromises.numberAnimation(bicycle, "y", 100, 300, 1000);
                    yield QMLPromises.numberAnimation(bicycle, "rotation", 90, 0, 500);
                } )();
                
                // Capture animation to disk.
                
                QMLPromises.asyncToGenerator( function* () {
                    for (let i = 0; i < 200; i++) {
                        let filePath = "C:/temp/img/screengrab" + String(i).padStart(4, '0') + ".png";
                        yield QMLPromises.sleep(20);
                        yield QMLPromises.grabToImage(body, filePath);
                    }
                } )();

                // Use ffmpeg to combine the above images into an animated gif
                // ffmpeg -y -framerate 10 -i "screengrab%%04d.png"  -vf fps=10,palettegen pal.png
                // ffmpeg -y -framerate 10 -i "screengrab%%04d.png" -i pal.png -lavfi "fps=10 [x]; [x][1:v] paletteuse" out.gif
            }
        }
    }

    Item {
        id: bicycle
        x: 100
        y: 300
        width: 0
        height: 0
        property color color: "blue"

        Button {
            id: bicycleButton
            anchors.centerIn: parent
            background: Item { }
            icon.source: "https://raw.githubusercontent.com/Esri/calcite-ui-icons/master/icons/biking-32.svg"
            icon.width: 64
            icon.height: 64
            icon.color: parent.color
        }
    }

    Frame {
        id: messageFrame
        anchors.centerIn: parent
        opacity: 0.0
        background: Rectangle {
            color: "blue"
            radius: 5
        }
        Text {
            id: message
            color: "black"
        }
    }
}
```

To use QMLPromises QML component in your project consider cloning this repo directly in your project:

    git clone https://github.com/stephenquan/qt5-qml-promises.git
    
or adding it as a submodule:

    git submodule add https://github.com/stephenquan/qt5-qml-promises.git qt5-qml-promises
    git submodule update
