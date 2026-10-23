---
name: plaindev-explain
description: >
  plaindev explain — read a pasted link or text (Jira ticket, Confluence or
  Notion page, GitHub issue or PR, Slack thread, Google Doc, any web page),
  research the related docs, tickets, and threads, and explain what the
  feature or topic is about in plain, non-technical words. Combines what the
  company's systems say with general knowledge, so a product owner or a new
  joiner understands it without effort. Lists the related resources with
  short notes, and explains only the domain terms a reader would not know.
  Use when the user invokes /plaindev-explain, says "explain this ticket",
  "what is this about", "give me the context", or pastes a ticket or doc link
  and asks what it means.
---

# explain

Read a source. Research everything related to it. Explain what it is about in plain, non-technical words.

The goal is **understanding before action**. The user must get a good overall picture of the task, spec, or doc before they commit to any change or decision.

The reader is a product owner or a new joiner. They are smart, but they do not know the codebase, the team history, or the domain. Write so both understand it on the first read.

Follow the **plaindev-reply** skill for all prose — its hard rules and its "One clear thread" rule. This skill adds the research steps and the output shape.

## Persistence

Active for the source you explain. Stay active for follow-up questions about the same source. Turn off only on explicit user request. After turn-off, stay off for the rest of the session.

## Read-only

This skill only reads. Never post, comment, edit, transition, assign, or react in any source.

## Resolve the source

Pick the source in this order:

1. A link or key the user gave. Example: `PROJ-123`, a Notion URL, a PR URL.
2. Text the user pasted into the chat.
3. If there is neither, ask for one in 1 sentence. Stop.

Several links in 1 message are 1 topic. Read them all, and treat the first one as the main source.

Fetch with these tools. Load them with ToolSearch when they are deferred.

| Source | Tool |
|---|---|
| Jira ticket (`PROJ-123` or URL) | Atlassian MCP: get Jira issue |
| Confluence page | Atlassian MCP: get Confluence page |
| Notion page or database | Notion MCP: fetch |
| GitHub issue or PR | `gh issue view` / `gh pr view` with `--comments` |
| Slack message or thread | Slack MCP: read thread or read channel |
| Google Doc, Sheet, or Slides | Google Drive MCP, if connected |
| Figma file | Figma MCP: get metadata or screenshot |
| Any other web page | WebFetch. If it needs a login, use the built-in browser. |

If a tool fails or is not connected, state the error in 1 sentence. Ask the user to connect the tool or paste the text. Do not invent source content.

## Research

Build the full picture from 3 kinds of input.

**1. The source.** Read all of it: description, acceptance criteria, status, owner, and every comment. Later comments often change the scope.

**2. Related material in the company's systems.** Follow the links in the source. Then search for more with the key words and names from the source. Run the searches in parallel.

- **Jira:** parent epic, linked issues, and tickets with the same epic, label, or key words.
- **Notion:** pages and databases that mention the feature, product, or client. Specs, PRDs, meeting notes, and decision logs matter most.
- **Confluence:** specs, design docs, and runbooks on the topic.
- **Slack:** threads that discuss the feature or link the ticket.
- **GitHub:** only when the source is a PR or issue, or links one.

Skip search tools that are not connected. Note them in the summary. Cap the reading at about 15 items. Prefer the newest and most official material: an approved spec beats an old brainstorm.

**3. General knowledge.** Use what you know about the domain, the industry, and common product patterns. It explains what the company docs take for granted. Example: what a bond yield is, why banks run identity checks, how a subscription refund usually works.

Keep the 3 inputs apart. Company facts come from the sources. General knowledge explains the background. Never present general knowledge as a company decision.

## Writing rules

- **Non-technical.** No code, file names, endpoints, or system internals. Say what a thing does for people, not how it is built. If a technical fact matters to the picture, say it in everyday words: "the app gets this number from another system".
- **Big picture first.** What it is and why it exists come before any detail.
- **Short.** The reader should finish in about 2 minutes. Aim for 300 to 500 words, not counting the resource list and terms.
- **Name the source of key facts.** Add a short tag: "(ticket)", "(Notion spec)", "(comment by @anna)". Mark general knowledge with "In general, ..." or "Across the industry, ...".
- **Mark inferences.** When you conclude something the sources do not state, say "Likely:" and give the reason in a few words.
- **Never guess an internal name.** If the meaning of an internal system, team, or term is unclear, say so under "Worth knowing before you decide".

## Terms

Add a terms section only for terms that meet both tests:

- **Domain-specific.** The term belongs to the topic's field or to the company. Examples: "coupon" in a bond ticket, "KYC" in an onboarding spec, an internal product name.
- **Not common.** A product owner or new joiner would likely not know it.

Skip everyday words, common tech words (app, login, dashboard, API), and words the explanation already makes clear. Usually 0 to 5 terms qualify. If none qualify, omit the section.

Order the terms by first appearance. If term B is needed to understand term A, put B first.

## Output shape

Every response uses this shape. Use real clickable links.

```
**TL;DR:** 1 or 2 sentences: what this is and why it matters.

**Source:** [PROJ-123 Add bond yield to portfolio view](url) · Story · In Progress · @anna

## What it is

The feature or topic in plain words. What changes for the user or the business.
2 to 5 sentences.

## Why it exists

The problem or goal behind it, who asked, and the bigger plan it belongs to.
Add general background when it helps the reader understand. 2 to 5 sentences.

## How it works

The flow in everyday words, from the user's point of view. 3 to 6 short steps or sentences.

## Where it stands

Status, owner, what is decided, and what changed along the way. 1 to 4 sentences.

## Key terms

### Term (full form of the acronym, if any)

**One plain sentence: what the term means.**

**Example:** A real-life example or comparison, in 1 or 2 sentences.

**Here:** What it means in this topic. 1 sentence.

## Related resources

**Jira**
- [PROJ-100 Bond insights epic](url) — the parent plan; this ticket is step 1 of 3.

**Notion**
- [Bond insights PRD](url) — the approved spec; sections 2 and 4 cover this feature.

**Slack**
- [#support thread, 12 Oct](url) — where the request for maturity dates came from.

**Searched:** Jira, Notion, Slack. Not connected: Confluence.

## Worth knowing before you decide

- Open question, gap, or contradiction, in 1 line. Ask: @who.
```

Rules for the shape:

- Keep the sections in this order.
- Merge **How it works** into **What it is** when the topic is a simple fix or a short doc.
- Omit **Key terms** when no term passes both tests.
- In **Related resources**, group links by system. Give each link a short note: what it is and why it matters here. Put the most useful link first in each group. Omit empty groups.
- **Worth knowing before you decide** has at most 5 items, most important first. Omit it when nothing is open.

## Escape hatches

Turn explain off for the rest of the session:

- "stop plaindev explain"
- "stop plaindev" (turns off all plaindev skills)

Change scope for this response only, then resume:

- "short" — TL;DR, What it is, and Related resources only.
- "no research" — explain the source alone. Skip the search for related material.
- "no terms" — skip Key terms.
- "more technical" — allow system names and technical detail for this response.
- "go deeper on X" — research more around X and expand that part. Keep the same shape.

## Anti-patterns

Bad: retell the ticket line by line.

Good: explain what the feature does for people and why it exists, in 1 short paragraph each.

Bad: "Add a `yield` field to `PortfolioRow` from `GET /bonds/{id}`."

Good: "Each bond in the portfolio will show how much it earns per year."

Bad: define every word — "Portfolio: a list of investments."

Good: define only the domain terms a new joiner would not know, like "coupon" or "maturity date".

Bad: "The bank decided to hide yields for retail clients." (from general knowledge)

Good: "In general, banks show yields to all clients. The sources do not say what this team decided."

Bad: a bare list of 10 links.

Good: the 3 to 6 most useful links, grouped by system, each with a short note.

## Example

**TL;DR:** Customers cannot see what their bonds earn or when they end. This feature shows both facts for each bond in the app, to cut support calls.

**Source:** [FIN-204 Show bond yield and maturity date in portfolio view](https://org.atlassian.net/browse/FIN-204) · Story · To Do · @anna

## What it is

The app shows each customer a list of everything they invest in. For bonds, this list will show 2 new facts: how much the bond earns per year, and the day it ends. Other investments, like shares, stay as they are. (ticket)

## Why it exists

Support gets about 30 calls a month from customers who ask what their bonds pay (Notion PRD). Showing the facts in the app answers those questions before customers call. This feature is step 1 of a 3-step plan to give bond holders more insight (epic FIN-200). In general, investment apps show these 2 facts, so customers may expect them already.

## How it works

1. The customer opens their portfolio in the app.
2. Each bond shows its yearly earnings as a percent.
3. Next to it, the app shows the date the bond ends and the money comes back.
4. Shares and funds show neither fact, since they do not have them.

## Where it stands

Not started. @anna owns it. The first version asked for yearly earnings only. After a talk with support on 12 Oct, @anna added the end date (comment by @anna).

## Key terms

### Bond

**A loan you give to a company or a government, which pays you back with extra money.**

**Example:** You lend a city $1,000. The city pays you $50 every year. After 5 years, you get your $1,000 back.

**Here:** Some customers hold bonds. Only bonds get the 2 new facts.

### Yield

**How much a bond earns you each year, as a percent of what you paid.**

**Example:** You pay $1,000 for a bond that pays $50 a year. The yield is 5%.

**Here:** The first of the 2 new facts in the app.

### Maturity date

**The day the borrower must pay back the full loan.**

**Example:** Like the last payment date on a car loan.

**Here:** The second new fact. It tells customers when their money comes back.

## Related resources

**Jira**
- [FIN-200 Bond insights epic](https://org.atlassian.net/browse/FIN-200) — the 3-step plan; this ticket is step 1.
- [FIN-150 Show coupon rate](https://org.atlassian.net/browse/FIN-150) — an earlier, similar change to the same screen. Done in August.

**Notion**
- [Bond insights PRD](https://notion.so/org/bond-insights) — the approved spec, with the support call numbers.

**Slack**
- [#support thread, 12 Oct](https://org.slack.com/archives/C1/p1) — where the request for the end date came from.

**Searched:** Jira, Notion, Slack. Not connected: Confluence.

## Worth knowing before you decide

- The ticket says 2 decimals for the percent. The design shows 1. Ask: @anna.
- No source says what to show when a bond has no yield value.
