import { View, div } from "gpui-kit";
import { v_flex } from "gpui-base";
import {
  closeOverlay, focused, hc, nextCommand, openOverlay, panes, props, run,
  settings, shared, spaces, theme,
} from "herdr";

const NAME = "my-terminal-map";
const DIRECTIONS = {
  h: "left", j: "down", k: "up", l: "right",
  left: "left", down: "down", up: "up", right: "right",
};
const TILE_WIDTH = 420;
const TILE_HEIGHT = 246;
const GAP = 12;
const PADDING = 18;
const FULLSCREEN = { kind: "dialog", width: 1, height: 1, frame: "none" };
const ZOOM = { duration: 290, easing: "ease-in-out" };
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

function cameraOffset(index, size, viewport) {
  return cellStart(index, size) + (size - viewport) / 2;
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

export default class TerminalMap extends View {
  init(options, cx) {
    this.controller = options?.controller ?? props()?.controller;
    this.handle = cx.focus_handle();
    if (this.controller) {
      cx.spawn(async (cx) => {
        for (;;) {
          const command = await nextCommand();
          if (command === "normal") this.enterNormal(cx);
          else if (["left", "down", "up", "right"].includes(command)) this.moveTerminal(command, this.handle.is_focused(), cx);
        }
      });
      return;
    }

    const current = focused();
    this.origin = current?.terminal;
    this.selected = current?.pane ?? panes().find((pane) => this.origin && pane.terminal === this.origin)?.pane;
    this.zoomPhase = this.origin && this.selected ? "waiting" : "done";
    this.screens = new Map();
    this.width = 1080;
    this.height = 680;
    this.handle.focus();
    cx.timer.after(0, () => this.handle.focus());
    cx.timer.after(180, (cx) => this.startZoom(cx));
    cx.timer.every(1600, (cx) => this.refresh(cx));
  }

  enterNormal(cx) {
    this.preferredColumn = null;
    this.normal = true;
    this.handle.focus();
    cx.notify();
  }

  enterInsert(cx) {
    this.normal = false;
    this.preferredColumn = null;
    const pane = focused()?.pane;
    if (pane) run("pane.focus", { pane });
    cx.notify();
  }

  moveTerminal(direction, normal, cx) {
    const rows = mapRows();
    const current = focused();
    const at = position(rows, current?.pane, current?.space);
    const preferred = normal ? this.preferredColumn ?? at.col : at.col;
    const next = step(rows, at, direction, preferred);
    const pane = rows[next.row]?.terminals[next.col]?.pane;
    this.preferredColumn = direction === "left" || direction === "right" ? next.col : preferred;
    if (!pane || pane === current?.pane) return;

    run("pane.focus", { pane });
    if (normal) this.refocusNormal(cx);
  }

  refocusNormal(cx) {
    cx.timer.after(0, (cx) => {
      if (!this.normal || shared("layout") !== NAME) return;
      this.handle.focus();
      cx.notify();
    });
  }

  ensureFullTerminal(cx) {
    if (this.zoomPending || !focusedSplit()) return;
    this.zoomPending = true;
    cx.timer.after(0, (cx) => {
      this.zoomPending = false;
      if (shared("layout") !== NAME) return;
      const pane = focusedSplit();
      if (pane) {
        const normal = this.handle.is_focused();
        run("pane.zoom", { pane });
        if (normal) this.refocusNormal(cx);
      }
      cx.notify();
    });
  }

  normalKey(event, cx) {
    const key = event.keystroke;
    if (key === "i" || key === "enter") {
      this.enterInsert(cx);
    } else if (key === "g") {
      openOverlay({ mod: NAME, ...FULLSCREEN });
      cx.notify();
    } else if (Object.hasOwn(DIRECTIONS, key)) {
      this.moveTerminal(DIRECTIONS[key], true, cx);
    } else if (event.modifiers.control || event.modifiers.platform || event.modifiers.alt) {
      return;
    }
    cx.stop_propagation();
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
    cx.timer.after(48, (cx) => {
      if (this.zoomPhase !== "full") return;
      this.zoomPhase = "shrinking";
      cx.notify();
      cx.timer.after(ZOOM.duration + 35, (cx) => {
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
    return v_flex().flex_none().font_family(typeof font === "string" && font ? font : "JetBrains Mono")
      .text_color(t.foreground).text_size(fontSize).line_height(fontSize * 1.24)
      .children(screen.lines.map((line) => div().flex_none().whitespace_nowrap().child(line || " ")));
  }

  preview(item, col, row, selected, t) {
    return v_flex().id(item.pane)
      .absolute().left(cellStart(col, TILE_WIDTH)).top(cellStart(row, TILE_HEIGHT))
      .w(TILE_WIDTH).h(TILE_HEIGHT).overflow_hidden().rounded(7).p(7)
      .border_2().border_color(selected ? t.accent : t.border)
      .bg(t.background).cursor_pointer().on_click(() => this.openTerminal(item))
      .child(this.screenText(this.screens.get(item.terminal), TILE_WIDTH, TILE_HEIGHT, t, 10));
  }

  zoomingTerminal(at, t) {
    const shrinking = this.zoomPhase === "shrinking";
    const screen = this.screens.get(this.origin);
    const left = cellStart(at.col, TILE_WIDTH) - this.cameraX;
    const top = cellStart(at.row, TILE_HEIGHT) - this.cameraY;

    return div().id("terminal-map-zoom").absolute()
      .left(shrinking ? left : 0).top(shrinking ? top : 0)
      .w(shrinking ? TILE_WIDTH : this.width).h(shrinking ? TILE_HEIGHT : this.height)
      .transition("left", ZOOM).transition("top", ZOOM)
      .transition("width", ZOOM).transition("height", ZOOM)
      .bg(t.background).overflow_hidden()
      .when(shrinking, (el) => el.rounded(7).border_2().border_color(t.accent))
      .child(div().id("terminal-map-zoom-full").absolute().top(8).left(8)
        .opacity(shrinking ? 0 : 1).transition("opacity", { duration: 145, easing: "ease-out" })
        .child(this.screenText(screen, this.width, this.height, t, 24)))
      .child(div().id("terminal-map-zoom-preview").absolute().top(7).left(7)
        .opacity(shrinking ? 1 : 0).transition("opacity", { duration: 170, delay: 100, easing: "ease-out" })
        .child(this.screenText(screen, TILE_WIDTH, TILE_HEIGHT, t, 10)));
  }

  render(cx) {
    const t = theme();
    if (this.controller) {
      this.ensureFullTerminal(cx);
      return div().id("terminal-map-mode").size_full().track_focus(this.handle)
        .on_key_down((event, cx) => this.normalKey(event, cx))
        .bg(this.handle.is_focused() ? t.accent : t.background);
    }

    const rows = mapRows();
    const at = position(rows, this.selected, focused()?.space);
    this.cameraX = cameraOffset(at.col, TILE_WIDTH, this.width);
    this.cameraY = cameraOffset(at.row, TILE_HEIGHT, this.height);

    const xRange = renderedRange(this.cameraX, this.width, TILE_WIDTH);
    const yRange = renderedRange(this.cameraY, this.height, TILE_HEIGHT);
    const tiles = [];
    const visible = [];
    for (let row = yRange.first; row < Math.min(yRange.end, rows.length); row++) {
      const top = cellStart(row, TILE_HEIGHT) - this.cameraY;
      const items = rows[row].terminals;
      for (let col = xRange.first; col < Math.min(xRange.end, items.length); col++) {
        const item = items[col];
        const left = cellStart(col, TILE_WIDTH) - this.cameraX;
        tiles.push(this.preview(item, col, row, row === at.row && col === at.col, t));
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
      .opacity(done || shrinking ? 1 : 0)
      .transition("opacity", { duration: 200, delay: 35, easing: "ease-out" })
      .children(tiles);

    return div().id("terminal-map-overview").relative().size_full().overflow_hidden()
      .when(done || full || shrinking, (el) => el.bg(t.popover))
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
      .child(gridElement)
      .when(rows.length > 0 && (full || shrinking), (el) => el.child(this.zoomingTerminal(at, t)));
  }
}
