import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { StringEnum } from "@earendil-works/pi-ai";

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

// ── Choice normalization ────────────────────────────────────────────
// LLMs occasionally send choices in non-string shapes:
//   - { label: "Yes", description: "..." }   (Claude / OpenAI tool-use style)
//   - { "Yes": "" }                          (label used as a key with empty value)
//   - "Yes"                                  (already a string)
//
// `ctx.ui.select` requires `string[]`, so flatten anything we get into that.
type RawChoice =
  | string
  | { label?: unknown; description?: unknown; [k: string]: unknown };

function normalizeChoice(raw: unknown, index: number): string {
  if (typeof raw === "string") return raw;

  if (raw && typeof raw === "object") {
    const obj = raw as Record<string, unknown>;

    // 1. Preferred shape: { label, description? }
    if (typeof obj.label === "string" && obj.label.length > 0) {
      const desc = typeof obj.description === "string" ? obj.description : "";
      return desc ? `${obj.label} — ${desc}` : obj.label;
    }

    // 2. Last-resort: label was used as the *key* with an empty value
    //    e.g. { "Yes, destroy now": "" }
    for (const [key, value] of Object.entries(obj)) {
      if (typeof value === "string" || value === "") return key;
    }

    // 3. Give up — fall back to JSON so the user can still see something
    try {
      return JSON.stringify(obj);
    } catch {
      return `Option ${index + 1}`;
    }
  }

  // 4. Anything else (number, null, …): stringify it.
  return String(raw);
}

function normalizeChoices(raw: unknown): string[] {
  if (!Array.isArray(raw)) return [];
  return raw.map((c, i) => normalizeChoice(c, i));
}

// Sentinel appended to the choice list so the user can always type a free-form
// answer instead of picking one of the model-provided options. The leading
// emoji + zero-width-joiner make it effectively impossible for the LLM to
// produce the same string as a regular choice.
const FREE_TEXT_SENTINEL = "\u270f\ufe0f Type your own answer\u2026";

export default function (pi: ExtensionAPI) {
  // ── Inject system prompt guidance ─────────────────────────────────
  pi.on("before_agent_start", async (event, ctx) => {
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
    parameters: Type.Object({
      question: Type.String({
        description:
          "The full question to present to the user. Be specific and provide context for why you're asking.",
      }),
      question_type: StringEnum([
        "open",
        "choice",
        "confirm",
      ] as const),
      // Accept either a plain string OR an object with a `label` field.
      // We normalize everything to `string[]` inside `execute`.
      choices: Type.Optional(
        Type.Array(
          Type.Union([
            Type.String(),
            Type.Object({
              label: Type.String(),
              description: Type.Optional(Type.String()),
            }),
          ]),
          {
            description:
              "For 'choice' type: list of options to present. First option is the default. Each entry may be a plain string or an object like { label, description }.",
          }
        )
      ),
      context: Type.Optional(
        Type.String({
          description:
            "Brief context explaining why you're asking (shown to user as a subtitle). E.g., 'Choosing between React Query and SWR for data fetching'",
        })
      ),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      const { question, question_type, context } = params;
      const choices = normalizeChoices(params.choices);

      // Build the prompt text for the dialog
      const title = context ?? "Question";

      if (!ctx.hasUI) {
        // Non-interactive mode: return a message indicating we can't ask
        return {
          content: [
            {
              type: "text" as const,
              text: `[ask_user skipped in non-interactive mode] Question: "${question}" — proceeding without user input. If critical, re-run interactively and the model will ask again.`,
            },
          ],
          details: { skipped: true, question, question_type, choices },
        };
      }

      let answer: string | undefined;

      switch (question_type) {
        case "confirm": {
          const ok = await ctx.ui.confirm(title, question);
          answer = ok ? "Yes (confirmed by user)" : "No (declined by user)";
          break;
        }

        case "choice": {
          if (choices.length === 0) {
            // Fallback to open if no choices given
            answer = await ctx.ui.input(title, question);
            break;
          }
          // Always offer a free-text escape hatch as the last option.
          const choicesWithFreeText = [...choices, FREE_TEXT_SENTINEL];
          const selected = await ctx.ui.select(title, choicesWithFreeText);

          if (selected === undefined) {
            answer = "(user cancelled)";
          } else if (selected === FREE_TEXT_SENTINEL) {
            // User picked the free-text option — prompt for input.
            const freeText = await ctx.ui.input(title, question);
            if (freeText === undefined || freeText.trim() === "") {
              answer = "(user did not provide an answer)";
            } else {
              answer = freeText;
            }
          } else {
            answer = selected;
          }
          break;
        }

        case "open":
        default: {
          answer = await ctx.ui.input(title, question);
          if (answer === undefined || answer.trim() === "") {
            answer = "(user did not provide an answer)";
          }
          break;
        }
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
