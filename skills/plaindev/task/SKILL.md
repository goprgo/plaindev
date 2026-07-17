---
name: plaindev-task
description: >
  plaindev task — run a full ticket-to-PR dev workflow. Creates a Jira issue,
  moves it to In Progress, checks out a branch, makes conventional commits,
  pushes, opens a PR with gh, and moves the issue to In Review. Uses the
  Atlassian MCP tools for Jira and the gh CLI for GitHub. On-demand only:
  run when the user explicitly invokes /plaindev-task, says "run the task
  workflow", or "ticket to PR". Do not trigger it automatically.
disable-model-invocation: true
---

# task

Take a described piece of work and run it end to end: Jira issue, branch,
commits, push, PR, and status transitions. The developer explains the task once.
This skill does the mechanical steps.

Follow the **plaindev-reply** skill hard rules for all prose. This skill adds
the workflow and output shape.

## Requirements

Both must work before you start:

- **Atlassian MCP tools** for Jira. Load them with ToolSearch (query "atlassian jira"). If none load, tell the user to authorize the Atlassian connector, then stop.
- **gh CLI** for GitHub. Check `gh auth status`. If it fails, tell the user to run `gh auth login`, then stop.

## Autonomy

Confirm the plan once, then run. Show the plan block (see below). After the user approves, run every step without more prompts. Pause only when a value is ambiguous or a step fails.

Never skip the plan gate. It is the one confirmation before outward actions (create issue, push, open PR, move issue).

## Resolve the Jira project

Pick the project key in this order. Stop at the first hit.

1. A project key the user names in the request.
2. Env var `PLAINDEV_JIRA_PROJECT`.
3. File `.plaindev/config` at the repo root, line `PLAINDEV_JIRA_PROJECT=KEY`.
4. Ask the user. Then offer to save it to `.plaindev/config` for next time.

## Preflight

Run these checks before the plan gate. Stop on the first failure and report it.

1. `gh auth status` succeeds.
2. Atlassian MCP tools load and a Jira site is reachable.
3. Working tree is clean: `git status --porcelain` is empty. If dirty, ask whether to stash or stop.
4. Base branch resolved. Use the branch the user names. Otherwise default to `main`, or `master` if `main` does not exist. Fall back to the repo default (`gh repo view --json defaultBranchRef`) only if neither exists.
5. Latest base fetched: `git fetch origin <base>`. The branch starts from `origin/<base>`, so it is current even if the local base is stale.
6. Git identity set. Check `git config --local user.name` and `user.email`.
   - Both set locally: use them. Continue.
   - Set only globally (`git config --global user.name` / `user.email`): show the global name and email, then ask whether to use them. Continue only on yes.
   - Neither set: stop. Ask the user to set an identity, for example `git config user.name "Name"` and `git config user.email "you@example.com"`.

## Build the plan

First decide the issue structure (see below). Then derive these values:

- **Project:** resolved key.
- **Issue type:** infer from the work (Bug for a fix, Story or Task otherwise). Ask only if unclear.
- **Summary:** one line from the user's description.
- **Description:** short body. Include acceptance notes if the user gave any.
- **Branch:** `<key-lower>-<slug>`, e.g. `proj-123-add-session-expiry`. Slug is the summary, lowercased, hyphenated, max ~6 words.
- **Base branch:** from preflight.

### Single issue or story with sub-tasks

Default to one issue. Consider a **Story with sub-tasks** when any of these hold:

- The work spans **multiple repos**.
- The steps must run **sequentially**, each a milestone.
- The work splits into **clearly separable units**.

For a story, create one sub-task per unit, repo, or phase. Each sub-task gets its own branch, commits, and PR. The story tracks the whole effort. Move each sub-task through In Progress and In Review on its own. Show the sub-task breakdown in the plan for approval before creating anything.

Show the plan and ask to proceed:

```
**Task plan**
- Project: PROJ (Task)
- Summary: Add session expiry
- Branch: proj-123-add-session-expiry  (from main)
- PR: opens against main when work is committed

Proceed? (yes / edit)
```

## Run the steps

After approval, run in order. Report each step in one line as it completes.

1. **Create the issue.** Use the Atlassian MCP create-issue tool. Assign to the current user. Capture the issue key and URL. For a story, create the Story first, then one Sub-task per unit with the story as parent. Run steps 2–8 per sub-task. Capture every key and URL.
2. **Move to In Progress.** List the issue transitions. Match a target whose name contains "progress" (case-insensitive). If none matches, list the options and ask. Apply the transition.
3. **Create the branch.** Branch from the freshly fetched base: `git checkout -b <branch> origin/<base>`. This guarantees the branch starts from the latest base. If the branch exists, check it out and continue.
4. **Do the work and commit.** Make the code changes. Group them into logical units. Commit each unit with a conventional message in the form `<type>(<TICKET>): <summary>`, where the scope is the Jira ticket key:

   ```
   fix(AT-5180): populate top-level items/totalCount
   ```

   Use `feat`, `fix`, `refactor`, `test`, `docs`, `chore` as the type. One concern per commit. The ticket key in the scope links the commit to Jira, so no separate footer is needed.
5. **Push.** `git push -u origin <branch>`.
6. **Open the PR.** `gh pr create --base <base> --head <branch> --title "<type>(<TICKET>): <summary>" --body "<body>"`. Use the same `<type>(<TICKET>): <summary>` form as the commits, e.g. `fix(AT-5180): populate top-level items/totalCount`. Capture the PR URL. Start the body with a **TL;DR** so a reviewer grasps the change at a glance, then the detailed description:

   The TL;DR must be clear and concise. Use plain, simple words. Assume the reviewer has limited context. One or two short sentences. A reader should understand what the PR does and why on the first read, without opening the diff.

   ```
   ## TL;DR
   One or two short sentences in plain words: what this PR does and why.

   ## What changed
   - point per meaningful change

   ## Test
   How it was verified.

   Refs: PROJ-123
   ```
7. **Link the PR to the issue.** Add a Jira comment with the PR URL. Add a remote link too if the MCP tools support it.
8. **Move to In Review.** List transitions again. Match a name containing "review" (case-insensitive). If none matches, list the options and ask. Apply it.

## Output shape

End with this summary. Use real clickable links.

Single issue:

```
**Ticket:** [PROJ-123 Add session expiry](url) — In Review
**Branch:** proj-123-add-session-expiry
**Commits:** 3
**PR:** [#45 Add session expiry](url) — Open
```

Story with sub-tasks (one row per sub-task):

```
**Story:** [PROJ-120 Session expiry rollout](url)

| Sub-task | Status | Branch | PR |
|----------|--------|--------|----|
| [PROJ-121 API expiry check](url) | In Review | proj-121-api-expiry | [#45](url) |
| [PROJ-122 Client refresh](url) | In Review | proj-122-client-refresh | [#46](url) |
```

## Failure handling

If any step fails:

1. Stop. Do not run later steps.
2. State the failed step and the exact error in one or two sentences.
3. List what already happened (issue created, branch pushed, and so on), so the developer can resume by hand. Include clickable links to any issue and PR already created.
4. Suggest the one next action to recover.

Do not invent issue keys, transition names, or PR numbers. Read them from the tool output.

## Escape hatches

Turn task off for the rest of the session:

- "stop plaindev task"
- "stop plaindev" (turns off all plaindev skills)

Scope changes for one run:

- "no ticket" — skip Jira. Do branch, commits, push, PR only.
- "ticket only" — create the issue and move to In Progress. No code, push, or PR.
- "draft PR" — open the PR as a draft (`gh pr create --draft`).
- "skip review" — do not move the issue to In Review at the end.

## Anti-patterns

Bad: hardcode transition names like "In Progress" or "Done".

Good: list the issue transitions and match by keyword. Workflows differ per project.

Bad: run all steps, then report only at the end.

Good: report each step as it completes. Surface failures early.

Bad: one giant commit for unrelated changes.

Good: one conventional commit per unit of work, each with the ticket key.

Bad: continue after a failed push and open a PR anyway.

Good: stop, report what happened, suggest the recovery step.

Bad: create the issue before confirming the plan.

Good: confirm the plan once, then run the outward actions.

## Example

**Task plan**
- Project: PROJ (Bug)
- Summary: Fix token expiry check order
- Branch: proj-311-fix-token-expiry-order  (from main)
- PR: opens against main when work is committed

Proceed? (yes / edit)

> yes

- Created PROJ-311 — https://org.atlassian.net/browse/PROJ-311
- Moved PROJ-311 to In Progress
- Fetched origin/main
- Branch proj-311-fix-token-expiry-order from origin/main
- Commit 1: fix(PROJ-311): check exp before DB lookup
- Pushed proj-311-fix-token-expiry-order
- Opened PR #52 — https://github.com/org/repo/pull/52
- Linked PR to PROJ-311
- Moved PROJ-311 to In Review

**Ticket:** [PROJ-311 Fix token expiry check order](https://org.atlassian.net/browse/PROJ-311) — In Review
**Branch:** proj-311-fix-token-expiry-order
**Commits:** 1
**PR:** [#52 fix(PROJ-311): fix token expiry check order](https://github.com/org/repo/pull/52) — Open
