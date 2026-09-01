import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type, type Static } from "typebox";
import { StringEnum } from "@mariozechner/pi-ai";

/**
 * ask-user extension
 *
 * Gives the model a tool to ask the user questions when it:
 *  - lacks context or domain knowledge
 *  - faces an architectural decision with trade-offs
 *  - needs clarification on ambiguous requests
 *  - is about to make a high-impact change
 *
 * The system prompt instructs the model on *when* to use this tool.
 */

// ── System prompt guidance ──────────────────────────────────────────
const ASK_USER_GUIDANCE = `
## When to Ask the User

You have an **ask_user** tool. Use it proactively when you lack information that
would meaningfully change your approach. Do NOT guess or assume when:

### 1. Missing context
- The user's environment, stack, or tool versions are unclear
- You need to know project conventions (naming, folder structure, lint rules)
- The user's intent or goal is ambiguous

### 2. Architectural decisions
- There are multiple valid approaches with different trade-offs (e.g., library
  choice, monolith vs. microservice, state management strategy, database schema design)
- A decision will be hard to reverse later
- The choice affects performance, security, or maintainability in non-obvious ways

### 3. High-impact actions
- You're about to delete, restructure, or rewrite a significant amount of code
- A change could break existing integrations or APIs
- The action touches authentication, billing, data migration, or production configs

### 4. Clarification needed
- The user's request is underspecified (e.g., "add logging" — where? what level? what format?)
- Multiple interpretations are possible and lead to different outcomes

### When NOT to ask
- The answer is obvious or universally accepted best practice
- The question is trivial (e.g., "should I use const or let?")
- You can safely infer from existing code or documentation
- The user has already provided the information

Prefer multiple-choice questions over open-ended ones when you can enumerate
reasonable options. This reduces user friction while still getting the signal
you need.
`;

// ── Normalized parameter shape (after prepareArguments) ────────────
const ParameterSchema = Type.Object({
  question: Type.String({
    description:
      "The full question to present to the user. Be specific and provide context for why you're asking.",
  }),
  question_type: StringEnum(
    ["open", "choice", "confirm"] as const,
    {
      description:
        "Type of question: 'confirm' for yes/no, 'choice' for multiple choice, 'open' for free text",
    }
  ),
  choices: Type.Optional(
    Type.Array(Type.String(), {
      description:
        "For 'choice' type: list of options to present. First option is the default.",
    })
  ),
  context: Type.Optional(
    Type.String({
      description:
        "Brief context explaining why you're asking (shown to user as a subtitle)",
    })
  ),
});

type NormalizedParams = Static<typeof ParameterSchema>;

// ── LLM input normalization (prepareArguments) ─────────────────────
// Models send choices in wildly inconsistent shapes. Normalize *before* validation.
type RawChoice = unknown;

function normalizeSingleChoice(raw: RawChoice, index: number): string {
  // Already a non-empty string ✓
  if (typeof raw === "string" && raw.trim().length > 0) return raw.trim();

  // Object shapes
  if (raw && typeof raw === "object" && !Array.isArray(raw)) {
    const obj = raw as Record<string, unknown>;

    // Shape: { label: "...", description?: "..." }
    if (typeof obj.label === "string" && obj.label.length > 0) {
      const desc = typeof obj.description === "string" ? obj.description : "";
      return desc ? `${obj.label} — ${desc}` : obj.label;
    }

    // Shape: { label: "...", ...otherKeys ignored }
    if (typeof obj.label !== "undefined") {
      return String(obj.label);
    }

    // Last resort: first key in the object IS the label
    const keys = Object.keys(obj);
    if (keys.length > 0) return keys[0];
  }

  // Coerce numbers, booleans
  if (raw !== null && raw !== undefined) {
    const s = String(raw).trim();
    if (s.length > 0) return s;
  }

  // Final fallback — index sentinel
  return `Option ${index + 1}`;
}

function normalizeChoices(raw: unknown): string[] | undefined {
  if (!Array.isArray(raw)) return undefined;
  return raw.map((c, i) => normalizeSingleChoice(c, i));
}

function prepareArguments(raw: unknown): NormalizedParams {
  if (!raw || typeof raw !== "object") {
    return {
      question: "No question provided",
      question_type: "open",
    };
  }

  const obj = raw as Record<string, unknown>;

  // question — must be present and non-empty string; fall back gracefully
  let question = "";
  if (typeof obj.question === "string" && obj.question.trim()) {
    question = obj.question.trim();
  } else if (obj.prompt && typeof obj.prompt === "string") {
    question = obj.prompt.trim(); // some models use "prompt" instead of "question"
  }
  question = question || "No question provided";

  // question_type — clamp to valid enum
  const typeRaw = obj.question_type ?? obj.type ?? "open";
  const validTypes = ["open", "choice", "confirm"];
  const question_type = (typeof typeRaw === "string" &&
    validTypes.includes(typeRaw.toLowerCase())
    ? typeRaw.toLowerCase()
    : "open") as NormalizedParams["question_type"];

  // choices — normalized to string[] | undefined
  const choices = normalizeChoices(obj.choices);

  // context — optional subtitle
  let context: string | undefined;
  if (typeof obj.context === "string" && obj.context.trim()) {
    context = obj.context.trim();
  } else if (typeof obj.subtitle === "string" && obj.subtitle.trim()) {
    context = obj.subtitle.trim(); // some models use "subtitle"
  }

  return { question, question_type, choices, context };
}

// Sentinel appended to the choice list so the user can always type a free-form
// answer instead of picking one of the model-provided options. The leading
// emoji + zero-width-joiner make it effectively impossible for the LLM to
// produce the same string as a regular choice.
const FREE_TEXT_SENTINEL = "\u270f\ufe0f Type your own answer\u2026";

// Timeout for UI dialogs (5 minutes) — prevents agent from hanging forever
const UI_TIMEOUT_MS = 5 * 60 * 1000;

export default function (pi: ExtensionAPI) {
  // ── Inject system prompt guidance ─────────────────────────────────
  pi.on("before_agent_start", async (event, _ctx) => {
    return {
      systemPrompt: event.systemPrompt + "\n\n" + ASK_USER_GUIDANCE,
    };
  });

  // ── Register the ask_user tool ────────────────────────────────────
  pi.registerTool({
    name: "ask_user",
    label: "Ask User",
    description:
      "Ask the user a question when you lack context, face an architectural decision, or need clarification. Use proactively before guessing.",
    promptSnippet:
      "Ask the user a question (open-ended, multiple choice, or confirm)",
    promptGuidelines: [
      "Use ask_user proactively when you lack context, face architectural decisions with trade-offs, are about to make high-impact changes, or need clarification on ambiguous requests. Do NOT use for trivial questions or when the answer is obvious from context.",
    ],
    parameters: ParameterSchema,
    prepareArguments,

    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      const { question, question_type, choices, context } = params;
      const title = context ?? "Question";

      // ── Non-interactive fallback ────────────────────────────────────
      if (!ctx.hasUI) {
        return {
          content: [
            {
              type: "text" as const,
              text: `[ask_user skipped — non-interactive mode] Question: "${question}"`,
            },
          ],
          details: { skipped: true, reason: "non-interactive" },
          terminate: true,
        };
      }

      let answer: string;

      try {
        switch (question_type) {
          case "confirm": {
            try {
              const ok = await ctx.ui.confirm(title, question, {
                timeout: UI_TIMEOUT_MS,
              });
              answer = ok
                ? "Yes (confirmed by user)"
                : "No (declined by user)";
            } catch {
              answer = "(user did not respond in time or dialog was dismissed)";
            }
            break;
          }

          case "choice": {
            const choiceList = choices?.filter(Boolean);
            if (!choiceList || choiceList.length === 0) {
              // Degraded to open if no valid choices provided
              try {
                const input = await ctx.ui.input(title, question, {
                  timeout: UI_TIMEOUT_MS,
                });
                answer =
                  input && input.trim()
                    ? input.trim()
                    : "(user did not provide an answer)";
              } catch {
                answer = "(user did not respond in time or dialog was dismissed)";
              }
              break;
            }

            // Always offer a free-text escape hatch as the last option.
            const allChoices = [...choiceList, FREE_TEXT_SENTINEL];

            try {
              const selected = await ctx.ui.select(title, allChoices, {
                timeout: UI_TIMEOUT_MS,
              });

              if (selected === undefined) {
                answer = "(user cancelled the dialog)";
              } else if (selected === FREE_TEXT_SENTINEL) {
                // User picked the free-text option — prompt for input.
                try {
                  const freeText = await ctx.ui.input(title, question, {
                    timeout: UI_TIMEOUT_MS,
                  });
                  answer =
                    freeText && freeText.trim()
                      ? freeText.trim()
                      : "(user did not provide an answer)";
                } catch {
                  answer =
                    "(user cancelled the free-text input or timed out)";
                }
              } else {
                answer = selected;
              }
            } catch {
              answer = "(user did not respond in time or dialog was dismissed)";
            }
            break;
          }

          case "open":
          default: {
            try {
              const input = await ctx.ui.input(title, question, {
                timeout: UI_TIMEOUT_MS,
              });
              answer =
                input && input.trim()
                  ? input.trim()
                  : "(user did not provide an answer)";
            } catch {
              answer =
                "(user did not respond in time or dialog was dismissed)";
            }
            break;
          }
        }
      } catch (err) {
        // Catches any unexpected errors from the switch logic itself
        const msg = err instanceof Error ? err.message : String(err);
        answer = `(error: ${msg})`;
      }

      return {
        content: [
          {
            type: "text" as const,
            text: `User response to: "${question}"\n\nAnswer: ${answer}`,
          },
        ],
        details: { question, question_type, choices, answer },
      };
    },
  });
}
