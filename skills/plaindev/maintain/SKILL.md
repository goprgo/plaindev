---
name: plaindev-maintain
description: >
  plaindev maintain — work through open review comments on a GitHub pull
  request with gh. Checks access and the local branch, triages every
  unresolved comment (agree, disagree, better idea, unclear), makes and pushes
  the agreed changes, replies, resolves threads, and requests re-review.
  On-demand only: run when the user invokes /plaindev-maintain, says "address
  the PR comments", "resolve review comments", or "handle the review". Do not
  trigger it automatically.
disable-model-invocation: true
---

# maintain

Work through the review comments on a PR until each one has an answer. Agreed comments get a code change. Disagreed comments get a clear reply. Better ideas get a proposal that stays open for the reviewer.

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
   gh pr view <pr> --json number,url,title,state,isDraft,author,baseRefName,headRefName,headRepositoryOwner,isCrossRepository,maintainerCanModify,mergeable,latestReviews,reviewRequests
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

Report preflight as one short block. Mention `mergeable: CONFLICTING` as a warning, not a blocker. It is out of scope for this run.

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

Read the code each comment points to. Read enough around it to judge the comment on its merits. Then give each comment 1 decision:

| Decision | When |
|---|---|
| **Agree** | The comment is right. Make the change. |
| **Disagree** | The comment is wrong, out of scope, or the current code is the better choice. |
| **Better idea** | The comment points to a real problem, but a different fix is better. |
| **Unclear** | You cannot tell what the reviewer wants, or the answer is a product or team decision. Ask the user. |
| **Already done** | The current code already does what the comment asks, for example after a later commit. |

A question from a reviewer ("why X?") is **Disagree** if the answer defends the current code. It is **Agree** if the question exposes a real problem.

Judge on evidence, not on who wrote the comment. Do not agree only to avoid friction. Do not disagree only to avoid work.

Show the triage and ask to proceed:

```
**PR #52 — fix token expiry check order** · 5 open comments

| # | Author | Where | Ask | Decision | Plan |
|---|---|---|---|---|---|
| 1 | @anna | auth.ts:42 | Check exp before DB call | Agree | Move check up |
| 2 | @anna | auth.ts:88 | Rename `tok` | Agree | Rename to `token` |
| 3 | @ben | review body | Add retry on 5xx | Disagree | Caller already retries |
| 4 | @ben | cache.ts:10 | Use a Map here | Better idea | Propose LRU from utils |
| 5 | @coderabbitai[bot] | api.ts:7 | Unused import | Already done | Removed in a1b2c3d |

Unclear: none

Proceed? (yes / edit)
```

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

### Better idea

1. Reply with a proposal. Tag the author (`@login`). Include:
   - Agreement on the problem, in 1 sentence.
   - The proposed fix and why it beats the original ask.
   - Trade-offs, and a short code sketch if it helps.
   - A clear question at the end: "OK to go with this?"
2. Leave the thread open. Resolve only if the user says so.

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
**Pushed:** 2 commits (a1b2c3d, e4f5a6b)

| # | Author | Decision | Result |
|---|---|---|---|
| 1 | @anna | Agree | Fixed in a1b2c3d · resolved |
| 2 | @anna | Agree | Fixed in e4f5a6b · resolved |
| 3 | @ben | Disagree | [Replied](url) · no resolve button |
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

## Example

**Preflight:** gh OK · PR #52 open · on `proj-311-fix-token-expiry` · clean · up to date · tests: `npm test`

**PR #52 — fix token expiry check order** · 2 open comments

| # | Author | Where | Ask | Decision | Plan |
|---|---|---|---|---|---|
| 1 | @anna | auth.ts:42 | Check exp before DB call | Agree | Move check up |
| 2 | @ben | auth.ts:60 | Cache decoded tokens | Better idea | Propose short TTL cache |

Proceed? (yes / edit)

> yes

- Commit a1b2c3d: fix(PROJ-311): check token exp before DB lookup
- Tests passed (`npm test`)
- Pushed proj-311-fix-token-expiry
- #1 replied and resolved
- #2 proposal posted, left open
- Re-review requested from @anna

**PR:** [#52 fix token expiry check order](https://github.com/org/repo/pull/52)
**Pushed:** 1 commit (a1b2c3d)

| # | Author | Decision | Result |
|---|---|---|---|
| 1 | @anna | Agree | Fixed in a1b2c3d · resolved |
| 2 | @ben | Better idea | [Proposed TTL cache](https://github.com/org/repo/pull/52#discussion_r2) · open |

**Re-review requested:** @anna
**Still open:** #2 — waiting on @ben
