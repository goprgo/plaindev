# plaindev

> Inspired by Caveman's no-fluff discipline, tuned for easy reading.

A coding-agent skill that makes AI answers **clear and fast to scan**. Built for everyday software work: bug fixes, features, reviews, explanations. Predictable response shapes, plain words, short sentences. Same technical content, less effort to parse.

Non-native English readers and people who find dense text hard to parse benefit most.

## Why

[Caveman](https://github.com/JuliusBrussee/caveman) is the inspiration here. It cuts ~75% of tokens with strict no-fluff discipline. plaindev borrows that discipline but optimizes for a different goal: clear, fast-to-scan answers for software work.

So plaindev makes a different trade-off:

- Plain words instead of compressed slang.
- Short sentences instead of telegraphic fragments.
- Standardized shapes so you always know where the answer is.
- Compactness is a side effect, not the goal.

## Who it is for

Default AI output is full of phrasal verbs ("get rid of", "kick off", "look into"), idioms, soft hedging ("you might want to consider"), and preamble. This style is invisible to most native English speakers, but it adds parsing effort for everyone under time pressure.

plaindev drops that style by default. The output stays in plain words, with the answer first and a predictable shape. These readers benefit most:

- Developers who read English as a second language (ESL).
- People who find dense text hard to parse, including folks with ADHD.
- Anyone tired of AI preamble, hedging, and filler.

You do not need to identify with any of these. If clear, structured output beats friendly preamble for you, plaindev is for you.

## Before / after

**Default AI output**

> Sure! I'd be happy to help. The reason your React component is re-rendering is most likely because you're creating a new object reference on each render cycle. When you pass an inline object as a prop, React's shallow comparison sees it as a different object every render, which triggers a re-render. I'd recommend using `useMemo` to memoize the object.

**plaindev output**

> **Cause:** Inline object prop creates a new reference each render.
> **Fix:** Wrap the object in `useMemo`.

Same fix. Faster to read in any language.

## Install

One per-tool installer, runnable remotely or from a local clone. `git` is required.

By default the installer **registers** plaindev globally. You activate it per session with `/plaindev` or "use plaindev". To turn it off, say "no plaindev".

To make plaindev **always active** in the current repo without invocation, pass `--always-on`.

### Cursor

Global only — invoke with `/plaindev`:

```bash
curl -fsSL https://raw.githubusercontent.com/gopaz/plaindev/main/install/cursor.sh | bash
```

Also always-on for the current repo (writes `.cursor/rules/plaindev.mdc`):

```bash
curl -fsSL https://raw.githubusercontent.com/gopaz/plaindev/main/install/cursor.sh | bash -s -- --always-on
```

Uninstall:

```bash
curl -fsSL https://raw.githubusercontent.com/gopaz/plaindev/main/install/cursor.sh | bash -s -- --uninstall
```

### Claude Code

Global only — applied when description matches:

```bash
curl -fsSL https://raw.githubusercontent.com/gopaz/plaindev/main/install/claude-code.sh | bash
```

Also always-on for the current repo (injects plaindev block into `./AGENTS.md`):

```bash
curl -fsSL https://raw.githubusercontent.com/gopaz/plaindev/main/install/claude-code.sh | bash -s -- --always-on
```

Uninstall:

```bash
curl -fsSL https://raw.githubusercontent.com/gopaz/plaindev/main/install/claude-code.sh | bash -s -- --uninstall
```

### Codex

Global only — applied when description matches:

```bash
curl -fsSL https://raw.githubusercontent.com/gopaz/plaindev/main/install/codex.sh | bash
```

Also always-on for the current repo (injects plaindev block into `./AGENTS.md`):

```bash
curl -fsSL https://raw.githubusercontent.com/gopaz/plaindev/main/install/codex.sh | bash -s -- --always-on
```

Uninstall:

```bash
curl -fsSL https://raw.githubusercontent.com/gopaz/plaindev/main/install/codex.sh | bash -s -- --uninstall
```

### Install everything at once

Every detected tool, global registration:

```bash
curl -fsSL https://raw.githubusercontent.com/gopaz/plaindev/main/install.sh | bash
```

Also always-on for the current repo:

```bash
curl -fsSL https://raw.githubusercontent.com/gopaz/plaindev/main/install.sh | bash -s -- --always-on
```

Specific tools (positional args):

```bash
curl -fsSL https://raw.githubusercontent.com/gopaz/plaindev/main/install.sh | bash -s -- cursor claude-code
```

Uninstall for every detected tool:

```bash
curl -fsSL https://raw.githubusercontent.com/gopaz/plaindev/main/install.sh | bash -s -- --uninstall
```

### Or clone and run locally

```bash
git clone https://github.com/gopaz/plaindev.git
cd plaindev
./install/cursor.sh --always-on   # any of the scripts above, same flags
```

## How plaindev activates (by tool)

| Tool | Global install | `--always-on` (this repo) |
|---|---|---|
| **Cursor** | Available, invoke with `/plaindev` | Always active (`alwaysApply: true` rule) |
| **Claude Code** | Auto-discovered by description, applied when relevant | Always loaded via `AGENTS.md` |
| **Codex** | Auto-discovered by description, applied when relevant | Always loaded via `AGENTS.md` |

To turn plaindev off in any session, just say "no plaindev" or "normal mode".

## Triggers

- **Turn on:** `/plaindev`, "plaindev mode", "use plaindev"
- **Turn off:** "stop plaindev", "no plaindev", "normal mode"
- **This response only:** "explain in detail", "be thorough", "long answer"

## Response shapes

plaindev uses four shapes. Once you learn them, scanning becomes automatic.

| Kind | Shape |
|---|---|
| Bug fix | Cause → Fix → Files → Test |
| Feature / larger change | Plan → Files → Risks |
| Question | Answer → Why → Example |
| Pushback | Concern → Evidence → Alternative |

## Hard rules (short version)

- One idea per sentence. Max ~15 words.
- No phrasal verbs, idioms, hedging, filler, or pleasantries.
- Active voice. Lead with the answer.
- Headings for 2+ sections. Bullets for 3+ items.
- Code blocks and error strings stay exact.

Full rules live in [skills/plaindev/SKILL.md](./skills/plaindev/SKILL.md).

## The name

A small pun on ESL: col**ESL**aw. The lowercase spelling is canonical everywhere — the capitals are just here so the joke lands.

## Status

Hobby project. v0. Used daily by the author. Feedback and PRs welcome.

## License

MIT.
