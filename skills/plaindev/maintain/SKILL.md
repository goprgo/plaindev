---
name: plaindev-maintain
description: >
  plaindev maintain — work through open review comments on a GitHub pull
  request with gh. Checks access and the local branch, loads the linked ticket
  or spec as the source of truth, triages every unresolved comment against it
  (agree, disagree, better idea, unclear), makes and pushes the agreed changes,
  replies, resolves threads, and requests re-review.
  On-demand only: run when the user invokes /plaindev-maintain, says "address
  the PR comments", "resolve review comments", or "handle the review". Do not
  trigger it automatically.
disable-model-invocation: true
---

# maintain

Work through the review comments on a PR until each one has an answer. Agreed comments get a code change. Disagreed comments get a clear reply. Better ideas get a proposal that stays open for the reviewer.

The ticket or spec behind the PR is the **source of truth**. Review comments are claims to check against it, not orders. See [Source of truth](#source-of-truth).

Follow the **plaindev-reply** skill for prose — to the user and in GitHub replies. This skill adds the workflow and output shape.

## Autonomy

Confirm the triage once, then run. Show the triage table (see below). After the user approves, run every step without more prompts. Pause only when a step fails or a comment turns out to need a decision from the user.

Never skip the triage gate. It is the one confirmation before outward actions (push, reply, resolve, re-review request). The user can skip it for one run with "no confirm".

## Preflight

Run these checks before triage. Stop on the first failure and report it with the fix.

1. **gh works.** `gh auth status` succeeds. If not, tell the user to run `gh auth login`.
2. **Repo root.** `git rev-parse --show-toplevel` equals the current directory. If not, say where the root is and stop.
3. **PR resolved.** Pick the target in this order:
   1. PR number or URL the user gave.
   2. PR for the current branch: `gh pr view --json number,url`.
   3. None found: say so in one sentence and stop.
4. **PR is open.** Read the PR once:

   ```bash
   gh pr view <pr> --json number,url,title,body,state,isDraft,author,baseRefName,headRefName,headRepositoryOwner,isCrossRepository,maintainerCanModify,mergeable,latestReviews,reviewRequests
   ```

   Stop if `state` is not `OPEN`. For a fork PR (`isCrossRepository`), push works only if you own the fork or `maintainerCanModify` is true. Otherwise stop.
5. **Same repo.** `gh repo view --json nameWithOwner` matches the PR repo. A PR URL from another repo means the wrong folder.
6. **Clean tree.** `git status --porcelain` is empty. If dirty, ask whether to stash or stop.
7. **Right branch.** The current branch is the PR head branch. If not, run `gh pr checkout <pr>`. It sets the push remote, including for forks.
8. **Up to date.** `git fetch` the head branch, then compare with `git status -sb`.
   - Behind: `git pull --ff-only`.
   - Diverged: stop. Show both sides and let the user decide.
9. **Git identity.** `git config user.name` and `user.email` are set. If only set globally, show them and ask once. If unset, stop.
10. **Know yourself.** `gh api user -q .login` gives your login. Use it to skip your own comments and to spot threads you already answered.
11. **Repo checks.** Find the repo's test and lint commands (README, `package.json`, `Makefile`, CI config). Note them for the verify step. Do not run them yet.
12. **Source of truth.** Find and read the requirements behind the PR. See [Load the requirements](#load-the-requirements).

Report preflight as one short block. Mention `mergeable: CONFLICTING` as a warning, not a blocker. It is out of scope for this run.

## Source of truth

The original requirements decide what the PR must do. Requirements are the ticket description, its acceptance criteria, and any spec it links. Review feedback does not change them.

Rules:

- **Requirements win.** If a comment conflicts with the requirements, the requirements win.
- **Feedback is a claim.** Check every comment against the requirements before you act on it. This applies to colleagues and to agents or bots alike.
- **Labels are claims too.** "Blocker", "critical", "major", or `CHANGES_REQUESTED` do not make a comment right. Compare it with the requirements first.
- **Silent requirements.** If the requirements say nothing on the point, judge the comment on the code and the evidence.
- **Gaps count.** If a comment shows the PR misses a requirement, it is **Agree**, whatever its label.

Requirements change only on an explicit signal:

- The ticket itself asks for it. Examples: an open question, a "TBD", or "reviewer to decide" on that point.
- A ticket comment or spec update from the ticket owner changes the scope.
- The user says so in chat.

A reviewer saying "the ticket is wrong" is not an explicit signal. Mark it **Unclear** and ask the user. Do not change the code on the reviewer's word alone.

### Load the requirements

Find the ticket or spec in this order:

1. A ticket key or URL the user gave.
2. A ticket key in the PR title, PR body, or head branch name. Example: `AT-5180` in `fix(AT-5180): ...` or `at-5180-fix-totals`.
3. A spec or design doc linked in the PR body, or a spec file the PR changes.

Read a Jira ticket with the Atlassian MCP tools. Load them with ToolSearch (query "atlassian jira"). Read the description, acceptance criteria, linked specs, and the latest comments. Comments can carry explicit scope changes.

If no source is found, or the tools do not load, say so in preflight. Ask once for a ticket key or spec link. If the user has none, triage on code and evidence only, and note "no ticket" in the summary.

## Collect comments

Fetch 3 kinds of feedback. Run the calls in parallel.

**Review threads** (inline comments on code). These can be resolved.

```bash
gh api graphql -F owner=<owner> -F repo=<repo> -F pr=<number> -f query='
query($owner:String!,$repo:String!,$pr:Int!){
  repository(owner:$owner,name:$repo){
    pullRequest(number:$pr){
      reviewThreads(first:100){
        nodes{
          id isResolved isOutdated path line
          comments(first:50){
            nodes{ databaseId url body createdAt author{ login __typename } }
          }
        }
      }
    }
  }
}'
```

**Review summaries** (the text a reviewer writes when they submit a review): `gh api repos/<owner>/<repo>/pulls/<number>/reviews --paginate`. Keep only those with a non-empty `body`. Use `html_url` as the link.

**Top-level comments** (the PR conversation tab): `gh pr view <pr> --json comments`. Use `url` as the link.

Review summaries and top-level comments have no resolve button. This skill calls them **unresolvable feedback**.

GitHub state is the only memory between runs. Do not keep a local state file. The filters below decide what is still open.

Then filter:

- **Skip** resolved threads.
- **Skip** comments by you.
- **Skip** threads where the last comment is yours. You already answered. The reviewer has not replied yet.
- **Skip** unresolvable feedback if a later top-level comment by you contains its link. You already answered it.
- **Skip** top-level comments with no request or question (thanks, CI links, bot status reports).
- **Keep** outdated threads (`isOutdated`), but check whether the current code already fixes them.
- **Mark** bot authors (`__typename` is `Bot`, or the login ends in `[bot]`). Treat their comments the same way. Never tag or re-request review from a bot.

Read the whole thread, not only the first comment. A later reply often changes the request.

## Triage

Read the code each comment points to. Read enough around it to judge the comment on its merits. Then check the comment against the requirements. Give it 1 spec status:

| Spec | When |
|---|---|
| **Fits** | The ask matches the requirements, or closes a gap in them. |
| **Conflicts** | The ask contradicts the requirements. |
| **Silent** | The requirements do not cover the point. |

Then give each comment 1 decision:

| Decision | When |
|---|---|
| **Agree** | The comment is right. Make the change. |
| **Disagree** | The comment is wrong, out of scope, conflicts with the requirements, or the current code is the better choice. |
| **Better idea** | The comment points to a real problem, but a different fix is better. |
| **Unclear** | You cannot tell what the reviewer wants, or the answer is a product or team decision. Ask the user. |
| **Already done** | The current code already does what the comment asks, for example after a later commit. |

A question from a reviewer ("why X?") is **Disagree** if the answer defends the current code. It is **Agree** if the question exposes a real problem.

Judge on evidence, not on who wrote the comment. Do not agree only to avoid friction. Do not disagree only to avoid work.

A **Conflicts** comment is **Disagree** by default, even if it claims a blocker. It becomes **Agree** only on an explicit signal from [Source of truth](#source-of-truth). If the reviewer argues the requirements are wrong, mark it **Unclear** and ask the user.

Show the triage and ask to proceed:

```
**PR #52 — fix token expiry check order** · [PROJ-311](url) · 5 open comments

| # | Author | Where | Ask | Spec | Decision | Plan |
|---|---|---|---|---|---|---|
| 1 | @anna | auth.ts:42 | Check exp before DB call | Fits | Agree | Move check up |
| 2 | @anna | auth.ts:88 | Rename `tok` | Silent | Agree | Rename to `token` |
| 3 | @ben | review body | Blocker: return 401 on expiry | Conflicts | Disagree | Ticket AC 2 asks for 403 |
| 4 | @ben | cache.ts:10 | Use a Map here | Silent | Better idea | Propose LRU from utils |
| 5 | @coderabbitai[bot] | api.ts:7 | Unused import | Silent | Already done | Removed in a1b2c3d |

Unclear: none

Proceed? (yes / edit)
```

For each **Conflicts** row, quote the requirement it conflicts with under the table. The user then sees why the reviewer's claim loses.

For each **Unclear** item, ask one direct question under the table. Wait for the answer, then fold it into the decisions.

## Apply changes

For each **Agree** item, in file order:

1. **Make the change.** If the reviewer left a GitHub suggestion block, apply it as written unless it is wrong. Keep the change to what the comment asks.
2. **Commit.** One commit per comment, or one per group of comments that touch the same concern. Match the repo commit style from `git log --oneline -20`. Say what changed, not "address review".
3. **Record** the short commit SHA against the comment. The reply step needs it.

Do not amend, squash, or force-push. New commits let reviewers see exactly what changed since their review.

## Verify

Run the test and lint commands found in preflight, if any. If a check fails because of your change, fix it and commit the fix. If it fails on code you did not touch, note it and continue.

## Push

`git push` once, after all changes and checks. If the push is rejected, stop. Do not force-push. Report the rejection and suggest `git pull --rebase` for the user to review.

## Reply and resolve

Work through every triaged item. Write each reply body to a file in the scratchpad directory, then pass it with `-F body=@<file>`. This keeps multi-line markdown intact.

Reply to a review thread:

```bash
gh api graphql -f query='
mutation($id:ID!,$body:String!){
  addPullRequestReviewThreadReply(input:{pullRequestReviewThreadId:$id,body:$body}){ comment{ url } }
}' -f id=<thread-id> -F body=@reply.md
```

Resolve a review thread:

```bash
gh api graphql -f query='
mutation($id:ID!){
  resolveReviewThread(input:{threadId:$id}){ thread{ isResolved } }
}' -f id=<thread-id>
```

Reply to unresolvable feedback with 1 top-level comment per item:

```bash
gh pr comment <pr> --body-file reply.md
```

Start the reply with a short quote of the original and its link. The link marks the item as answered for the next run.

Unresolvable feedback follows the same decisions below, with 2 differences:

- Skip every "Resolve" step. There is no resolve button.
- Always reply, also for **Agree**. The reply is the only sign that the item is handled.

### Agree

1. Reply only when it adds something. Good reasons: the fix differs from the literal suggestion, the change also touched other places, or the reason is not obvious. Keep it to 1 or 2 lines and include the SHA: `Done in a1b2c3d. Moved the exp check above the DB lookup, and did the same in refresh().`
2. Resolve the thread.
3. Add the human author to the re-review list.

### Already done

1. Reply with 1 line and the SHA or file line that covers it.
2. Resolve the thread.

### Disagree

1. Reply with a full explanation. The reviewer must be able to accept it without opening the code. Include:
   - The position in 1 sentence first.
   - The reason, with evidence: code links (permalinks with the head SHA), docs, test results, or numbers.
   - What would change your mind, if anything.
2. Resolve the thread.

### Disagree: conflicts with the requirements

This is a **Disagree** where the spec status is **Conflicts**. The reply must be comprehensive. The reviewer and anyone reading the PR later must see the full reasoning in the thread. Include, in this order:

1. **Position.** 1 sentence: the PR keeps the current behaviour because the requirements ask for it.
2. **Requirement.** Link the ticket or spec. Quote the exact line, acceptance criterion, or section that applies.
3. **Conflict.** Explain how the requested change contradicts that requirement. Say what would break or which criterion would fail.
4. **Current code.** Show how the code meets the requirement, with permalinks at the head SHA.
5. **Severity claim.** If the reviewer called it a blocker or major issue, address that directly. Say why it is not a blocker against the requirements as written.
6. **Way forward.** If the requirement should change, the ticket must change first. Name the ticket owner if known. Say the code will follow once the ticket is updated.

Then resolve the thread, as for any **Disagree**. Example:

```markdown
Keeping 403 here. [PROJ-311](https://org.atlassian.net/browse/PROJ-311) asks for it.

> AC 2: An expired token returns 403 with `error: token_expired`.

Returning 401 would fail AC 2. The web client treats 401 as "logged out" and drops the refresh token. That is the bug PROJ-311 fixes.

The current code returns 403 in [auth.ts#L42](https://github.com/org/repo/blob/a1b2c3d/src/auth.ts#L42). The test is in [auth.test.ts#L80](https://github.com/org/repo/blob/a1b2c3d/src/auth.test.ts#L80).

This is not a blocker against the ticket as written. If 401 is the right call, please raise it on PROJ-311 with @carol. I will update the code once the ticket changes.
```

### Better idea

1. Reply with a proposal. Tag the author (`@login`). Include:
   - Agreement on the problem, in 1 sentence.
   - The proposed fix and why it beats the original ask.
   - Trade-offs, and a short code sketch if it helps.
   - A clear question at the end: "OK to go with this?"
2. Leave the thread open. Resolve only if the user says so.

### Bot and reviewer-tool threads

Resolve a thread after its fix is pushed, whoever wrote it, bots included. A
bot's footer about resolving ("resolving waives this finding", "the bot reopens
threads that others resolve") covers waiving a finding that is still in the
code. It does not apply to a fixed finding, so it is no reason to leave a fixed
thread open. If the bot reopens a thread after a fix, report that in the
summary. Do not resolve it again.

Leave a thread open only for **Better idea**, or when the user asks.

## Request re-review

After the replies, request review again from each human who asked for a change that you made:

```bash
gh pr edit <pr> --add-reviewer <login1>,<login2>
```

Request once per person, not once per comment. Skip bots and skip yourself. Skip people whose only items were **Disagree** or **Better idea**, unless their latest review state is `CHANGES_REQUESTED`. That state blocks the merge until they review again.

## Reply style

Replies go to people on GitHub, so write for them:

- Plain words, short sentences, answer first. Follow the **plaindev-reply** rules.
- Neutral and direct. No apologies, no thanks-for-the-catch filler.
- Code refs as permalinks: `https://github.com/<owner>/<repo>/blob/<sha>/<path>#L<line>`.
- Never mention an AI or this skill in a reply.

## Output shape

Report each step in 1 line as it completes. End with this summary. Use real clickable links.

```
**PR:** [#52 fix token expiry check order](url)
**Ticket:** [PROJ-311](url)
**Pushed:** 2 commits (a1b2c3d, e4f5a6b)

| # | Author | Decision | Result |
|---|---|---|---|
| 1 | @anna | Agree | Fixed in a1b2c3d · resolved |
| 2 | @anna | Agree | Fixed in e4f5a6b · resolved |
| 3 | @ben | Disagree (conflicts with AC 2) | [Replied](url) · no resolve button |
| 4 | @ben | Better idea | [Proposed LRU](url) · open |
| 5 | @coderabbitai[bot] | Already done | [Replied](url) · resolved |

**Re-review requested:** @anna
**Still open:** #4 — waiting on @ben
```

## Failure handling

If any step fails:

1. Stop. Do not run later steps.
2. State the failed step and the exact error in 1 or 2 sentences.
3. List what already happened: commits made, pushed or not, replies posted, threads resolved. Link each one.
4. Suggest the 1 next action to recover.

A failed reply or resolve for 1 thread is not a full stop. Report it, continue with the rest, and list it at the end.

Do not invent thread IDs, SHAs, or URLs. Read them from the tool output.

## Escape hatches

Turn maintain off for the rest of the session:

- "stop plaindev maintain"
- "stop plaindev" (turns off all plaindev skills)

Scope changes for 1 run:

- "dry run" — preflight and triage only. No commits, push, replies, or resolves.
- "no confirm" — skip the triage gate.
- "only @login" — handle comments from that reviewer only.
- "no push" — commit locally, then stop before push and replies.
- "resolve proposals" — also resolve **Better idea** threads after replying.
- "skip re-review" — do not request review again.
- "no ticket" — skip loading the requirements. Triage on code and evidence only.

## Anti-patterns

Bad: push after every single fix.

Good: commit per comment, push once, then reply with the SHAs.

Bad: resolve a thread before the fix is pushed.

Good: push first. The reply links a commit that exists on GitHub.

Bad: reply "Done" to every agreed comment.

Good: reply only when the reply tells the reviewer something new.

Bad: "I think maybe this could possibly be fine as is?"

Good: "Keeping the current order. The caller at `client.ts:30` already retries on 5xx, so a second retry doubles the load."

Bad: force-push a rebased branch mid-review.

Good: add new commits. Reviewers see only what changed since their review.

Bad: agree with every comment to finish faster.

Good: judge each comment on the code and the evidence.

Bad: change the code because a reviewer or bot labelled the comment "blocker".

Good: compare the comment with the ticket. If they conflict, keep the code and reply with the requirement quoted.

Bad: reply "This is out of scope" to a comment that conflicts with the ticket.

Good: link the ticket, quote the requirement, explain the conflict, and say how to change the ticket.

## Example

**Preflight:** gh OK · PR #52 open · on `proj-311-fix-token-expiry` · clean · up to date · tests: `npm test` · ticket: PROJ-311 read

**PR #52 — fix token expiry check order** · [PROJ-311](https://org.atlassian.net/browse/PROJ-311) · 3 open comments

| # | Author | Where | Ask | Spec | Decision | Plan |
|---|---|---|---|---|---|---|
| 1 | @anna | auth.ts:42 | Check exp before DB call | Fits | Agree | Move check up |
| 2 | @ben | auth.ts:60 | Cache decoded tokens | Silent | Better idea | Propose short TTL cache |
| 3 | @review-agent[bot] | auth.ts:47 | Major: return 401 on expiry | Conflicts | Disagree | Reply with AC 2 |

#3 conflicts with PROJ-311 AC 2: "An expired token returns 403 with `error: token_expired`."

Proceed? (yes / edit)

> yes

- Commit a1b2c3d: fix(PROJ-311): check token exp before DB lookup
- Tests passed (`npm test`)
- Pushed proj-311-fix-token-expiry
- #1 replied and resolved
- #2 proposal posted, left open
- #3 replied with AC 2 and resolved
- Re-review requested from @anna

**PR:** [#52 fix token expiry check order](https://github.com/org/repo/pull/52)
**Ticket:** [PROJ-311](https://org.atlassian.net/browse/PROJ-311)
**Pushed:** 1 commit (a1b2c3d)

| # | Author | Decision | Result |
|---|---|---|---|
| 1 | @anna | Agree | Fixed in a1b2c3d · resolved |
| 2 | @ben | Better idea | [Proposed TTL cache](https://github.com/org/repo/pull/52#discussion_r2) · open |
| 3 | @review-agent[bot] | Disagree (conflicts with AC 2) | [Replied](https://github.com/org/repo/pull/52#discussion_r3) · resolved |

**Re-review requested:** @anna
**Still open:** #2 — waiting on @ben
