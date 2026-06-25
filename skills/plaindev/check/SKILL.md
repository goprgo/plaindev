---
name: check
description: >
  plaindev check — review GitHub pull requests with gh and return negative-only
  structured criticism in plaindev reply style. Reports bugs, issues, gaps, and
  sub-optimal code only — no praise or neutral notes. ADHD-friendly ESL output:
  compact rows with location, what, why, and fix. Use when the user invokes
  /plaindev/check, /check, says "pr check", "check this PR", or asks for PR
  review on a GitHub pull request.
---

# check

Review a GitHub PR with `gh`. Report **negative findings only**: bugs, issues, gaps, sub-optimal implementations. Skip praise, neutral notes, preamble, and filler.

Follow [plaindev reply](../reply/SKILL.md) hard rules for prose. This skill adds PR workflow and output shape.

## Persistence

Active for the PR review. Stay active for follow-up questions about the same PR. Turn off only on explicit user request. After turn-off, stay off for the rest of the session.

## Resolve the PR

Pick one target, in this order:

1. PR number or URL the user gave.
2. Current branch: `gh pr view --json number,url,title`.
3. If no PR exists, say so in one sentence. Stop.

If the user gave a PR link or number and the local branch differs, fetch context with `gh` only. Do not checkout unless the user asks.

## Gather context with gh

Run these in parallel when possible:

```bash
gh pr view <target> --json title,body,baseRefName,headRefName,files,additions,deletions,commits,reviews,state,author
gh pr diff <target>
gh pr checks <target>
```

Optional when useful:

```bash
gh pr view <target> --comments
gh api repos/{owner}/{repo}/pulls/{number}/files --paginate
```

Read the diff. Read changed files when the diff alone is not enough. Note approximate line numbers from the diff hunk headers (`@@` lines) or from the file after checkout.

## What to criticize

### Scope

Criticize only what this PR changes in this repo.

- **In scope:** new or modified lines, files touched by the diff, and PR metadata (title, body, checks).
- **Out of scope:** unchanged existing code. Do not file findings about problems the PR did not introduce or alter.
- **Out of scope:** dependency code. Do not criticize libraries, packages, `node_modules`, vendored code, or generated files from third-party tools.

If a finding needs unchanged or external code as context, mention it briefly. Still point the finding at a changed line in the diff.

### Report only negatives

By default, include only problems. Do not list what is good, acceptable, or neutral.

Report these:

- Bugs and incorrect behavior.
- Security, reliability, or data risks.
- Missing tests, docs, or migrations for changed behavior.
- Gaps: unhandled edge cases, error paths, or incomplete work.
- Sub-optimal implementations in changed code.

Do not report:

- Code that is fine as-is.
- Neutral observations ("uses pattern X", "follows convention Y").
- Compliments ("nice refactor", "good test coverage here").

If nothing is wrong, say so in the no-findings shape. Do not pad the report with positives.

Report only issues that matter for merge. Skip nitpicks unless the user asked for style-only review.

Check, in priority order:

1. Correctness bugs and edge cases.
2. Security and data handling.
3. Missing or weak tests for changed behavior.
4. Breaking API or contract changes without migration.
5. Error handling and failure paths.
6. Performance regressions on hot paths.
7. Maintainability: unclear names, duplication, dead code.
8. PR hygiene: scope creep, missing description, failing checks.

Sort findings by severity. Put blockers first.

## Output shape

Every review uses this shape. Do not skip sections.

### Header

```
**PR:** [#123 title](url) — +N / −M lines, N files
**Verdict:** [Approve | Request changes | Blocked by checks]
**Findings:** N (or "None")
```

`Verdict` rules:

- **Blocked by checks** when required checks fail.
- **Request changes** when any blocker or serious issue exists.
- **Approve** only when no material issues remain.

### Summary table

One row per finding. Always include this table, even for 1 finding.

| # | Location | Summary |
|---|----------|---------|
| 1 | `path/to/file.ts:~42` | Short preview of the issue |

Location rules:

- Use `` `path/to/file.ext:~LINE` `` when a line is known.
- Use `` `path/to/file.ext` `` when the whole file is the issue.
- Use `PR description` or `PR scope` when the issue is not in code.
- Prefix `~` before the line number. It means approximate.
- Omit Location only for repo-wide issues. Use `repository` instead.

### Detail blocks

One block per table row. Index must match the table.

```
### 1. Short preview — `path/to/file.ts:~42`

**What:** One or two sentences. State the problem plainly.
**Why it matters:** One or two sentences. State the risk or cost.
**Solution:** Concrete fix. Code snippet only when it helps.
**Alternative approach:** Different valid fix. Omit this line when none exists.
```

Rules for detail blocks:

- **Short preview** in the heading must match the Summary column.
- **What** and **Why it matters** are required.
- **Solution** is required when a fix exists. Write "No code change needed" for process-only issues.
- **Alternative approach** is optional. Include only when a real trade-off exists.
- One idea per sentence. ~15 words per sentence when possible.
- No hedging. No pleasantries.

### No findings

When the PR is clean:

```
**PR:** [#123 title](url) — +N / −M lines, N files
**Verdict:** Approve
**Findings:** None

No material issues found.
```

Still mention failing checks or missing tests if those exist. They are findings.

## Severity (internal only)

Use severity to sort. Do not add a Severity column unless the user asks.

| Level | Examples |
|-------|----------|
| Blocker | Bug, security hole, broken build, data loss |
| Serious | Missing tests for risky change, silent failure |
| Minor | Naming, small refactor, optional polish |

## gh failure handling

If `gh` fails:

1. State the error in one sentence.
2. Check `gh auth status`. Suggest `gh auth login` when not authenticated.
3. Do not invent PR content.

## Escape hatches

Turn check off for the rest of the session:

- "stop plaindev check"
- "stop plaindev" (turns off reply and check)

Relax detail for this response only, then resume:

- "brief check"
- "table only"

For "table only", show the summary table without detail blocks.

## Anti-patterns

Bad: "Great PR overall! I noticed a few minor things..."

Good: lead with the summary table. No positive summary.

Bad: neutral note — "Auth flow uses JWT, which is standard."

Good: omit. Only file a finding when something is wrong or missing.

Bad: finding with no location when the diff points to a file.

Good: `` `src/handler.go:~88` `` from the diff hunk.

Bad: vague **Solution:** "Consider refactoring this."

Good: **Solution:** Extract validation into `validateInput()` and call it before the DB write.

Bad: **Alternative approach:** on every item.

Good: omit when there is only one reasonable fix.

Bad: criticizing pre-existing code the PR did not touch.

Good: skip it, or tie the finding to a line the PR actually changed.

Bad: criticizing a third-party package API or `node_modules` implementation.

Good: criticize only how this PR uses the dependency, and only on changed lines.

## Example

**PR:** [#42 Add session expiry](https://github.com/org/repo/pull/42) — +120 / −15 lines, 4 files
**Verdict:** Request changes
**Findings:** 2

| # | Location | Summary |
|---|----------|---------|
| 1 | `src/auth/session.ts:~42` | Token expiry is not checked before DB lookup |
| 2 | `src/auth/session.test.ts` | No test for expired token path |

### 1. Token expiry not checked — `src/auth/session.ts:~42`

**What:** `validateSession` reads the DB before checking `exp`.
**Why it matters:** Expired tokens still hit the DB. Stale sessions may pass.
**Solution:** Compare `exp` to `Date.now()` first. Return early when expired.

### 2. Missing test for expired token — `src/auth/session.test.ts`

**What:** Tests cover valid tokens only. Expired path is untested.
**Why it matters:** Regressions in expiry logic will ship silently.
**Solution:** Add a test that passes an expired token and expects 401.
