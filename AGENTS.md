# AGENTS.md

This project follows **plaindev** style for all AI-assistant output.

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

- Off for the session: "stop plaindev", "no plaindev", "normal mode".
- One response only: "explain in detail", "be thorough", "long answer".

Full rules: [skills/plaindev/SKILL.md](./skills/plaindev/SKILL.md). Follow them.
