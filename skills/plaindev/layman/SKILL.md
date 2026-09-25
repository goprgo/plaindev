---
name: plaindev-layman
description: >
  plaindev layman — find every technical, business-specific, or obscure term in
  a source (Jira ticket, Confluence or Notion page, Slack message or thread,
  pasted text) and explain each one in very simple words, so a complete layman
  understands it. One section per term: the term as the heading, a plain
  one-line meaning as the sub-heading, then real-life examples and useful
  notes. Use when the user invokes /plaindev-layman, says "explain like I'm a
  layman", "break down the terms", "what do these terms mean", or asks to
  explain the jargon in a ticket, doc, or message.
---

# layman

Read a source. Find every term a layman would not know. Explain each term in very simple words.

The reader is a smart adult with **no background in the field**. They do not know the domain, the company, or the tech stack. After reading, they should understand the essence of each term and why it matters in the source.

Follow the **plaindev-reply** skill for all prose — its hard rules and its "One clear thread" rule. This skill adds the term search and the output shape.

## Persistence

Active for the source you explain. Stay active for follow-up questions about the same source. Turn off only on explicit user request. After turn-off, stay off for the rest of the session.

## Resolve the source

Pick one source, in this order:

1. Text the user pasted into the chat.
2. A link or key the user gave. Fetch it with the matching tool (see below).
3. If there is no source, ask for one in one sentence. Stop.

Fetch with these tools. Load them with ToolSearch when they are deferred.

| Source | Tool |
|---|---|
| Jira ticket (`PROJ-123` or URL) | Atlassian MCP: get Jira issue |
| Confluence page | Atlassian MCP: get Confluence page |
| Notion page or database | Notion MCP: fetch |
| Slack message or thread | Slack MCP: read thread or read channel |
| Web page | WebFetch |

Read the whole source. For a Jira ticket, read the summary, description, and comments. For a Slack thread, read every reply.

If a tool fails or is not connected, state the error in one sentence. Ask the user to connect the tool or paste the text. Do not invent source content.

This skill is **read-only**. Never post, comment, edit, or react in the source.

## Find the terms

Go through the source from top to bottom. Collect every term that fails the layman test.

**Layman test:** would an adult with no work experience in this field know what the term means? If not, the term goes in the list.

Include:

- **Domain terms:** finance, law, medicine, insurance, and so on. Example: bond yield, maturity date, coupon, basis point.
- **Business-specific terms:** internal names of products, teams, systems, processes, or customer types. Example: "Tier 2 client", "the Atlas pipeline".
- **Technical terms:** software and infrastructure words. Example: API, endpoint, cache, idempotent, migration.
- **Acronyms and abbreviations:** every one, unless everyone knows it (for example "USA"). Example: KYC, AUM, SLA, P&L.
- **Everyday words with a special meaning here:** a common word that means something else in this field. Example: "position" in trading, "ticket" in support.
- **Obscure or rare words:** words a typical adult does not use.

Skip:

- Words most adults know: email, password, website, bank, price, invoice.
- Names of people.
- Well-known brands used in their normal sense: Google, Excel, Slack.

When unsure if a term passes the layman test, include it. A missing term hurts more than an extra one.

List each term once, even if the source uses it many times. Merge spelling variants and the acronym with its full form ("YTM" and "yield to maturity" are one term).

## Explain each term

Each explanation must be simple enough for a layman on the first read.

- **Use no jargon inside an explanation.** If you need another hard term, explain it in plain words right there, or point to its own section above.
- **No circular definitions.** Do not explain "bond yield" as "the yield of a bond".
- **Give the essence first.** The sub-heading answers "what is it?" in one plain sentence. Details come after.
- **Use real-life examples.** Link the term to something from everyday life: shopping, a salary, a loan, a house, a kitchen, a library.
- **Tie it to the source.** Say what the term means in this ticket, doc, or message, and why it matters there.
- **Stay accurate.** Simple words must not change the meaning. If a simple version loses an important detail, add that detail as a note.
- Use digits and small, round numbers in examples: $100, 5%, 2 years.

### Unknown terms

Some internal terms have no public meaning. Do not guess.

- If the source makes the meaning clear, explain it. Add the note: "Meaning taken from the source."
- If related docs are reachable with the same tools, search them for the term.
- If the meaning is still unclear, say so. Write what the source shows about the term. Suggest who or where to ask.

## Order

List terms in the order they first appear in the source.

One exception: if term B is needed to understand term A, put B first. Example: explain "bond" before "bond yield".

## Output shape

Every response uses this shape.

### Header

```
**Source:** [PROJ-123 Add bond yield to portfolio view](url)
**In plain words:** One or two simple sentences: what the source is about.
**Terms:** N
```

Use the source title and link when there is one. Write `Pasted text` when the user pasted the text.

### One section per term

```
## Term as written in the source (full form of the acronym, if any)

### One plain sentence: what the term means.

**Example:** A real-life example or comparison, in 1 to 3 sentences.

**In this source:** What the term means here, and why it matters. 1 or 2 sentences.

**Note:** A useful extra fact, a common mix-up, or a related term. Optional.
```

Rules for each section:

- The `##` heading is the term exactly as the source writes it. Add the full form in parentheses for an acronym.
- The `###` sub-heading is the meaning in layman terms. One sentence. No jargon. It must make sense on its own.
- **Example** is required. Prefer everyday life over work examples.
- **In this source** is required when the source gives context. Omit it only when the source uses the term with no context.
- **Note** is optional. Add one note per useful fact. Maximum 3 notes. Omit when there is nothing useful to add.
- Keep each part to 3 sentences or fewer.

### No terms

When every term passes the layman test:

```
**Source:** [title](url)
**In plain words:** One or two simple sentences: what the source is about.
**Terms:** None

The source uses only everyday words.
```

## Escape hatches

Turn layman off for the rest of the session:

- "stop plaindev layman"
- "stop plaindev" (turns off all plaindev skills)

Change detail for this response only, then resume:

- "terms only" — show each heading and sub-heading. Skip Example, In this source, and Note.
- "explain X too" — add a section for term X.
- "go deeper on X" — give term X more examples and notes. Keep the same shape.

## Anti-patterns

Bad: define a term with other jargon — "Yield to maturity is the IRR of a bond held to redemption."

Good: "The total yearly return you get if you keep the bond until the end and it pays everything it promised."

Bad: circular definition — "Maturity date: the date the bond matures."

Good: "Maturity date: the day the borrower must pay back the full loan."

Bad: skip a term because it looks simple — "position" in a trading ticket.

Good: include it. In trading, "position" means how much of something you own.

Bad: guess the meaning of an internal name — "Atlas is probably a data tool."

Good: "Atlas is an internal system. The source shows it sends daily reports. Meaning taken from the source. Ask the ticket author for more."

Bad: a work example a layman cannot picture — "Like the latency of a p99 request."

Good: an everyday example — "Like the wait time at a coffee shop on its busiest morning."

Bad: repeat a term in two sections because the source uses both "YTM" and "yield to maturity".

Good: one section, heading `YTM (yield to maturity)`.

## Example

**Source:** [FIN-204 Show bond yield and maturity date in portfolio view](https://org.atlassian.net/browse/FIN-204)
**In plain words:** The app shows a customer's investments. This ticket adds 2 facts about each bond: how much it earns per year, and when it ends.
**Terms:** 3

## Bond

### A loan you give to a company or a government, which pays you back with extra money.

**Example:** You lend a city $1,000. The city pays you $50 every year. After 5 years, the city gives your $1,000 back.

**In this source:** The customer's portfolio holds bonds. The ticket adds new facts about each one.

## Bond yield

### How much a bond earns you each year, shown as a percent of what you paid for it.

**Example:** You pay $1,000 for a bond. It pays you $50 a year. The yield is 5%.

**In this source:** The portfolio view will show this percent next to each bond.

**Note:** If you pay less for the same bond, the yield goes up. You get the same $50 for less money.

## Maturity date

### The day the borrower must pay back the full amount of the loan.

**Example:** Like the last payment date on a car loan. After that day, the loan is finished.

**In this source:** The portfolio view will show this date, so customers know when their money comes back.

**Note:** After the maturity date, the bond stops paying yearly money.
