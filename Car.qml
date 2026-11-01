import QtQuick

// A top-down pixel-art car, drawn with the exact path data from the original
// Android vector drawables (player_car.xml / blue_car.xml, viewport 390x538).
// Only the two body-coloured paths differ between the player and the blue car.
Canvas {
    id: car
    property color bodyColor: "#D82800"
    // Player body base is white; the blue car's base uses its body colour.
    property color baseColor: "#FFFFFF"

    // [fill, pathData] — "BODY" is replaced by bodyColor, "BASE" by baseColor.
    readonly property var paths: [
        ["BASE", "M72,29L198,29L198,60L229,60L229,92L261,92L261,532L229,532L229,501L41,501L41,532L9,532L9,92L41,92L41,60L72,60ZM41,123L41,375L72,375L72,406L198,406L198,375L229,375L229,186L198,186L198,155L72,155L72,123ZM41,438L41,469L103,469L103,438ZM166,438L166,469L229,469L229,438Z"],
        ["#000000", "M229,60L292,60L292,92L324,92L324,218L355,218L355,249L387,249L387,375L355,375L355,406L324,406L324,501L355,501L355,532L261,532L261,92L229,92Z"],
        ["#000000", "M72,155L198,155L198,186L229,186L229,375L198,375L198,406L72,406L72,375L41,375L41,343L72,343L72,312L41,312L41,218L72,218ZM72,249L72,312L103,312L103,343L198,343L198,249Z"],
        ["BODY", "M103,249L198,249L198,343L103,343Z"],
        ["#000000", "M41,501L229,501L229,532L41,532Z"],
        ["#FCFCFC", "M41,123L72,123L72,218L41,218Z"],
        ["#000000", "M166,438L229,438L229,469L166,469Z"],
        ["#FCFCFC", "M72,249L103,249L103,312L72,312Z"],
        ["#000000", "M41,438L103,438L103,469L41,469Z"],
        ["#FCFCFC", "M41,312L72,312L72,343L41,343Z"],
        ["#000000", "M198,29L229,29L229,60L198,60Z"]
    ]

    // The path data uses only absolute M/L/Z commands, so trace it manually —
    // Qt 6.4's QML Canvas has no Path2D constructor.
    function tracePath(ctx, d) {
        var tokens = d.match(/[MLZ]|-?\d+\.?\d*/g);
        var i = 0, cmd = "";
        ctx.beginPath();
        while (i < tokens.length) {
            var t = tokens[i];
            if (t === "M" || t === "L" || t === "Z") {
                cmd = t; i++;
                if (cmd === "Z") ctx.closePath();
                continue;
            }
            var x = parseFloat(tokens[i]), y = parseFloat(tokens[i + 1]);
            i += 2;
            if (cmd === "M") { ctx.moveTo(x, y); cmd = "L"; }
            else ctx.lineTo(x, y);
        }
    }

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.scale(width / 390, height / 538);
        for (var i = 0; i < paths.length; i++) {
            var fill = paths[i][0];
            if (fill === "BODY") fill = bodyColor;
            else if (fill === "BASE") fill = baseColor;
            tracePath(ctx, paths[i][1]);
            ctx.fillStyle = fill;
            ctx.fill();
        }
    }
    onBodyColorChanged: requestPaint()
    onBaseColorChanged: requestPaint()
}
