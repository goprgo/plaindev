# plaindev

> Inspired by Caveman's no-fluff discipline, tuned for easy reading.

A coding-agent skill pack that makes AI answers **clear and fast to scan**. Two skills ship together:

- **plaindev/reply** — structured answers for everyday software work.
- **plaindev/check** — negative-only GitHub PR review via `gh`.

Built for non-native English readers and people who find dense text hard to parse.

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

## Skills

| Skill | Purpose | Invoke |
|---|---|---|
| **reply** | Clear, structured assistant output | `/plaindev/reply`, "use plaindev" |
| **check** | Negative-only PR review with `gh` | `/plaindev/check`, "check this PR" |

Full rules:

- [skills/plaindev/reply/SKILL.md](./skills/plaindev/reply/SKILL.md)
- [skills/plaindev/check/SKILL.md](./skills/plaindev/check/SKILL.md)

## Before / after

**Default AI output**

> Sure! I'd be happy to help. The reason your React component is re-rendering is most likely because you're creating a new object reference on each render cycle. When you pass an inline object as a prop, React's shallow comparison sees it as a different object every render, which triggers a re-render. I'd recommend using `useMemo` to memoize the object.

**plaindev reply**

> **Cause:** Inline object prop creates a new reference each render.
> **Fix:** Wrap the object in `useMemo`.

Same fix. Faster to read in any language.

## Install

Supported tools: **Cursor** and **Claude Code** only. `git` is required.

By default the installer **registers both skills globally**. Activate reply per session with `/plaindev/reply` or "use plaindev". Activate check with `/plaindev/check` or "check this PR".

To make **plaindev reply always active** in the current repo without invocation, pass `--always-on`.

### Cursor

Global — invoke skills when needed:

```bash
curl -fsSL https://raw.githubusercontent.com/goprgo/plaindev/main/install/cursor.sh | bash
```

Also always-on reply for the current repo (writes `.cursor/rules/plaindev-reply.mdc` and local skills):

```bash
curl -fsSL https://raw.githubusercontent.com/goprgo/plaindev/main/install/cursor.sh | bash -s -- --always-on
```

Install paths:

- Global: `~/.cursor/skills/plaindev/reply/`, `~/.cursor/skills/plaindev/check/`
- Local (`--always-on`): `.cursor/skills/plaindev/reply/`, `.cursor/skills/plaindev/check/`, `.cursor/rules/plaindev-reply.mdc`

### Claude Code

Global — applied when description matches:

```bash
curl -fsSL https://raw.githubusercontent.com/goprgo/plaindev/main/install/claude-code.sh | bash
```

Also always-on reply for the current repo (injects plaindev block into `./AGENTS.md` and local skills):

```bash
curl -fsSL https://raw.githubusercontent.com/goprgo/plaindev/main/install/claude-code.sh | bash -s -- --always-on
```

Install paths:

- Global: `~/.claude/skills/plaindev/reply/`, `~/.claude/skills/plaindev/check/`
- Local (`--always-on`): `.claude/skills/plaindev/reply/`, `.claude/skills/plaindev/check/`, `AGENTS.md` block

### Install everything at once

Every detected tool, global registration:

```bash
curl -fsSL https://raw.githubusercontent.com/goprgo/plaindev/main/install.sh | bash
```

Also always-on reply for the current repo:

```bash
curl -fsSL https://raw.githubusercontent.com/goprgo/plaindev/main/install.sh | bash -s -- --always-on
```

Specific tools (positional args):

```bash
curl -fsSL https://raw.githubusercontent.com/goprgo/plaindev/main/install.sh | bash -s -- cursor claude-code
```

### Or clone and run locally

```bash
git clone https://github.com/goprgo/plaindev.git
cd plaindev
./install/cursor.sh --always-on   # any of the scripts above, same flags
```

## Uninstall (global)

Remove global plaindev skills. **Does not touch repo-local files.**

```bash
curl -fsSL https://raw.githubusercontent.com/goprgo/plaindev/main/uninstall.sh | bash
```

One tool only:

```bash
curl -fsSL https://raw.githubusercontent.com/goprgo/plaindev/main/uninstall.sh | bash -s -- cursor
```

Same flag on install scripts also works: `install/cursor.sh --uninstall`.

**Local cleanup** (manual):

- `.cursor/skills/plaindev/`
- `.cursor/rules/plaindev-reply.mdc`
- `.claude/skills/plaindev/`
- `AGENTS.md` block between `<!-- plaindev-begin -->` and `<!-- plaindev-end -->`

## How plaindev activates (by tool)

| Tool | Global install | `--always-on` (this repo) |
|---|---|---|
| **Cursor** | Invoke `/plaindev/reply` or `/plaindev/check` | Reply always active via rule; check on invoke |
| **Claude Code** | Auto-discovered by description | Reply always loaded via `AGENTS.md` |

To turn a skill off in any session, use its turn-off phrase. This does not uninstall plaindev.

## Triggers

**reply**

- Turn on: `/plaindev/reply`, "plaindev mode", "use plaindev"
- Turn off (session): "stop plaindev reply", "stop plaindev"
- This response only: "explain in detail", "be thorough", "long answer"

**check**

- Turn on: `/plaindev/check`, "check this PR", "pr check"
- Turn off (session): "stop plaindev check", "stop plaindev"
- This response only: "brief check", "table only"

**both**

- Turn off (session): "stop plaindev"

## Response shapes (reply)

plaindev reply uses four shapes. Once you learn them, scanning becomes automatic.

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

## The name

A small pun on ESL: col**ESL**aw. The lowercase spelling is canonical everywhere — the capitals are just here so the joke lands.

## Status

Hobby project. v0. Used daily by the author. Feedback and PRs welcome.

## License

MIT.
