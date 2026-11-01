import QtQuick
import QtQuick.Window

// Road Fighter — QML port of kaiwalyakhasnis/Road-Fighter-Compose.
// Mechanics mirror the Compose original:
//  - the road scrolls one full screen per "speed" ms (level table below),
//  - the blue car rides the same loop and re-enters at a random x (120..250),
//  - steering moves the player in 20 px steps (on-screen buttons or arrow keys),
//  - touching the grass strips or the blue car ends the game,
//  - passing the blue car scores 1; every 25 points raises the level
//    (faster scroll, side strips tinted blue / light red on some levels).
// Extra: "--demo" on the command line enables an autopilot for recordings.
Window {
    id: win
    width: 480
    height: 1024
    visible: true
    color: "black"
    title: "Road Fighter (QML)"

    readonly property bool demoMode: Qt.application.arguments.indexOf("--demo") >= 0

    // level table from LevelsState.kt: [speedMs, sideTint]
    readonly property var levelData: [
        [1500, "transparent"],
        [1400, "#2440FF"],
        [1300, "#F08080"],
        [1200, "transparent"],
        [1000, "#2440FF"],
        [750,  "#F08080"]
    ]

    property real phase: 0            // 0..1 game loop, like the Compose animation value
    property int score: 0
    property int level: 1
    property bool running: true
    property bool counted: false      // blue car already scored this pass
    property real blueX: 170
    property real playerOffset: 0     // px from centre, like GameControllerState.playerOffset

    readonly property int speedMs: levelData[Math.min(level, 6) - 1][0]
    readonly property color sideTint: levelData[Math.min(level, 6) - 1][1]
    readonly property real leftW: width * 0.25        // weights 1 : 2.5 : 0.5
    readonly property real centerW: width * 0.625
    readonly property real rightW: width * 0.125
    readonly property real carW: 29
    readonly property real carH: 40
    readonly property real playerTop: height * 0.60
    readonly property real playerX: width / 2 + playerOffset - carW / 2
    readonly property real blueY: phase * height

    function restart() {
        score = 0; level = 1; playerOffset = 0; phase = 0; counted = false;
        blueX = 120 + Math.random() * 130;
        running = true;
    }

    function gameOver() {
        running = false;
        if (demoMode) demoRestart.start();
    }

    function step(dir) {  // dir: -1 left, +1 right — 20 px like the Compose reducer
        if (running) playerOffset += dir * 20;
    }

    // ---- game loop -------------------------------------------------------
    Timer {
        interval: 16; running: true; repeat: true
        onTriggered: {
            if (!win.running) return;
            win.phase += 16 / win.speedMs;
            if (win.phase >= 1) {
                win.phase -= 1;
                win.blueX = 120 + Math.random() * 130;   // 120..250 like BlueCar.kt
                win.counted = false;
            }
            // score: blue car's top reaches the player's top
            if (!win.counted && win.blueY >= win.playerTop) {
                win.counted = true;
                win.score += 1;
                if (win.score % 25 === 0) win.level += 1;   // LevelsMiddleware
            }
            // collisions: grass strips
            if (win.playerX < win.leftW || win.playerX + win.carW > win.leftW + win.centerW)
                return win.gameOver();
            // collisions: blue car (AABB overlap)
            if (win.playerX < win.blueX + win.carW && win.playerX + win.carW > win.blueX &&
                win.playerTop < win.blueY + win.carH && win.playerTop + win.carH > win.blueY)
                return win.gameOver();
        }
    }

    // ---- demo autopilot --------------------------------------------------
    Timer {
        interval: 50; repeat: true
        running: win.demoMode && win.running
        onTriggered: {
            var playerC = win.playerX + win.carW / 2;
            var blueC = win.blueX + win.carW / 2;
            var target = win.leftW + win.centerW / 2;         // road centre
            var dy = win.playerTop - win.blueY;               // blue car distance above player
            if (dy > -60 && dy < 340 && Math.abs(blueC - playerC) < 55) {
                target = blueC + (playerC < blueC ? -78 : 78); // dodge sideways
                target = Math.max(win.leftW + win.carW, Math.min(win.leftW + win.centerW - win.carW, target));
            }
            var want = target - win.carW / 2 - win.width / 2;  // target as playerOffset
            var d = want - win.playerOffset;
            win.playerOffset += Math.max(-16, Math.min(16, d));
        }
    }
    Timer { id: demoRestart; interval: 2500; onTriggered: win.restart() }

    // ---- road ------------------------------------------------------------
    Row {
        anchors.fill: parent
        // one strip = two stacked copies of the section image, scrolling down
        Repeater {
            model: [
                { w: win.leftW,  src: "assets/road_left.png",   tint: true },
                { w: win.centerW, src: "assets/road_center.png", tint: false },
                { w: win.rightW, src: "assets/road_right.png",  tint: true }
            ]
            delegate: Item {
                width: modelData.w; height: win.height
                clip: true
                property real off: win.phase * win.height % win.height
                Image {
                    width: parent.width; height: win.height; y: parent.off
                    source: modelData.src; fillMode: Image.Stretch
                }
                Image {
                    width: parent.width; height: win.height; y: parent.off - win.height
                    source: modelData.src; fillMode: Image.Stretch
                }
                Rectangle {  // per-level colour filter on the side sections
                    anchors.fill: parent
                    color: win.sideTint
                    opacity: modelData.tint && win.sideTint != "transparent" ? 0.30 : 0
                }
            }
        }
    }

    // ---- blue (enemy) car -------------------------------------------------
    Car {
        width: win.carW; height: win.carH
        x: win.blueX; y: win.blueY
        bodyColor: "#43B5E8"; baseColor: "#43B5E8"
    }

    // ---- player car --------------------------------------------------------
    Car {
        width: win.carW; height: win.carH
        x: win.playerX; y: win.playerTop
        bodyColor: "#D82800"; baseColor: "#FFFFFF"
        Behavior on x { NumberAnimation { duration: 45 } }
    }

    // ---- dashboard ----------------------------------------------------------
    Rectangle {
        color: "black"
        anchors.top: parent.top; anchors.left: parent.left
        width: dashCol.implicitWidth + 40; height: dashCol.implicitHeight + 12
        Column {
            id: dashCol
            anchors.centerIn: parent
            Text { text: "Score"; color: "white"; font.pixelSize: 20 }
            Text { text: win.score; color: "white"; font.pixelSize: 20 }
            Text { text: "Level"; color: "white"; font.pixelSize: 20 }
            Text { text: win.level; color: "white"; font.pixelSize: 20 }
        }
    }

    // ---- on-screen controls (75 px grey circles, as in GameControls.kt) ----
    Repeater {
        model: [{ dir: -1, left: true }, { dir: 1, left: false }]
        delegate: Rectangle {
            width: 75; height: 75; radius: 37.5
            color: "#808080"; border.color: "black"; border.width: 1
            anchors.bottom: parent.bottom; anchors.bottomMargin: 100
            anchors.left: modelData.left ? parent.left : undefined
            anchors.right: modelData.left ? undefined : parent.right
            anchors.leftMargin: 10; anchors.rightMargin: 10
            Text {
                anchors.centerIn: parent
                text: modelData.dir < 0 ? "❮" : "❯"
                font.pixelSize: 44; color: "black"
            }
            MouseArea { anchors.fill: parent; onClicked: win.step(modelData.dir) }
        }
    }

    // ---- game over ---------------------------------------------------------
    Rectangle {
        anchors.fill: parent; color: "black"
        visible: !win.running
        Text {
            anchors.centerIn: parent
            text: "Game Over \n Score " + win.score + " \n\n\n Tap anywhere to restart"
            color: "white"; font.pixelSize: 32; horizontalAlignment: Text.AlignHCenter
        }
        MouseArea { anchors.fill: parent; onClicked: win.restart() }
    }

    // ---- keyboard ------------------------------------------------------------
    Item {
        focus: true
        Keys.onLeftPressed: win.step(-1)
        Keys.onRightPressed: win.step(1)
        Keys.onPressed: function (event) {
            if (!win.running && (event.key === Qt.Key_R || event.key === Qt.Key_Space)) win.restart();
        }
        Component.onCompleted: forceActiveFocus()
    }
}
