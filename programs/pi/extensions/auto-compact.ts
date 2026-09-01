import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

/**
 * Debug log: one line per turn evaluation so trigger/skip decisions are
 * visible after the fact.
 *   ~/.pi/agent/auto-compact.log
 */
const LOG_FILE = path.join(os.homedir(), ".pi", "agent", "auto-compact.log");
function log(msg: string) {
  try {
    let size = 0;
    try {
      size = fs.statSync(LOG_FILE).size;
    } catch {
      size = 0; // file does not exist yet
    }
    if (size > 1_000_000) fs.appendFileSync(LOG_FILE, "\n[log truncated]\n");
    fs.appendFileSync(LOG_FILE, `${new Date().toISOString()} ${msg}\n`);
  } catch {
    // Logging must never break the extension.
  }
}

/**
 * auto-compact extension
 *
 * Monitors context usage before each LLM turn and automatically triggers
 * compaction when the context window is >= 95% full. Summarizes older
 * conversation history while preserving recent work, key decisions, file
 * changes, and next steps.
 *
 * Adds system-prompt guidance so the LLM knows compaction is handled
 * automatically and does not need to invoke /compact manually.
 */

// ── Threshold ───────────────────────────────────────────────────────
// Trigger compaction when context usage reaches this fraction of the
// model's context window. The default 0.95 (= 95%) leaves room for the
// compaction turn itself to fit comfortably.
const THRESHOLD = 0.95;

// ── System prompt guidance ──────────────────────────────────────────
const COMPACTION_GUIDANCE = `
## Context Window Awareness

An auto-compaction extension monitors context usage and **automatically
triggers compaction** when the context window exceeds ${(THRESHOLD * 100).toFixed(0)}%
capacity. Compaction summarizes older conversation history while preserving:

- Recent work and completed tasks
- Key decisions and their rationale
- Files read and modified
- Current goals and next steps

**You do not need to invoke \`/compact\` manually** — the extension handles
compaction proactively before the context fills up. If you see a notification
about auto-compaction, the extension is freeing space so you can continue
working without interruption.
`;

export default function (pi: ExtensionAPI) {
  // ── State ──────────────────────────────────────────────────────────
  // Guards against re-entrant compaction requests (e.g. if the session
  // reload fires another turn_start before the current compaction finishes).
  let compacting = false;

  // The session file we last saw. When compaction causes a session reload,
  // the session_start fires again — we reset our state there.
  let lastSessionFile: string | undefined;

  // ── Inject system prompt guidance ─────────────────────────────────
  pi.on("before_agent_start", async (event, _ctx) => {
    return {
      systemPrompt: event.systemPrompt + "\n\n" + COMPACTION_GUIDANCE,
    };
  });

  // ── Monitor context before each turn ─────────────────────────────
  // turn_start fires before each LLM call within the agent loop.
  pi.on("turn_start", async (_event, ctx) => {
    // Skip while compaction is already in progress
    if (compacting) {
      log("skip: compaction already in progress");
      return;
    }

    // Prefer pi's own usage estimate (it knows the active model's window).
    // Fallback to the model registry entry. Note: usage.tokens is null right
    // after a compaction until the next LLM response — that is expected.
    const usage = ctx.getContextUsage();
    const contextWindow = usage?.contextWindow ?? ctx.model?.contextWindow ?? 0;
    if (!contextWindow || contextWindow <= 0) {
      log("skip: context window unknown (model missing or contextWindow unset)");
      return;
    }
    if (!usage || typeof usage.tokens !== "number") {
      log(`skip: token count unknown (window=${contextWindow})`);
      return;
    }

    const ratio = usage.tokens / contextWindow;

    // Below threshold — nothing to do
    if (ratio < THRESHOLD) {
      log(`ok: ${(ratio * 100).toFixed(1)}% (${usage.tokens.toLocaleString()} / ${contextWindow.toLocaleString()} tokens) < ${(THRESHOLD * 100).toFixed(0)}% threshold`);
      return;
    }

    // ── Above threshold: trigger compaction ────────────────────────
    compacting = true;
    log(`TRIGGER: ${(ratio * 100).toFixed(1)}% (${usage.tokens.toLocaleString()} / ${contextWindow.toLocaleString()} tokens) >= ${(THRESHOLD * 100).toFixed(0)}% threshold — compacting`);

    if (ctx.hasUI) {
      ctx.ui.notify(
        `Context at ${(ratio * 100).toFixed(1)}% (${usage.tokens.toLocaleString()} / ${contextWindow.toLocaleString()} tokens) — auto-compacting...`,
        "warning",
      );
    }

    ctx.compact({
      customInstructions: [
        "The context window is nearly full and auto-compaction has been triggered.",
        "Summarize older conversation history while preserving:",
        "- Current task and goal",
        "- Key decisions and their rationale",
        "- Files read and modified",
        "- Completed and in-progress work",
        "- Important constraints and preferences",
        "- Blockers and open questions",
        "- Next steps",
        "Keep the summary focused, actionable, and concise.",
      ].join("\n"),

      onComplete: () => {
        compacting = false;
        log("complete: auto-compaction succeeded");
        if (ctx.hasUI) {
          ctx.ui.notify("Auto-compaction complete — continuing.", "info");
        }
      },

      onError: (error: Error) => {
        compacting = false;
        log(`error: auto-compaction failed: ${error.message}`);
        if (ctx.hasUI) {
          ctx.ui.notify(`Auto-compaction failed: ${error.message}`, "error");
        }
      },
    });
  });

  // ── Reset state on session start / reload ─────────────────────────
  // After compaction completes, the session reloads and the extension
  // runtime is re-initialized. This handler resets our guard flag.
  pi.on("session_start", async () => {
    compacting = false;
    lastSessionFile = undefined;
  });
}
