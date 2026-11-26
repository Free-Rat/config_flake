// niri-style workspace overview for Hyprland (Lua config, >= 0.57).
//
// Toggle:  qs -c overview ipc call overview toggle   (bound to SUPER+TAB)
// Keys:    j/k switch workspace, h/l move along the columns, Enter/Esc/SUPER+TAB
//          close (staying there), 1-9/0 jump
// Layout:  a "map" centred on screen: workspaces stacked top to bottom in the
//          same order SUPER+J/K walk them (ws_stack in hyprland.lua), the
//          current one in the middle (size: mapScale).
// Mouse:   wheel walks the map; click a workspace or a window to go there, drag a window onto
//          another workspace to move it, click the empty area to close.

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

ShellRoot {
    id: root

    property bool open: false
    // The monitor the overview was opened on. It stays there for the whole
    // session (including the staged close), even if monitor focus moves.
    property var sessionMonitor: null
    // bumped on every open, so a close step from an earlier session can tell
    // it is outdated
    property int session: 0

    // look (matches the eww notification palette)
    readonly property color bg: "#1e1e2e"
    readonly property color accent: "#f9e2af"
    readonly property color text: "#cdd6f4"
    readonly property color subtext: "#6c7086"
    // workspace cards are this fraction of the screen size (the "map" zoom)
    readonly property real mapScale: 0.5
    readonly property int spacing: 14
    // every overview animation (open, map sliding on j/k); same as ANIM in hyprland.lua
    readonly property int animMs: 25
    // edge blur over the map: how far out (0..1, centre to screen edge) things
    // stay sharp, and how strong the blur gets at the edges
    readonly property real sharpRadius: 0.7
    readonly property int edgeBlur: 48

    // ---- talking to Hyprland ----
    //
    // Hyprland in Lua mode only accepts Lua, and quickshell 0.3.2's
    // Hyprland.dispatch() doesn't reach its Lua dispatcher, so everything goes
    // through hyprctl. Workspace switches call ws_go() (hyprland.lua), which
    // pins the slide direction for named workspaces.

    function dispatch(lua) {
        Quickshell.execDetached(["hyprctl", "dispatch", lua]);
    }

    // Lua string literal: quotes, backslashes and control characters escaped
    function luaStr(s) {
        return '"' + String(s).replace(/[\\"\x00-\x1f\x7f]/g, c => c === "\\" || c === '"' ? "\\" + c : "\\" + String(c.charCodeAt(0)).padStart(3, "0")) + '"';
    }

    // A workspace key is its number, or "name:x" for a named workspace; that is
    // also the selector Hyprland takes.
    function wsKey(ws) {
        return ws.id > 0 ? ws.id : "name:" + ws.name;
    }

    function luaSel(key) {
        return typeof key === "number" ? String(key) : luaStr(key);
    }

    function focusWindowLua(address) {
        return `hl.dispatch(hl.dsp.focus({ window = ${luaStr("address:" + address)} }))`;
    }

    function refresh() {
        Hyprland.refreshMonitors();
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
    }

    // ---- open / close ----
    //
    // While the overlay holds exclusive keyboard focus, Hyprland refuses to focus
    // any window, so its "last focused window" stays the one you opened the
    // overview from. On close it refocuses that window, which slides back to its
    // workspace / scrolls the tape back to its column. So closing is staged:
    //   1. `closing`: contents vanish at once, the surface stays mapped but drops
    //      to on-demand keyboard focus, so window focus is allowed again;
    //   2. run `lua`, which switches workspace and focuses a window that is in
    //      view, making that the "last focused window";
    //   3. unmap once it has run; Hyprland refocuses that window, so nothing moves.
    property bool closing: false
    property string pendingLua: ""

    function show() {
        if (open)
            return;
        session++;
        afterClose.stop();
        closeTimeout.stop();
        pendingLua = "";
        sessionMonitor = Hyprland.focusedMonitor;
        refresh();
        closing = false;
        open = true;
    }

    function closeThen(lua) {
        if (!open)
            return;
        // drop navigation that hasn't started; one in flight lands first (afterClose waits)
        focusQueue = [];
        unlockDelay.stop();
        relockGap.stop();
        refocusAfterClose.stop();
        refreshTimer.stop();
        if (!focusProc.running)
            focusUnlocked = false;
        pendingLua = lua;
        closing = true;
        open = false;
        afterClose.restart();
    }

    // step 2, once the on-demand keyboard focus has reached Hyprland
    Timer {
        id: afterClose
        interval: 30
        onTriggered: {
            if (focusProc.running) {
                restart();
                return;
            }
            if (root.pendingLua === "") {
                root.closing = false;
                return;
            }
            closeProc.session = root.session;
            closeProc.command = ["hyprctl", "eval", root.pendingLua];
            closeProc.running = true;
            root.pendingLua = "";
            closeTimeout.restart();
        }
    }

    // step 3
    Process {
        id: closeProc
        property int session: -1
        onExited: {
            if (session === root.session && !root.open)
                root.closing = false;
        }
    }

    // in case hyprctl never returns
    Timer {
        id: closeTimeout
        interval: 1000
        onTriggered: {
            if (!root.open)
                root.closing = false;
        }
    }

    // Close and stay exactly where j/k/h/l left you: this workspace, this
    // part of the tape.
    function dismiss() {
        const ws = sessionMonitor ? sessionMonitor.activeWorkspace : null;
        const addr = inViewAddress("");
        closeThen(ws ? `ws_go(${luaSel(wsKey(ws))})` + (addr ? "; " + focusWindowLua(addr) : "") : "");
    }

    function toggle() {
        open ? dismiss() : show();
    }

    function goToWorkspace(key) {
        const ws = sessionMonitor ? sessionMonitor.activeWorkspace : null;
        if (ws && wsKey(ws) === key)
            dismiss(); // already there (j/k moved us): keep the tape position too
        else
            closeThen(`ws_go(${luaSel(key)})`);
    }

    // switch workspace first (for the right slide direction), then focus the window
    function goToWindow(key, address) {
        if (!address)
            return goToWorkspace(key);
        closeThen(`ws_go(${luaSel(key)}); ${focusWindowLua(address)}`);
    }

    function moveWindow(address, key) {
        if (!address)
            return;
        dispatch(`hl.dsp.window.move({ workspace = ${luaSel(key)}, window = ${luaStr("address:" + address)}, follow = false })`);
        refreshTimer.restart();
    }

    // Address of a window on screen on the session monitor, to keep focused
    // across a close: tiled before floating; among fully visible ones the
    // focused one, else the leftmost; if none is fully visible (a full-width
    // column scrolled half off), the one closest to the screen centre.
    // `exclude`: address of a window that is going away (just closed).
    function inViewAddress(exclude) {
        const mon = sessionMonitor;
        const ws = mon ? mon.activeWorkspace : null;
        if (!ws)
            return "";
        const monW = mon.width / mon.scale, monH = mon.height / mon.scale;
        let best = null, bestRank = null;
        for (const t of ws.toplevels.values) {
            const o = t.lastIpcObject;
            if (!o || !o.at || !o.size || o.hidden || o.address === exclude)
                continue;
            const l = o.at[0] - mon.x, top = o.at[1] - mon.y;
            const inView = l > -5 && l + o.size[0] < monW + 5 && top > -5 && top + o.size[1] < monH + 5;
            const rank = [o.floating ? 1 : 0, !inView ? 2 : t.activated ? 0 : 1, inView ? l : Math.abs(l + o.size[0] / 2 - monW / 2)];
            const i = rank.findIndex((v, j) => v !== bestRank?.[j]);
            if (!bestRank || (i >= 0 && rank[i] < bestRank[i])) {
                best = o.address;
                bestRank = rank;
            }
        }
        return best || "";
    }

    // ---- moving window focus while the overview is open ----
    //
    // Hyprland refuses window focus while an exclusive-keyboard layer is up, so
    // "focus the next column" would always start from the same window, and a
    // focused fullscreen app would stay pinned over the screen. So for each such
    // action the overlay briefly drops to on-demand keyboard focus, the Lua runs
    // (as SUPER+H/L / SUPER+J/K would), and the overlay takes the keyboard back as
    // soon as hyprctl has returned. Actions are queued so they never overlap.
    property bool focusUnlocked: false
    property var focusQueue: []

    function withWindowFocus(lua) {
        if (!open)
            return;
        focusQueue = focusQueue.concat([lua]);
        if (!focusUnlocked)
            runNextFocusOp();
    }

    function runNextFocusOp() {
        if (focusQueue.length === 0 || !open)
            return;
        focusUnlocked = true;
        focusProc.command = ["hyprctl", "eval", focusQueue[0]];
        focusQueue = focusQueue.slice(1);
        unlockDelay.restart();
    }

    // Best-effort wait for the keyboard-interactivity change to reach Hyprland
    // (nothing tells us when it has); one frame is enough in practice.
    Timer {
        id: unlockDelay
        interval: 16
        onTriggered: {
            if (root.open)
                focusProc.running = true;
            else
                root.focusUnlocked = false;
        }
    }

    Process {
        id: focusProc
        onExited: {
            root.focusUnlocked = false;
            if (!root.open)
                return;
            refreshTimer.restart();
            if (root.focusQueue.length > 0)
                relockGap.restart();
        }
    }

    Timer {
        id: relockGap
        interval: 16
        onTriggered: root.runNextFocusOp()
    }

    // h/l: exactly SUPER+H/L, i.e. move focus along the tape of columns
    function focusColumn(dir) {
        withWindowFocus(`hl.dispatch(hl.dsp.layout("focus ${dir}"))`);
    }

    // ---- keeping the model fresh ----

    // Window positions (lastIpcObject) only update on refresh: refresh shortly
    // after a burst of window/workspace events while open.
    Timer {
        id: refreshTimer
        interval: 120
        onTriggered: root.refresh()
    }

    Connections {
        target: Hyprland
        enabled: root.open
        function onRawEvent(event) {
            if (["openwindow", "closewindow", "movewindow", "movewindowv2", "createworkspace", "destroyworkspace", "changefloatingmode"].includes(event.name))
                refreshTimer.restart();
            if (event.name === "closewindow") {
                root.closedAddress = "0x" + event.data;
                refocusAfterClose.restart();
            }
        }
    }

    property string closedAddress: ""

    // A window closed (e.g. SUPER+Q) while the overview is open. If it was the
    // focused one, Hyprland wants to focus the next window but refuses because
    // the overlay holds the keyboard, so nothing is focused and h/l have nothing
    // to step from: focus a window in view ourselves. A close elsewhere leaves
    // the focus alone. The delay lets the refreshed positions arrive first.
    Timer {
        id: refocusAfterClose
        interval: 250
        onTriggered: {
            const ws = root.sessionMonitor ? root.sessionMonitor.activeWorkspace : null;
            const active = Hyprland.activeToplevel;
            if (!root.open || !ws || (active && active.workspace === ws))
                return;
            const addr = root.inViewAddress(root.closedAddress);
            if (addr)
                root.withWindowFocus(root.focusWindowLua(addr));
        }
    }

    // ---- widget layer data (time, date, battery) ----

    SystemClock {
        id: clock
        enabled: root.open
        precision: SystemClock.Minutes
    }

    // Battery straight from the kernel (no UPower service needed). Stays ""
    // on machines without BAT0, which hides it in the widget layer.
    property string batteryLevel: ""
    // "Charging", "Discharging", "Full" or "Not charging" (plugged in, held)
    property string batteryState: ""

    FileView {
        id: batteryStatus
        path: "/sys/class/power_supply/BAT0/status"
        printErrors: false
        onLoaded: root.batteryState = text().trim()
    }

    FileView {
        id: batteryCapacity
        path: "/sys/class/power_supply/BAT0/capacity"
        printErrors: false
        onLoaded: root.batteryLevel = text().trim()
    }

    // sysfs files can't be watched for changes; re-read while the overview is open
    Timer {
        interval: 30000
        running: root.open
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            batteryCapacity.reload();
            batteryStatus.reload();
        }
    }

    // Nerd Font (Material Design) battery icons, index = level in 10% steps
    readonly property var batteryIconsDischarging: [0xF008E, 0xF007A, 0xF007B, 0xF007C, 0xF007D, 0xF007E, 0xF007F, 0xF0080, 0xF0081, 0xF0082, 0xF0079]
    readonly property var batteryIconsCharging: [0xF089C, 0xF089C, 0xF0086, 0xF0087, 0xF0088, 0xF089D, 0xF0089, 0xF089E, 0xF008A, 0xF008B, 0xF0085]
    readonly property int batteryIconPluggedFull: 0xF0084 // 󰂄

    readonly property string batteryIcon: {
        const level = parseInt(batteryLevel);
        if (isNaN(level))
            return "";
        const step = Math.max(0, Math.min(10, Math.round(level / 10)));
        if (batteryState === "Full" || batteryState === "Not charging")
            return String.fromCodePoint(batteryIconPluggedFull);
        if (batteryState === "Charging")
            return String.fromCodePoint(batteryIconsCharging[step]);
        return String.fromCodePoint(batteryIconsDischarging[step]);
    }

    IpcHandler {
        target: "overview"

        function toggle(): void {
            root.toggle();
        }
        function open(): void {
            root.show();
        }
        function close(): void {
            root.dismiss();
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            screen: modelData

            readonly property var monitor: Hyprland.monitorFor(modelData)
            readonly property bool isSession: monitor !== null && monitor === root.sessionMonitor

            // logical monitor geometry (hyprland reports pixels + scale)
            readonly property real monX: monitor ? monitor.x : 0
            readonly property real monY: monitor ? monitor.y : 0
            readonly property real monW: monitor ? monitor.width / monitor.scale : 1920
            readonly property real monH: monitor ? monitor.height / monitor.scale : 1080

            readonly property real cardW: monW * root.mapScale
            readonly property real cardH: monH * root.mapScale

            // Stays mapped (but empty) during `root.closing`, with on-demand
            // keyboard focus so a window can be focused before it unmaps; see
            // "open / close" above.
            visible: isSession && (root.open || root.closing)
            color: "transparent"
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-overview"
            WlrLayershell.keyboardFocus: root.closing || root.focusUnlocked ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive

            // Everything below only exists while open, so the always-running
            // service holds no delegates, captures or effects in between.
            Loader {
                anchors.fill: parent
                active: win.isSession && root.open
                focus: true

                sourceComponent: Component {
                    Item {
                        id: view

                        // Rows on this monitor, top to bottom: named workspaces
                        // (alphabetical, by code point like Lua's table.sort),
                        // numbered ones, then one empty slot with the first free
                        // number (niri's "always one empty"). Same as ws_stack().
                        readonly property var entries: {
                            const all = Hyprland.workspaces.values.filter(w => w.monitor === win.monitor && !w.name.startsWith("special"));
                            const named = all.filter(w => w.id <= 0).sort((a, b) => a.name < b.name ? -1 : a.name > b.name ? 1 : 0);
                            const numbered = all.filter(w => w.id > 0).sort((a, b) => a.id - b.id);
                            const taken = new Set(Hyprland.workspaces.values.map(w => w.id));
                            let next = numbered.length ? numbered[numbered.length - 1].id + 1 : 1;
                            while (taken.has(next))
                                next++;
                            const list = named.concat(numbered).map(w => ({ ws: w, key: root.wsKey(w) }));
                            list.push({ ws: null, key: next });
                            return list;
                        }

                        // Selection by workspace key, not row index, so it stays on
                        // the same workspace when rows appear or disappear.
                        property var selectedKey: null
                        readonly property int selected: {
                            let i = entries.findIndex(e => e.key === selectedKey);
                            if (i < 0)
                                i = entries.findIndex(e => e.ws !== null && e.ws === win.monitor.activeWorkspace);
                            return Math.max(i, 0);
                        }

                        // jump straight to the current row on open; animate only later j/k moves
                        property bool animateMap: false

                        Timer {
                            interval: 50
                            running: true
                            onTriggered: view.animateMap = true
                        }

                        // j/k move the selection *and* switch the real workspace behind the
                        // overlay, like niri's overview; Enter then just closes.
                        function step(delta) {
                            const i = Math.max(0, Math.min(selected + delta, entries.length - 1));
                            if (i === selected)
                                return;
                            selectedKey = entries[i].key;
                            root.withWindowFocus(`ws_go(${root.luaSel(selectedKey)})`);
                        }

                        function selectActive() {
                            const ws = win.monitor ? win.monitor.activeWorkspace : null;
                            selectedKey = ws ? root.wsKey(ws) : null;
                        }

                        Component.onCompleted: selectActive()

                        // Follow the real active workspace (it can lag a moment behind
                        // on open), but not while j/k moves are still queued: those
                        // already set where the selection is going.
                        Connections {
                            target: win.monitor
                            function onActiveWorkspaceChanged() {
                                if (root.focusQueue.length === 0 && !root.focusUnlocked)
                                    view.selectActive();
                            }
                        }

                        anchors.fill: parent

                        // clicking anywhere outside the cards closes the overview
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.dismiss()
                        }

                        // The "map": a grid with one row per workspace, all at one zoom level
                        // (mapScale) so every row is the same height and every column the same
                        // size. Each row is shifted so its on-screen part is centred, so the
                        // screens of all workspaces line up in the middle and off-screen
                        // columns extend left/right. The current row is centred vertically.
                        Item {
                            id: panel
                            anchors.fill: parent

                            // zoom out into the map on open
                            NumberAnimation on scale {
                                from: 1.08
                                to: 1
                                duration: root.animMs
                                easing.type: Easing.OutCubic
                            }
                            NumberAnimation on opacity {
                                from: 0
                                to: 1
                                duration: root.animMs
                            }

                            // mouse wheel walks the map like j/k (one step per notch)
                            WheelHandler {
                                property real acc: 0
                                onWheel: event => {
                                    acc += event.angleDelta.y;
                                    while (Math.abs(acc) >= 120) {
                                        view.step(acc > 0 ? -1 : 1);
                                        acc -= acc > 0 ? 120 : -120;
                                    }
                                }
                            }

                            Item {
                                id: list
                                anchors.fill: parent

                                focus: true
                                Keys.onPressed: event => {
                                    const k = event.key;
                                    if (k === Qt.Key_Escape || k === Qt.Key_Tab) {
                                        root.dismiss();
                                    } else if (k === Qt.Key_J || k === Qt.Key_Down) {
                                        view.step(1);
                                    } else if (k === Qt.Key_K || k === Qt.Key_Up) {
                                        view.step(-1);
                                    } else if (k === Qt.Key_H || k === Qt.Key_Left) {
                                        root.focusColumn("l");
                                    } else if (k === Qt.Key_L || k === Qt.Key_Right) {
                                        root.focusColumn("r");
                                    } else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) {
                                        const e = view.entries[view.selected];
                                        if (e)
                                            root.goToWorkspace(e.key);
                                    } else if (k >= Qt.Key_0 && k <= Qt.Key_9) {
                                        root.goToWorkspace(k === Qt.Key_0 ? 10 : k - Qt.Key_0);
                                    } else {
                                        return;
                                    }
                                    event.accepted = true;
                                }

                                // Cards stacked top to bottom; the whole column is shifted so the
                                // selected (= current) card's centre sits at the screen's centre.
                                Column {
                                    id: col
                                    width: parent.width
                                    spacing: root.spacing * 2

                                    y: {
                                        // itemAt() doesn't notify; count does once the rows exist
                                        const it = rep.count > view.selected ? rep.itemAt(view.selected) : null;
                                        return it ? list.height / 2 - (it.y + it.height / 2) : 0;
                                    }
                                    Behavior on y {
                                        enabled: view.animateMap
                                        NumberAnimation {
                                            duration: root.animMs
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Repeater {
                                        id: rep
                                        model: view.entries

                                        delegate: Item {
                                            id: entry

                                            required property var modelData
                                            readonly property var ws: modelData.ws

                                            // Left/top edge of the whole scrolling tape (every column,
                                            // also the off-screen ones) united with the on-screen
                                            // viewport, and its width, in monitor-relative logical
                                            // coords; the card spans all of it.
                                            readonly property var bounds: {
                                                let x0 = 0, y0 = 0, x1 = win.monW;
                                                for (const t of ws ? ws.toplevels.values : []) {
                                                    const o = t.lastIpcObject;
                                                    if (!o || !o.at || !o.size || o.hidden)
                                                        continue;
                                                    const x = o.at[0] - win.monX;
                                                    x0 = Math.min(x0, x);
                                                    y0 = Math.min(y0, o.at[1] - win.monY);
                                                    x1 = Math.max(x1, x + o.size[0]);
                                                }
                                                return { x: x0, y: y0, w: x1 - x0 };
                                            }
                                            // where the on-screen viewport starts inside the card
                                            readonly property real offX: -bounds.x * root.mapScale
                                            readonly property real offY: -bounds.y * root.mapScale

                                            // the row spans the screen width; the card inside is placed so
                                            // its viewport is centred horizontally
                                            width: list.width
                                            height: win.cardH

                                            Rectangle {
                                                id: cardRect
                                                x: (entry.width - win.cardW) / 2 - entry.offX
                                                width: entry.ws ? entry.bounds.w * root.mapScale : win.cardW
                                                height: entry.height
                                                // transparent: only the windows show, the blur shows through the gaps
                                                color: "transparent"
                                                radius: 6
                                                clip: true
                                                // no border, except while a dragged window is over it (drop target)
                                                border.width: drop.containsDrag ? 2 : 0
                                                border.color: root.accent

                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: root.goToWorkspace(entry.modelData.key)
                                                }

                                                Text {
                                                    visible: entry.ws === null
                                                    anchors.centerIn: parent
                                                    text: "+"
                                                    color: root.subtext
                                                    font.pixelSize: 32
                                                }

                                                Repeater {
                                                    model: entry.ws ? entry.ws.toplevels.values : []

                                                    delegate: Item {
                                                        id: tile

                                                        required property var modelData
                                                        readonly property var ipc: modelData.lastIpcObject
                                                        readonly property string address: ipc && ipc.address ? ipc.address : ""
                                                        readonly property string appClass: ipc && ipc.class ? ipc.class : ""

                                                        // home position inside the card; restored after a drag
                                                        readonly property real homeX: ipc && ipc.at ? entry.offX + (ipc.at[0] - win.monX) * root.mapScale : 0
                                                        readonly property real homeY: ipc && ipc.at ? entry.offY + (ipc.at[1] - win.monY) * root.mapScale : 0
                                                        x: homeX
                                                        y: homeY
                                                        width: ipc && ipc.size ? Math.max(ipc.size[0] * root.mapScale, 8) : 0
                                                        height: ipc && ipc.size ? Math.max(ipc.size[1] * root.mapScale, 8) : 0
                                                        z: ipc && ipc.floating ? 1 : 0
                                                        visible: !(ipc && ipc.hidden)

                                                        // Only capture tiles on screen, plus one row/card of
                                                        // margin so the next j/k or h/l step is already live.
                                                        readonly property bool nearScreen: {
                                                            const mx = win.cardW, my = win.cardH + root.spacing * 2;
                                                            const sx = cardRect.x + homeX, sy = col.y + entry.y + homeY;
                                                            return sx + width > -mx && sx < view.width + mx && sy + height > -my && sy < view.height + my;
                                                        }

                                                        Drag.active: mouse.drag.active
                                                        Drag.keys: ["window"]
                                                        Drag.hotSpot.x: width / 2
                                                        Drag.hotSpot.y: height / 2

                                                        Rectangle {
                                                            anchors.fill: parent
                                                            // background only behind the icon fallback; with a live
                                                            // preview it would show at the edges and through
                                                            // transparent windows
                                                            color: preview.hasContent ? "transparent" : root.bg

                                                            ScreencopyView {
                                                                id: preview
                                                                anchors.fill: parent
                                                                captureSource: tile.nearScreen || mouse.drag.active ? tile.modelData.wayland : null
                                                                live: true
                                                            }

                                                            // Off-screen columns usually have no capture
                                                            // (nothing renders them), so show icon + title.
                                                            Column {
                                                                visible: !preview.hasContent
                                                                anchors.centerIn: parent
                                                                width: parent.width - 6
                                                                spacing: 3

                                                                Image {
                                                                    readonly property var desktopEntry: tile.appClass ? DesktopEntries.heuristicLookup(tile.appClass) : null
                                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                                    width: Math.min(28, tile.width * 0.5)
                                                                    height: width
                                                                    sourceSize: Qt.size(width * 2, height * 2)
                                                                    source: desktopEntry && desktopEntry.icon ? Quickshell.iconPath(desktopEntry.icon, true) : ""
                                                                    visible: source != ""
                                                                }

                                                                Text {
                                                                    width: parent.width
                                                                    text: tile.modelData.title || tile.appClass
                                                                    color: root.text
                                                                    font.pixelSize: 9
                                                                    elide: Text.ElideRight
                                                                    horizontalAlignment: Text.AlignHCenter
                                                                }
                                                            }
                                                        }

                                                        MouseArea {
                                                            id: mouse
                                                            anchors.fill: parent
                                                            drag.target: tile
                                                            onClicked: root.goToWindow(entry.modelData.key, tile.address)
                                                            onReleased: {
                                                                if (drag.active) {
                                                                    const target = tile.Drag.target;
                                                                    if (target && target.key !== entry.modelData.key)
                                                                        root.moveWindow(tile.address, target.key);
                                                                }
                                                                tile.x = Qt.binding(() => tile.homeX);
                                                                tile.y = Qt.binding(() => tile.homeY);
                                                            }
                                                        }

                                                        // lift the tile out of the clipped card while dragging
                                                        states: State {
                                                            when: mouse.drag.active
                                                            ParentChange {
                                                                target: tile
                                                                parent: dragLayer
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            DropArea {
                                                id: drop
                                                anchors.fill: cardRect
                                                keys: ["window"]
                                                readonly property var key: entry.modelData.key
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Edge blur over the map: the current workspace in the middle stays
                        // sharp, everything further out (other workspaces, off-screen columns)
                        // gets blurrier towards the screen edges. A blurred copy of the cards
                        // is drawn on top of them through an elliptical mask that is
                        // transparent in the middle and opaque at the edges.
                        Item {
                            id: edgeMask
                            anchors.fill: parent
                            visible: false
                            layer.enabled: true
                            // a smooth gradient: a quarter-resolution texture is enough
                            layer.textureSize: Qt.size(width / 4, height / 4)
                            layer.smooth: true

                            // circle in a square, stretched to the screen's aspect = an ellipse
                            // whose radius reaches the middle of each screen edge
                            Shape {
                                width: parent.height
                                height: parent.height
                                anchors.centerIn: parent
                                transform: Scale {
                                    origin.x: edgeMask.height / 2
                                    origin.y: edgeMask.height / 2
                                    xScale: edgeMask.width / Math.max(edgeMask.height, 1)
                                }

                                ShapePath {
                                    strokeWidth: 0
                                    strokeColor: "transparent"
                                    fillGradient: RadialGradient {
                                        centerX: edgeMask.height / 2
                                        centerY: edgeMask.height / 2
                                        focalX: centerX
                                        focalY: centerY
                                        centerRadius: edgeMask.height / 2
                                        focalRadius: 0
                                        // the current card reaches 0.5 (it is mapScale of the screen)
                                        GradientStop { position: root.sharpRadius; color: "transparent" }
                                        GradientStop { position: 1.0; color: "black" }
                                    }
                                    // overdraw past the square so the stretched shape covers the corners
                                    startX: -edgeMask.height
                                    startY: -edgeMask.height
                                    PathLine { x: 2 * edgeMask.height; y: -edgeMask.height }
                                    PathLine { x: 2 * edgeMask.height; y: 2 * edgeMask.height }
                                    PathLine { x: -edgeMask.height; y: 2 * edgeMask.height }
                                    PathLine { x: -edgeMask.height; y: -edgeMask.height }
                                }
                            }
                        }

                        // The blur only shows towards the edges, where a half-resolution
                        // copy of the map looks the same and costs a quarter to blur.
                        ShaderEffectSource {
                            id: blurSource
                            anchors.fill: panel
                            sourceItem: panel
                            visible: false
                            smooth: true
                            textureSize: Qt.size(width / 2, height / 2)
                        }

                        MultiEffect {
                            anchors.fill: panel
                            source: blurSource
                            blurEnabled: true
                            blur: 1.0
                            blurMax: root.edgeBlur
                            autoPaddingEnabled: false
                            maskEnabled: true
                            maskSource: edgeMask
                            // MultiEffect maps mask alpha through smoothstep(min*(1+s)-s, min*(1+s));
                            // min 0.5 with spread 1 makes that smoothstep(0, 1): alpha 0 = sharp
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1.0
                        }

                        // Widget layer: time, date and battery at the top centre, drawn above
                        // the edge blur so it stays sharp. One line, one size.
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 8
                            text: Qt.formatDateTime(clock.date, "HH:mm")
                                + "   ·   " + Qt.formatDateTime(clock.date, "dddd, d MMMM")
                                + (root.batteryLevel !== "" ? `   ·   ${root.batteryIcon} ${root.batteryLevel}%` : "")
                            color: root.text
                            // the NF build of Krypton: same look, plus the Nerd Font icons
                            font.family: "Monaspace Krypton NF"
                            font.pixelSize: 18
                            style: Text.Raised
                            styleColor: "#80000000"
                        }

                        // dragged window tiles are reparented here so they can leave their card
                        Item {
                            id: dragLayer
                            anchors.fill: parent
                            z: 10
                        }
                    }
                }
            }
        }
    }
}
