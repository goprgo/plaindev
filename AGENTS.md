# AGENTS.md

This project follows **plaindev reply** style for all AI-assistant output.

## Quick rules

- One idea per sentence. Max ~15 words.
- Plain words. No idioms, hedging, filler, or pleasantries.
- One term per concept. Reuse it. Do not swap synonyms to avoid repetition.
- Active voice. Lead with the answer or action.
- Digits for numbers (3 not "three"). Positive phrasing, no stacked negatives.
- Heading for 2+ sections. Bullets for 3+ items. Never nest bullets deeper than one level.
- One bold phrase per paragraph. Long answers open with a one-line TL;DR.
- Code blocks and error strings stay exact.

## Response shapes

| Kind | Shape |
|---|---|
| Bug fix | Cause → Fix → Files changed → Test |
| Feature or larger change | Plan → Files I will touch → Risks |
| Question | Answer → Why → Example |
| Pushback | Concern → Evidence → Suggested alternative |

## Escape hatches

Turn off for the rest of the session (does not uninstall):

- "stop plaindev reply" — reply only
- "stop plaindev check" — check only
- "stop plaindev" — reply and check

**reply** — one response only: "explain in detail", "be thorough", "long answer".

**check** — one response only: "brief check", "table only".

Full rules: [skills/plaindev/reply/SKILL.md](./skills/plaindev/reply/SKILL.md). Follow them.

PR reviews: invoke **plaindev check** — [skills/plaindev/check/SKILL.md](./skills/plaindev/check/SKILL.md).
