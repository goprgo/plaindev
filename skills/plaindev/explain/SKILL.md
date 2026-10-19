---
name: plaindev-explain
description: >
  plaindev explain — read a pasted link or text (Jira ticket, Confluence or
  Notion page, GitHub issue or PR, Slack thread, Google Doc, any web page),
  follow its links, and explain the full story in plain words: why the work
  exists, what happened so far, and what needs to be done. Adds examples from
  similar tickets and merged PRs. Ends with gaps, contradictions, and
  questions to clarify. Use when the user invokes /plaindev-explain, says
  "explain this ticket", "what is this about", "give me the context", "break
  this down", or pastes a ticket or doc link and asks what it means or what to
  do.
---

# explain

Read a source. Rebuild the full story behind it. Explain it so the user can start the work without reading the source.

The reader is a developer who has not seen the source before. After reading, they must know 3 things: why the work exists, what exactly to do, and what is still unclear.

Follow the **plaindev-reply** skill for all prose — its hard rules and its "One clear thread" rule. This skill adds the research steps and the output shape.

## Persistence

Active for the source you explain. Stay active for follow-up questions about the same source. Turn off only on explicit user request. After turn-off, stay off for the rest of the session.

## Read-only

This skill only reads. Never post, comment, edit, transition, assign, or react in any source. Never create branches or files in the repo.

## Resolve the source

Pick the source in this order:

1. A link or key the user gave. Example: `PROJ-123`, a Notion URL, a PR URL.
2. Text the user pasted into the chat.
3. If there is neither, ask for one in 1 sentence. Stop.

Several links in 1 message are 1 story. Read them all, and treat the first one as the main source.

Fetch with these tools. Load them with ToolSearch when they are deferred.

| Source | Tool |
|---|---|
| Jira ticket (`PROJ-123` or URL) | Atlassian MCP: get Jira issue |
| Confluence page | Atlassian MCP: get Confluence page |
| Notion page or database | Notion MCP: fetch |
| GitHub issue or PR | `gh issue view` / `gh pr view` with `--comments` |
| Slack message or thread | Slack MCP: read thread or read channel |
| Google Doc, Sheet, or Slides | Google Drive MCP, if connected |
| Figma file | Figma MCP: get design context or metadata |
| Any other web page | WebFetch. If it needs a login, use the built-in browser. |

If a tool fails or is not connected, state the error in 1 sentence. Ask the user to connect the tool or paste the text. Do not invent source content.

## Read the whole story

The main source rarely holds the full story. Read it fully, then follow its links.

**Main source.** Read every part:

- Jira: summary, description, acceptance criteria, status, type, priority, assignee, reporter, labels, components, fix version, and every comment.
- Docs: the whole page, including tables, callouts, and comments if the tool returns them.
- GitHub: body, every comment and review, linked issues, and the changed files list for a PR.
- Slack: every reply in the thread.

**Linked context.** Follow links 1 level deep. Go 2 levels only when level 1 is a thin pointer ("see the epic").

- Parent epic or initiative: why this work exists.
- Linked issues: blocks, is blocked by, duplicates, relates to.
- Specs, designs, PRDs, and RFCs linked in the description or comments.
- Slack threads and meeting notes linked in the comments.

**Timeline.** Note the order of events: who asked for what, and when. Later comments often change the scope. The latest explicit decision wins over the original description. Say so when that happens.

Cap the reading at about 15 linked items. Note any links you skipped in the gaps section.

## Find similar work

Look for 2 to 4 examples that show how similar work was done before. Run the searches in parallel.

**Jira.** Search with JQL. Combine the strongest signals:

- Same epic, component, or label.
- Key words from the summary: `text ~ "<key words>"`.
- Status done or closed: `statusCategory = Done`.
- Order by `updated DESC`.

**GitHub merged PRs.** Search the repo named in the source, or the current repo when you run inside one:

```bash
gh search prs --repo <owner>/<repo> --merged --sort updated --limit 10 "<key words>"
gh pr list --repo <owner>/<repo> --state merged --search "<TICKET-KEY or key words>" --limit 10
```

Search for related ticket keys too. PR titles often carry them, for example `fix(PROJ-120): ...`.

**Local code.** When you run inside the target repo, `git log --oneline --grep="<key word>"` finds commits for older related work.

Keep only examples that help the user do this work. Good examples show the same pattern, the same files, the same API, or the same kind of change. For each example, read enough to say what it shows: the PR description and the changed files list.

If nothing useful turns up, say so and list what you searched. Do not pad the section with weak matches.

## Analyze

Before writing, check the story against itself:

- **Gaps.** What a developer needs but the source does not say. Examples: no acceptance criteria, no error behaviour, no target environment, no owner, a missing design, an unknown data source, no definition of done.
- **Contradictions.** 2 places that say different things. Examples: the description against a later comment, the ticket against the spec, the design against the acceptance criteria, the ticket against how the code works today. Cite both places.
- **To clarify.** Open questions that block the work or change its size. Name who can answer when the source shows it: the reporter, the epic owner, the designer.

Judge each finding on the evidence. Do not list a gap that the linked context already fills.

## Writing rules

- **Facts come from the sources.** Tie each key fact to where it came from: "(description)", "(comment by @anna, 12 Oct)", "(epic PROJ-100)".
- **Mark inferences.** When you conclude something the sources do not state, say "Inferred:" and give the reason.
- **Explain hard terms inline.** Use a few plain words in parentheses on first use. Example: "KYC (identity checks on a new customer)". For a full term breakdown, suggest `/plaindev-layman`.
- **Concrete tasks.** Each task in "What needs to be done" is an action a developer can start. Name the system, screen, endpoint, or file when the sources show it.
- **Never guess an internal name.** If the meaning of an internal system or term is unclear, put it under "To clarify".

## Output shape

Every response uses this shape. Use real clickable links.

```
**TL;DR:** 1 or 2 sentences: what the work is and why it matters.

**Source:** [PROJ-123 Add bond yield to portfolio view](url) · Story · In Progress · @anna
**Also read:** [PROJ-100 epic](url), [Spec](url), [Slack thread](url)

## The story

Why this work exists, what happened so far, and where it stands now.
3 to 8 sentences, in time order. Note any scope change and where it came from.

## What needs to be done

1. Concrete task. (source)
2. Concrete task. (source)
3. Concrete task. (source)

**Done when:** the acceptance criteria, in plain words. Write "Not stated" if the source has none.

**Out of scope:** what the sources exclude. Omit when nothing is excluded.

## Similar work

| Example | What it shows |
|---|---|
| [PROJ-88 Show coupon rate](url) · [PR #41](url) | Same view; added a column with a formatter in `PortfolioTable.tsx` |
| [PR #57 Add maturity sort](url) | How bond data reaches the view from `bonds-api` |

**Searched:** Jira epic PROJ-100, text "bond yield"; merged PRs in org/app for "yield", "bond".

## Gaps, contradictions, and questions

**Gaps**
- Missing fact, and why it matters.

**Contradictions**
- Place A says X. Place B says Y. Which one wins is unclear.

**To clarify**
- Direct question? Ask: @who.
```

Rules for the shape:

- Keep the sections in this order. **Gaps, contradictions, and questions is always the last section.**
- Omit **Also read** when you read only the main source.
- When no similar work is found, keep the section with 1 line: "None found." Add the **Searched** line.
- When a gaps subgroup is empty, write "None found." under it. Do not drop the subgroup.
- Put the most blocking item first in each subgroup.

## Escape hatches

Turn explain off for the rest of the session:

- "stop plaindev explain"
- "stop plaindev" (turns off all plaindev skills)

Change scope for this response only, then resume:

- "story only" — TL;DR and The story. Skip the rest.
- "tasks only" — TL;DR and What needs to be done.
- "no examples" — skip the similar-work search.
- "gaps only" — TL;DR and the last section.
- "go deeper on X" — read more around X and expand that part. Keep the same shape.

## Anti-patterns

Bad: retell the description line by line.

Good: rebuild the story from all sources, in time order, and say what changed.

Bad: "Implement the feature as described."

Good: "Add a `yield` column to the portfolio table. Read it from `GET /bonds/{id}`. (description)"

Bad: list 6 loosely related tickets to fill the table.

Good: 2 examples that show the same pattern, each with what it shows. Or "None found."

Bad: "The ticket might be a bit unclear about some things."

Good: "The description asks for yield to 2 decimals. The design shows 1 decimal. Ask: @designer."

Bad: state an inference as a fact — "The data comes from the bonds service."

Good: "Inferred: the data comes from `bonds-api`. PR #57 fetched maturity dates from there."

Bad: hide the open questions in the middle of the story.

Good: put every gap, contradiction, and question in the last section.

## Example

**TL;DR:** Customers cannot see what their bonds earn. This ticket adds yield and maturity date to each bond in the portfolio view.

**Source:** [FIN-204 Show bond yield and maturity date in portfolio view](https://org.atlassian.net/browse/FIN-204) · Story · To Do · @anna
**Also read:** [FIN-200 Bond insights epic](https://org.atlassian.net/browse/FIN-200), [Figma: Portfolio v3](https://figma.com/file/abc)

## The story

Support gets about 30 calls a month from customers asking what their bonds pay (epic FIN-200). The epic adds bond facts to the app in 3 steps. This ticket is step 1. The description asked for yield only. On 12 Oct, @anna added maturity date in a comment after a call with support. The design shows both fields, so the comment reflects the current scope.

## What needs to be done

1. Add 2 columns to the bond rows in the portfolio table: yield and maturity date. (description, Figma)
2. Show yield as a percent (how much the bond earns per year). (description)
3. Show maturity date (the day the loan is paid back) in the app's date format. (comment by @anna, 12 Oct)
4. Hide both columns for holdings that are not bonds. (Figma)

**Done when:** each bond row shows yield and maturity date, and other holdings show neither. (description)

**Out of scope:** yield history charts. They are step 3 of the epic. (epic FIN-200)

## Similar work

| Example | What it shows |
|---|---|
| [FIN-150 Show coupon rate](https://org.atlassian.net/browse/FIN-150) · [PR #41](https://github.com/org/app/pull/41) | Added a bond-only column to the same table, with a percent formatter |
| [PR #57 Add maturity sort](https://github.com/org/app/pull/57) | Maturity date already reaches the client from `bonds-api` |

**Searched:** Jira epic FIN-200 and text "bond"; merged PRs in org/app for "bond", "yield", "maturity".

## Gaps, contradictions, and questions

**Gaps**
- No source for yield. Inferred: `bonds-api` has it, since it serves other bond fields (PR #57). Not confirmed.
- No empty state. A bond with no yield value has no defined display.

**Contradictions**
- The description asks for 2 decimals. The design shows 1 decimal.

**To clarify**
- Does `bonds-api` return yield, or does the client compute it? Ask: @anna.
- 1 or 2 decimals for yield? Ask: the designer of Portfolio v3.
