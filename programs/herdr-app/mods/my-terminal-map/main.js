import { View, div, image, svg } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import {
  agents, closeOverlay, focused, hc, home, nextCommand, panes, props, run,
  setShared, settings, shared, spaces, terminals, theme,
} from "herdr";

const NAME = "my-terminal-map";
const DIRECTIONS = {
  h: "left", j: "down", k: "up", l: "right",
  left: "left", down: "down", up: "up", right: "right",
};
// Overview keys that add a terminal (tab) or a workspace, and where it goes.
// Shifted letters may arrive as "A" or "shift-a", so both are listed.
const ADD_KEYS = {
  a: "after", i: "before",
  A: "last", "shift-a": "last",
  I: "first", "shift-i": "first",
  o: "below",
  O: "above", "shift-o": "above",
};
const TILE_WIDTH = 504;
const TILE_HEIGHT = 296;
// Largest preview text size (px); smaller when a terminal is wide or tall.
const PREVIEW_TEXT_MAX = 12;
const OVERVIEW_BACKGROUND = "#000000";
const GAP = 12;
const PADDING = 18;
// Strip at the top of each tile: program, what it's doing, status.
const TILE_HEADER = 26;
// Column on the left with each workspace's name and branch, level with its row.
const LABEL_WIDTH = 170;
const LABEL_COLUMN = PADDING + LABEL_WIDTH + GAP;
// Line above each host's workspaces: "This computer", "maliketh".
const HOST_HEADER = 34;
// Text size of a workspace's name in that column.
const WORKSPACE_NAME_SIZE = 15;
// The full-screen view's "needs you" mark (top-right corner).
const ALERT_WIDTH = 14;
const ALERT_HEIGHT = 8;
// Checks the controller makes (zoom split tabs, show/hide the mark), ms.
const CONTROLLER_CHECK_MS = 400;
// A mark window an earlier version opened; closed once at start.
const OLD_ALERT_ID_KEY = `${NAME}.alert`;
// Summary at the top of the overview, one item per line: agent status on the
// left, the selected terminal's folder and branch on the right.
const TOP_LINE_HEIGHT = 18;
// Room kept free of the selected tile at the top: the summary's usual height.
const TOP_BAR = PADDING + TOP_LINE_HEIGHT * 6;
// How many blocked agents the summary names before "+N more".
const BLOCKED_NAMED = 3;
// Machine connection states are fetched, not live: how often (ms).
const SLOW_REFRESH = 15000;
const ICONS = "mods/workspace-chrome";
const ZOOM = { duration: 100, easing: "ease-in-out" };
const PAN = { duration: 160, easing: "ease-out" };

function mapRows() {
  const byTab = new Map();
  for (const pane of panes()) {
    if (!pane.terminal) continue;
    if (!byTab.has(pane.tab)) byTab.set(pane.tab, []);
    byTab.get(pane.tab).push(pane);
  }

  return spaces().map((space) => ({
    space: space.id,
    name: space.name,
    info: space,
    terminals: space.tabs.flatMap((tab) => byTab.get(tab.id) ?? []),
  })).filter((row) => row.terminals.length);
}

function position(rows, pane, space) {
  for (let row = 0; row < rows.length; row++) {
    const col = rows[row].terminals.findIndex((item) => item.pane === pane);
    if (col >= 0) return { row, col };
  }
  return { row: Math.max(0, rows.findIndex((row) => row.space === space)), col: 0 };
}

function step(rows, at, direction, preferredColumn) {
  const vertical = direction === "up" || direction === "down";
  const delta = direction === "up" || direction === "left" ? -1 : 1;
  const row = at.row + (vertical ? delta : 0);
  if (!rows[row]) return at;
  const col = vertical
    ? Math.min(preferredColumn, rows[row].terminals.length - 1)
    : at.col + delta;
  return rows[row].terminals[col] ? { row, col } : at;
}

function focusedSplit() {
  const current = focused();
  const tab = spaces().find((space) => space.id === current?.space)
    ?.tabs.find((tab) => tab.id === current?.tab);
  return current?.terminal && tab?.panes > 1 && !tab.zoomed ? current.pane : null;
}

function cellStart(index, size) {
  return PADDING + index * (size + GAP);
}

const tileLeft = (col) => LABEL_COLUMN + cellStart(col, TILE_WIDTH) - PADDING;

// Each row's top, with a host header above the first workspace of each host
// (spaces() lists a host's spaces together). `hosts`: where each header goes.
function rowLayout(rows) {
  const tops = [];
  const hosts = [];
  let y = PADDING;
  rows.forEach((row, i) => {
    const machine = row.info.machine ?? null;
    if (i === 0 || machine !== (rows[i - 1].info.machine ?? null)) {
      hosts.push({ machine, top: y });
      y += HOST_HEADER;
    }
    tops.push(y);
    y += TILE_HEIGHT + GAP;
  });
  return { tops, hosts };
}

function renderedRange(offset, viewport, size) {
  const stride = size + GAP;
  const first = Math.floor((offset - PADDING) / stride);
  const last = Math.ceil((offset + viewport - PADDING) / stride);
  // Keep the neighboring tiles drawn while the camera is in motion.
  return { first: Math.max(0, first - 1), end: last + 1 };
}

function plainScreen(text) {
  const lines = text.replace(/\r\n/g, "\n").split("\n");
  if (lines.at(-1) === "") lines.pop();
  return {
    lines,
    columns: Math.max(60, ...lines.map((line) => Array.from(line).length)),
  };
}

function shortPath(cwd) {
  if (!cwd) return "";
  const h = home();
  return cwd === h ? "~" : cwd.startsWith(h + "/") ? "~" + cwd.slice(h.length) : cwd;
}

function duration(ms) {
  const s = Math.max(0, Math.floor(ms / 1000));
  if (s < 60) return `${s}s`;
  if (s < 3600) return `${Math.floor(s / 60)}m`;
  if (s < 86400) return `${Math.floor(s / 3600)}h`;
  return `${Math.floor(s / 86400)}d`;
}

function programIcon(program, size, color) {
  if (!program?.icon) return null;
  return program.tint
    ? svg(program.icon).size(size).flex_none().text_color(color)
    : image(program.icon).w(size).h(size).flex_none();
}

// What the core knows about each terminal: status word, when it changed,
// the agent's own message, its parent. Keyed by address ("t2", "maliketh/t7").
function terminalIndex() {
  return new Map(terminals().map((k) => [k.address, k]));
}

// Herdr's status for a pane (as the agents list and the counts use: "done"
// turns "idle" once seen), except "error", which only the core reports.
// Without a pane (a sub-agent), the core's word.
function statusOf(item, k) {
  const word = typeof k?.status === "string" ? k.status : k?.status?.state;
  if (word === "error" || !item.pane) return word ?? null;
  return item.status ?? null;
}

// Status counts over every agent, and the blocked ones by name.
function summary() {
  const counts = { blocked: 0, working: 0, done: 0, idle: 0 };
  const blocked = [];
  for (const a of agents()) {
    if (a.status in counts) counts[a.status]++;
    if (a.status === "blocked") blocked.push(a);
  }
  return { counts, blocked, total: agents().length };
}

function agentLabel(a) {
  const tab = /^\d+$/.test(a.tab_name) ? `${a.tab_index}` : a.tab_name;
  return `${a.program?.name ?? a.app ?? "agent"} · ${a.space_name}/${tab}`;
}

const FOCUS_GLOW = "#22d3ee";
// The red of "an agent needs you": the corner mark and the glow behind tiles.
const NEEDS_YOU = "#ff2d2d";
// How much stronger the red glow is than the cyan one (1 = the same).
const NEEDS_YOU_GLOW_STRENGTH = 3;

// A glow fading out from a tile's center: cyan behind the selected tile, red
// (stronger by `strength`) behind ones that need you.
function focusShadow(color = FOCUS_GLOW, strength = 1) {
  // Stack translucent circles to fade the color out from the terminal's center.
  const layers = [
    [305, 0.0025], [294, 0.003], [283, 0.0035], [272, 0.004], [261, 0.0045],
    [250, 0.005], [239, 0.0055], [228, 0.006], [217, 0.0065], [206, 0.007], [195, 0.0075],
  ];
  const center = div().relative().size(0).children(layers.map(([radius, opacity]) =>
    div().absolute().left(-radius).top(-radius).size(radius * 2)
      .rounded_full().bg(color).opacity(Math.min(1, opacity * strength)),
  ));
  return div().absolute().left(0).top(0).size_full()
    .flex().items_center().justify_center().child(center);
}

export default class TerminalMap extends View {
  init(options, cx) {
    this.controller = options?.controller ?? props()?.controller;
    this.handle = cx.focus_handle();
    if (this.controller) {
      // An earlier version showed the mark as a separate window: close it.
      const old = shared(OLD_ALERT_ID_KEY);
      if (old) {
        closeOverlay(old);
        setShared(OLD_ALERT_ID_KEY, null);
      }
      // While it draws nothing the floating block is hidden, and a hidden
      // block isn't re-rendered on live changes: check on a timer, and
      // redraw only when the mark should appear or go.
      this.needsYou = summary().counts.blocked > 0;
      cx.timer.every(CONTROLLER_CHECK_MS, (cx) => {
        this.ensureFullTerminal(cx);
        const needsYou = summary().counts.blocked > 0;
        if (needsYou !== this.needsYou) {
          this.needsYou = needsYou;
          cx.notify();
        }
      });
      cx.spawn(async (cx) => {
        for (;;) {
          const command = await nextCommand();
          if (["left", "down", "up", "right"].includes(command)) this.moveTerminal(command);
        }
      });
      return;
    }

    const current = focused();
    this.origin = current?.terminal;
    this.selected = current?.pane ?? panes().find((pane) => this.origin && pane.terminal === this.origin)?.pane;
    this.zoomPhase = this.origin && this.selected ? "waiting" : "done";
    this.screens = new Map();
    // address -> when its status last changed (ms). From `hc get`: the app's
    // terminals() keeps a stale status_ms.
    this.since = new Map();
    this.machineStates = new Map(); // machine name -> "connected" | "asleep" | ...
    this.width = 1080;
    this.height = 680;
    this.handle.focus();
    cx.timer.after(0, () => this.handle.focus());
    cx.timer.after(110, (cx) => this.startZoom(cx));
    cx.timer.every(1600, (cx) => this.refresh(cx));
    // Redraw for the "time in status" counters.
    cx.timer.every(1000, (cx) => cx.notify());
    this.refreshSlow(cx);
    cx.timer.every(SLOW_REFRESH, (cx) => this.refreshSlow(cx));
  }

  // Each machine's connection state (for the host labels).
  refreshSlow(cx) {
    cx.spawn(async (cx) => {
      try {
        const result = await hc(["machine", "ls", "--json"]);
        if (result.code === 0) {
          for (const m of JSON.parse(result.stdout).machines ?? []) this.machineStates.set(m.name, m.state);
        }
      } catch {}
      cx.notify();
    });
  }

  moveTerminal(direction) {
    const rows = mapRows();
    const current = focused();
    const at = position(rows, current?.pane, current?.space);
    const next = step(rows, at, direction, at.col);
    const pane = rows[next.row]?.terminals[next.col]?.pane;
    if (pane && pane !== current?.pane) run("pane.focus", { pane });
  }

  ensureFullTerminal(cx) {
    if (this.zoomPending || !focusedSplit()) return;
    this.zoomPending = true;
    cx.timer.after(0, (cx) => {
      this.zoomPending = false;
      if (shared("layout") !== NAME) return;
      const pane = focusedSplit();
      if (pane) run("pane.zoom", { pane });
      cx.notify();
    });
  }

  // run() applies the command, but spaces()/panes() only show the result a
  // moment later: poll until `find` sees it (up to ~1s).
  waitFor(cx, find, then, tries = 40) {
    const found = find();
    if (found) return then(found);
    if (tries > 0) cx.timer.after(25, (cx) => this.waitFor(cx, find, then, tries - 1));
  }

  // tab.move / space.move take the final position (1 = first). `k` is the
  // anchor's position among the others, so k puts the new one just before
  // it and k + 1 just after it.
  targetIndex(ids, anchor, created, after) {
    const k = ids.filter((id) => id !== created).indexOf(anchor) + 1;
    return after ? k + 1 : k;
  }

  // a / i: new terminal in its own tab, right after / before the selected
  // terminal's tab in the same space; A / I: last / first in that space.
  // Then focused. `where`: "after" | "before" | "last" | "first".
  addTerminal(item, where, cx) {
    const space = item && spaces().find((space) => space.tabs.some((tab) => tab.id === item.tab));
    if (!space) return;

    const before = new Set(space.tabs.map((tab) => tab.id));
    run("tab.new", { space: space.id, ...(item.cwd ? { folder: item.cwd } : {}) });
    this.waitFor(cx, () => {
      const tabs = spaces().find((s) => s.id === space.id)?.tabs ?? [];
      const tab = tabs.find((tab) => !before.has(tab.id));
      const pane = tab && panes().find((pane) => pane.tab === tab.id && pane.terminal);
      return pane && { tabs, tab, pane };
    }, ({ tabs, tab, pane }) => {
      const ids = tabs.map((tab) => tab.id);
      const index = where === "first" ? 1
        : where === "last" ? ids.length
        : this.targetIndex(ids, item.tab, tab.id, where === "after");
      run("tab.move", { id: tab.id, index });
      this.openTerminal(pane);
    });
  }

  // o / O: new workspace right below / above the selected terminal's one.
  addSpace(item, below, cx) {
    const space = item && spaces().find((space) => space.tabs.some((tab) => tab.id === item.tab));
    if (!space) return;

    const before = new Set(spaces().map((space) => space.id));
    run("space.new", {
      machine: space.machine ?? "",
      ...(item.cwd ? { folder: item.cwd } : {}),
    });
    this.waitFor(cx, () => {
      const all = spaces();
      const created = all.find((space) => !before.has(space.id));
      const tabs = new Set(created?.tabs.map((tab) => tab.id));
      const pane = created && panes().find((pane) => tabs.has(pane.tab) && pane.terminal);
      return pane && { all, created, pane };
    }, ({ all, created, pane }) => {
      const ids = all.map((space) => space.id);
      run("space.move", { id: created.id, index: this.targetIndex(ids, space.id, created.id, below) });
      this.openTerminal(pane);
    });
  }

  // x: close the selected terminal; the selection moves to its neighbour.
  closeTerminal(cx) {
    const rows = mapRows();
    const at = position(rows, this.selected, focused()?.space);
    const item = rows[at.row]?.terminals[at.col];
    if (!item) return;

    const row = rows[at.row].terminals;
    const nearRow = rows[at.row + 1] ?? rows[at.row - 1];
    const next = row[at.col + 1] ?? row[at.col - 1]
      ?? nearRow?.terminals[Math.min(at.col, nearRow.terminals.length - 1)];
    this.zoomPhase = "done";
    this.selected = next?.pane;
    run("pane.close", { pane: item.pane });
    if (!next) closeOverlay(props().overlay);
    cx.notify();
  }

  openTerminal(item) {
    closeOverlay(props().overlay);
    if (!item) return;
    if (shared("layout") !== NAME) run("layout.switch", { name: NAME });
    run("pane.focus", { pane: item.pane });
  }

  overviewKey(event, cx) {
    const key = event.keystroke;
    if (key === "escape") {
      closeOverlay(props().overlay);
    } else if (Object.hasOwn(ADD_KEYS, key)) {
      const rows = mapRows();
      const at = position(rows, this.selected, focused()?.space);
      const item = rows[at.row]?.terminals[at.col];
      const where = ADD_KEYS[key];
      if (where === "below" || where === "above") this.addSpace(item, where === "below", cx);
      else this.addTerminal(item, where, cx);
    } else if (key === "x") {
      this.closeTerminal(cx);
    } else if (key === "enter" || Object.hasOwn(DIRECTIONS, key)) {
      const rows = mapRows();
      const at = position(rows, this.selected, focused()?.space);
      if (key === "enter") {
        this.openTerminal(rows[at.row]?.terminals[at.col]);
      } else {
        const preferred = this.preferredColumn ?? at.col;
        this.zoomPhase = "done";
        const direction = DIRECTIONS[key];
        const next = step(rows, at, direction, preferred);
        this.selected = rows[next.row]?.terminals[next.col]?.pane;
        this.preferredColumn = direction === "left" || direction === "right" ? next.col : preferred;
        cx.notify();
      }
    } else {
      return;
    }
    cx.stop_propagation();
  }

  startZoom(cx) {
    if (this.zoomPhase !== "waiting") return;
    this.zoomPhase = "full";
    cx.notify();
    // Submit the full-size frame before changing the native motion targets.
    cx.timer.after(32, (cx) => {
      if (this.zoomPhase !== "full") return;
      this.zoomPhase = "shrinking";
      cx.notify();
      cx.timer.after(ZOOM.duration + 20, (cx) => {
        this.zoomPhase = "done";
        cx.notify();
      });
    });
  }

  async refresh(cx) {
    if (this.refreshing || !this.visible?.length) return;
    this.refreshing = true;
    const visible = this.visible;
    await Promise.all(visible.map(async (address) => {
      hc(["get", address, "--json"]).then((result) => {
        if (result.code === 0) this.since.set(address, JSON.parse(result.stdout).status_ms ?? null);
      }).catch(() => {});
      let screen;
      try {
        const result = await hc(["read", address, "--json", "--lines", "0"]);
        if (result.code !== 0) return;
        screen = plainScreen(JSON.parse(result.stdout).text);
      } catch {
        return;
      }
      this.screens.set(address, screen);
      if (address === this.origin) this.startZoom(cx);
    }));
    this.refreshing = false;
    cx.notify();
    if (this.visible !== visible) cx.timer.after(0, (cx) => this.refresh(cx));
  }

  screenText(screen, width, height, t, maxSize) {
    if (!screen) return div();
    const fontSize = Math.min(maxSize, (width - 19) / (screen.columns * 0.62), (height - 19) / (Math.max(20, screen.lines.length) * 1.24));
    const font = settings().font_family;
    // Each line placed absolutely: in a flex column a short screen's lines
    // were stretched apart or centred instead of starting at the top.
    const lineHeight = fontSize * 1.24;
    return div().relative().flex_none()
      .w(screen.columns * fontSize * 0.62).h(screen.lines.length * lineHeight)
      .font_family(typeof font === "string" && font ? font : "JetBrains Mono")
      .text_color(t.foreground).text_size(fontSize).line_height(1.24) // a multiple of the font size, not px
      .children(screen.lines.map((line, i) => div().absolute().left(0).top(i * lineHeight)
        .h(lineHeight).whitespace_nowrap().child(line || " ")));
  }

  // working: spinner, blocked/error: nothing (the red glow shows it), done:
  // filled square, idle: square outline.
  statusMarker(status, t) {
    if (status === "working") return svg(`${ICONS}/spinner.svg`).size(12).flex_none().text_color(t.working).spin(900);
    // blocked and error: no label; the red glow behind the tile shows them.
    if (status === "done") return div().size(8).flex_none().bg(t.done);
    if (status === "idle") return div().size(8).flex_none().border(1.5).border_color(t.idle ?? t.dim);
    return null;
  }

  tileHeader(item, k, subs, tabs, t) {
    const tab = tabs.get(item.tab);
    const program = item.program;
    const name = tab?.named ? tab.name
      : ((program?.agent || program?.shell) && program.name) || item.title || program?.name || "shell";
    const status = statusOf(item, k);
    const report = k?.report ?? (typeof k?.status === "object" ? k.status : null);
    const doing = report?.msg || (item.title && item.title !== name ? item.title : "");
    const since = this.since.get(item.terminal);
    const subsBlocked = subs.filter((s) => ["blocked", "error"].includes(statusOf({}, s))).length;
    const marker = this.statusMarker(status, t);
    const pic = programIcon(program, 14, t.muted);

    return h_flex().h(TILE_HEADER).flex_none().px(8).gap(6).items_center()
      .text_size(11.5)
      .when(Boolean(pic), (el) => el.child(pic))
      .child(div().flex_none().max_w(170).truncate().font_medium().text_color(t.foreground).child(name))
      .child(div().flex_1().min_w(0).truncate().text_color(t.dim).child(doing))
      .when(subs.length > 0, (el) => el.child(div().flex_none().px(4).text_size(10.5)
        .bg((subsBlocked ? t.blocked : t.dim) + "26").text_color(subsBlocked ? t.blocked : t.muted)
        .child(subsBlocked ? `+${subs.length} · ${subsBlocked}!` : `+${subs.length}`)))
      .when(Boolean(status && since), (el) => el.child(div().flex_none().text_color(t.dim).child(duration(Date.now() - since))))
      .when(Boolean(marker), (el) => el.child(marker));
  }

  preview(item, col, row, selected, ctx, t) {
    const k = ctx.terms.get(item.terminal);
    const subs = ctx.children.get(item.terminal) ?? [];
    // Fixed-size parts placed absolutely in the tile: as flex children the
    // preview drifted down the tile when the screen had few lines.
    const body = div().absolute().left(0).top(TILE_HEADER).w(TILE_WIDTH).h(TILE_HEIGHT - TILE_HEADER)
      .overflow_hidden()
      .child(div().absolute().top(7).left(9)
        .child(this.screenText(this.screens.get(item.terminal), TILE_WIDTH, TILE_HEIGHT - TILE_HEADER, t, PREVIEW_TEXT_MAX)));
    const header = div().absolute().left(0).top(0).w(TILE_WIDTH)
      .child(this.tileHeader(item, k, subs, ctx.tabs, t));

    return div().id(item.pane).absolute()
      .left(tileLeft(col)).top(this.tops[row])
      .w(TILE_WIDTH).h(TILE_HEIGHT).overflow_hidden()
      .bg(t.background).cursor_pointer().on_click(() => this.openTerminal(item))
      .child(body).child(header);
  }

  // Left of its row, level with its tiles: the workspace's name.
  workspaceLabel(workspace, row, selected, t) {
    const LABEL_HEIGHT = 24;

    return v_flex().id(`ws-${workspace.space}`).absolute().left(PADDING)
      .top(this.tops[row] + (TILE_HEIGHT - LABEL_HEIGHT) / 2)
      .w(LABEL_WIDTH).h(LABEL_HEIGHT).gap(3).justify_center()
      .child(div().truncate().font_semibold().text_size(WORKSPACE_NAME_SIZE)
        .text_color(selected ? t.foreground : t.muted).child(workspace.name));
  }

  // Once per host, above its workspaces: icon, name, and its state when
  // not connected.
  hostHeader(host, t) {
    const state = host.machine ? this.machineStates.get(host.machine) : "connected";
    return h_flex().id(`host-${host.machine ?? "local"}`).absolute().left(PADDING).top(host.top)
      .w(this.width - PADDING * 2).h(HOST_HEADER - 8).gap(8).items_center().text_size(12.5)
      .child(svg(`${ICONS}/${host.machine ? "server" : "monitor"}.svg`).size(13).flex_none().text_color(t.muted))
      .child(div().flex_none().font_semibold().text_color(t.muted).child(host.machine ?? "This computer"))
      .when(Boolean(state && state !== "connected"), (el) => el.child(
        div().flex_none().text_color(t.blocked).child(String(state).replace(/_/g, " "))));
  }

  // Left, one per line: "■ 2 needs you", each blocked agent ("Claude ·
  // ws/1", up to BLOCKED_NAMED, then "+N more"), working, done, idle, total.
  summaryLines(t) {
    const { counts, blocked, total } = summary();
    const line = (text, color) => div().h(TOP_LINE_HEIGHT).flex().items_center().whitespace_nowrap()
      .text_color(color).child(text);
    const count = (n, label, color) => line(`${n} ${label}`, n ? color : t.dim);

    return v_flex().id("terminal-map-summary").absolute().left(PADDING).top(PADDING / 2)
      .child(h_flex().h(TOP_LINE_HEIGHT).gap(6).items_center().font_semibold()
        .text_color(counts.blocked ? t.blocked : t.dim)
        .child(div().size(7).bg(counts.blocked ? t.blocked : t.dim))
        .child(`${counts.blocked} needs you`))
      .children(blocked.slice(0, BLOCKED_NAMED).map((a) => line(agentLabel(a), t.blocked).pl(13)))
      .when(blocked.length > BLOCKED_NAMED, (el) => el.child(
        line(`+${blocked.length - BLOCKED_NAMED} more`, t.blocked).pl(13)))
      .child(count(counts.working, "working", t.working))
      .child(count(counts.done, "done", t.done))
      .child(count(counts.idle, "idle", t.muted))
      .child(line(`${total} agents`, t.dim));
  }

  // Right, one per line, right-aligned: the selected terminal's folder, then
  // its branch.
  selectedLines(selectedItem, t) {
    const line = (icon, text) => h_flex().h(TOP_LINE_HEIGHT).gap(5).items_center().justify_end()
      .text_color(t.muted)
      .child(div().max_w(420).truncate().child(text))
      .child(svg(`${ICONS}/${icon}.svg`).size(12).flex_none());

    return v_flex().id("terminal-map-selected").absolute().right(PADDING).top(PADDING / 2).items_end()
      .when(Boolean(selectedItem?.cwd), (el) => el.child(line("folder", shortPath(selectedItem.cwd))))
      .when(Boolean(selectedItem?.branch), (el) => el.child(line("git-branch", selectedItem.branch)));
  }

  // No background: tiles and glows panned up show through it.
  topBar(selectedItem, t) {
    return div().id("terminal-map-top").absolute().left(0).top(0).w_full().h(TOP_BAR).text_size(12)
      .child(this.summaryLines(t))
      .child(this.selectedLines(selectedItem, t));
  }

  zoomingTerminal(at, t) {
    const shrinking = this.zoomPhase === "shrinking";
    const screen = this.screens.get(this.origin);
    const left = tileLeft(at.col) - this.cameraX;
    const top = this.tops[at.row] - this.cameraY;

    return div().id("terminal-map-zoom").absolute()
      .left(shrinking ? left : 0).top(shrinking ? top : 0)
      .w(shrinking ? TILE_WIDTH : this.width).h(shrinking ? TILE_HEIGHT : this.height)
      .transition("left", ZOOM).transition("top", ZOOM)
      .transition("width", ZOOM).transition("height", ZOOM)
      .when(shrinking, (el) => el.child(focusShadow()))
      .child(div().relative().size_full().bg(t.background).overflow_hidden()
        .child(div().id("terminal-map-zoom-full").absolute().top(8).left(8)
          .opacity(shrinking ? 0 : 1).transition("opacity", { duration: 55, easing: "ease-out" })
          .child(this.screenText(screen, this.width, this.height, t, 24)))
        .child(div().id("terminal-map-zoom-preview").absolute().top(TILE_HEADER + 9).left(9)
          .opacity(shrinking ? 1 : 0).transition("opacity", { duration: 70, delay: 25, easing: "ease-out" })
          .child(this.screenText(screen, TILE_WIDTH, TILE_HEIGHT - TILE_HEADER, t, PREVIEW_TEXT_MAX))));
  }

  render(cx) {
    const t = theme();
    if (this.controller) {
      // The floating block in the top-right corner: the red mark while an
      // agent needs you, else nothing (then Herdr hides the block). Herdr's
      // frame around a floating block can't be turned off; the layout makes
      // its border black, so on the black background only the mark shows.
      return this.needsYou
        // Room around the mark, so the frame's rounded corners don't clip it.
        ? div().id("terminal-map-needs-you").p(6).child(div().w(ALERT_WIDTH).h(ALERT_HEIGHT).bg(NEEDS_YOU))
        : div();
    }

    const rows = mapRows();
    const at = position(rows, this.selected, focused()?.space);
    const { tops, hosts } = rowLayout(rows);
    this.tops = tops;
    this.cameraX = tileLeft(at.col) + (TILE_WIDTH - this.width) / 2;
    // Center the selected tile in the area below the top bar.
    this.cameraY = (tops[at.row] ?? PADDING) + (TILE_HEIGHT - (this.height - TOP_BAR)) / 2 - TOP_BAR;

    const ctx = { terms: terminalIndex(), children: new Map(), tabs: new Map() };
    for (const k of ctx.terms.values()) {
      if (!k.parent || k.state !== "live") continue;
      if (!ctx.children.has(k.parent)) ctx.children.set(k.parent, []);
      ctx.children.get(k.parent).push(k);
    }
    for (const space of spaces()) for (const tab of space.tabs) ctx.tabs.set(tab.id, tab);

    const xRange = renderedRange(this.cameraX - LABEL_COLUMN + PADDING, this.width, TILE_WIDTH);
    const tiles = [];
    const glows = [];
    const labels = hosts
      .filter((host) => host.top - this.cameraY > -HOST_HEADER * 2 && host.top - this.cameraY < this.height + HOST_HEADER)
      .map((host) => this.hostHeader(host, t));
    const visible = [];
    for (let row = 0; row < rows.length; row++) {
      const top = tops[row] - this.cameraY;
      // Draw a row's neighbours too, so they're there while the camera pans.
      if (top + TILE_HEIGHT < -TILE_HEIGHT || top > this.height + TILE_HEIGHT) continue;
      const workspace = rows[row];
      labels.push(this.workspaceLabel(workspace, row, row === at.row, t));
      const items = workspace.terminals;
      for (let col = xRange.first; col < Math.min(xRange.end, items.length); col++) {
        const item = items[col];
        const left = tileLeft(col) - this.cameraX;
        tiles.push(this.preview(item, col, row, row === at.row && col === at.col, ctx, t));
        if (["blocked", "error"].includes(statusOf(item, ctx.terms.get(item.terminal)))) {
          glows.push(div().absolute().left(tileLeft(col)).top(tops[row])
            .w(TILE_WIDTH).h(TILE_HEIGHT).child(focusShadow(NEEDS_YOU, NEEDS_YOU_GLOW_STRENGTH)));
        }
        if (left < this.width && left + TILE_WIDTH > 0 && top < this.height && top + TILE_HEIGHT > 0) {
          visible.push(item.terminal);
        }
      }
    }
    if (visible.join("\n") !== this.visible?.join("\n")) {
      this.visible = visible;
      cx.timer.after(0, (cx) => this.refresh(cx));
    }

    const full = this.zoomPhase === "full";
    const shrinking = this.zoomPhase === "shrinking";
    const done = this.zoomPhase === "done";
    const gridElement = div().id("terminal-map-grid").absolute().size_full()
      .left(-this.cameraX).top(-this.cameraY)
      .transition("left", PAN).transition("top", PAN)
      .when(done && rows.length > 0, (el) => el.child(
        div().absolute().left(tileLeft(at.col)).top(tops[at.row])
          .w(TILE_WIDTH).h(TILE_HEIGHT).child(focusShadow()),
      ))
      .when(done, (el) => el.children(glows))
      .children(tiles);
    // Host and workspace labels pan up and down with the grid but stay put
    // sideways, with no background: tiles scrolled left show through them.
    const labelLayer = div().id("terminal-map-workspace-labels").absolute()
      .left(0).top(-this.cameraY).w(this.width).h(this.height)
      .transition("top", PAN).children(labels);
    const overview = div().id("terminal-map-content").relative().size_full()
      .opacity(done || shrinking ? 1 : 0)
      .transition("opacity", { duration: 85, delay: 10, easing: "ease-out" })
      .child(gridElement).child(labelLayer)
      .child(this.topBar(rows[at.row]?.terminals[at.col], t));

    return div().id("terminal-map-overview").relative().size_full().overflow_hidden()
      .when(done || full || shrinking, (el) => el.bg(OVERVIEW_BACKGROUND))
      .track_focus(this.handle)
      .on_key_down((event, cx) => this.overviewKey(event, cx))
      .on_size_change((size, cx) => {
        const zoom = settings().zoom;
        const width = Math.round(size.width / zoom);
        const height = Math.round(size.height / zoom);
        if (width === this.width && height === this.height) return;
        this.width = width;
        this.height = height;
        cx.notify();
      })
      .child(overview)
      .when(rows.length > 0 && (full || shrinking), (el) => el.child(this.zoomingTerminal(at, t)));
  }
}
