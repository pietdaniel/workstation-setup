---
name: doc-review
description: "Review a Google Doc and post anchored inline comments with feedback. Takes a Google Docs URL, reads the document via `gws` CLI, analyzes the content for clarity, correctness, structure, and style, then uses Playwright browser automation to post real anchored inline comments with yellow highlighting on specific passages. Use when asked to review a doc, give feedback on a document, annotate a Google Doc, or comment on a doc."
---

# Google Doc Review

## Overview

Perform a thorough review of a Google Doc and post anchored inline comments directly on specific passages. This skill combines `gws` CLI for reading document content with Playwright browser automation for posting real inline comments. The Google Drive API cannot create anchored comments, so we automate the Docs UI via keyboard shortcuts.

All comments are posted in a **single browser session** using the batch script at `~/.config/opencode/skills/doc-review/doc-review-batch.mjs`. This opens Chrome once, navigates to each document tab as needed, and posts every comment in sequence, which is far faster than launching a separate browser per comment. For multi-tab documents, comments include a `tabUrl` field so the script navigates to the correct tab before posting.

## Input

The user provides a Google Docs URL:
- `https://docs.google.com/document/d/{DOCUMENT_ID}/edit`
- `https://docs.google.com/document/d/{DOCUMENT_ID}/edit?tab=t.0`
- Or just a document ID

The user may optionally specify:
- What kind of review (technical accuracy, writing quality, structure, etc.)
- Specific areas of focus or concern

## Prerequisites

- **`gws` CLI** installed at `/opt/homebrew/bin/gws` and authenticated
- **Playwright** installed in the skill's own directory. One-time setup:
  ```bash
  cd ~/.config/opencode/skills/doc-review && PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 npm install
  ```
  (The script uses system Chrome via `channel: 'chrome'`, so Playwright's bundled browsers are not needed.)
- **Chrome** installed (Playwright uses it via `channel: 'chrome'`)
- **One-time login**: First Playwright run opens a visible Chrome window for Google sign-in. Session is cached to `/tmp/google-docs-auth.json` and reused headlessly for ~30 days.

## Step 1 — Parse the document reference

Extract the `DOCUMENT_ID` from the input URL.

- Regex: match the ID between `/d/` and the next `/` in the URL
- Pattern: `docs\.google\.com/document/d/([a-zA-Z0-9_-]+)`
- If the user provides just an ID, use it directly

Construct the base edit URL:
```
https://docs.google.com/document/d/{DOCUMENT_ID}/edit
```

## Step 2 — Discover and select document tabs

Google Docs can contain multiple **tabs** (separate content pages within one document). Before reading content, discover the tab structure and let the user choose which tabs to review.

### 2a. Fetch tabs metadata

Use `includeTabsContent: true` to get the tab list:

```bash
gws docs documents get --params '{"documentId": "DOCUMENT_ID", "includeTabsContent": true}' \
  | jq '{title: .title, tabs: [.tabs[]? | {tabId: .tabProperties.tabId, title: .tabProperties.title, index: .tabProperties.index}]}'
```

This returns a `tabs` array with each tab's `tabId`, `title`, and `index`.

### 2b. Single-tab documents

If the document has only one tab (or no `tabs` array), skip tab selection and proceed directly to Step 3. Use the base URL without a `?tab=` parameter.

### 2c. Multi-tab documents: ask the user

If the document has **2 or more tabs**, use the `mcp_question` tool to ask which tabs to review. Present a multi-select question with:

- One option per tab, labeled with the tab title (e.g. "CJ&E Domain Overview", "Experiments Implementation")
- An **"All tabs"** option as the first choice
- `multiple: true` to allow selecting several tabs
- No custom/free-text needed

Example `mcp_question` call:

```
header: "Tabs to review"
question: "This document has {N} tabs. Which tabs would you like me to review?"
multiple: true
options:
  - label: "All tabs"
    description: "Review every tab in the document"
  - label: "{Tab 1 title}"
    description: "Tab 1 of {N}"
  - label: "{Tab 2 title}"
    description: "Tab 2 of {N}"
  ...
```

If the user selects "All tabs", review every tab. Otherwise review only the selected tabs.

### 2d. Construct per-tab URLs

For each selected tab, construct the tab-specific URL:
```
https://docs.google.com/document/d/{DOCUMENT_ID}/edit?tab={TAB_ID}
```

Keep track of the mapping: `tabId` -> `tabTitle` -> `tabUrl` for use in later steps.

## Step 3 — Read the document content

When `includeTabsContent: true` is used, content is nested under each tab rather than at the root `body`. Fetch the full document once and extract content per tab.

### 3a. Fetch full document with tab content

```bash
gws docs documents get --params '{"documentId": "DOCUMENT_ID", "includeTabsContent": true}'
```

### 3b. Extract readable text per tab

For each selected tab, extract the plain text from `tabs[].documentTab.body.content`:

```bash
gws docs documents get --params '{"documentId": "DOCUMENT_ID", "includeTabsContent": true}' \
  | jq -r '.tabs[] | select(.tabProperties.tabId == "TAB_ID") | .documentTab.body.content[].paragraph?.elements[]?.textRun?.content // empty'
```

Or extract all selected tabs at once:

```bash
gws docs documents get --params '{"documentId": "DOCUMENT_ID", "includeTabsContent": true}' \
  | jq -r '.tabs[] | "=== TAB: \(.tabProperties.title) ===", (.documentTab.body.content[].paragraph?.elements[]?.textRun?.content // empty)'
```

### 3c. Extract document structure per tab

The structural metadata is in each tab's body: `tabs[].documentTab.body.content[].paragraph.paragraphStyle.namedStyleType` (e.g. `HEADING_1`, `HEADING_2`, `NORMAL_TEXT`).

### 3d. Get document title and metadata

```bash
gws docs documents get --params '{"documentId": "DOCUMENT_ID", "includeTabsContent": true}' \
  | jq '{title: .title, revisionId: .revisionId}'
```

### 3e. Single-tab fallback

For single-tab documents (or when `includeTabsContent` is not used), the old paths still work:
- Text: `.body.content[].paragraph?.elements[]?.textRun?.content`
- Structure: `.body.content[].paragraph.paragraphStyle.namedStyleType`

## Step 4 — Plan the review using TodoWrite

Create a todo list to track progress. For multi-tab reviews, create per-tab items:

**Single-tab example:**
1. Read and understand the document structure
2. Analyze content by section
3. Generate review feedback items
4. Write comments JSON and post via batch script

**Multi-tab example:**
1. Read and understand all selected tabs
2. Analyze "Tab A" content
3. Analyze "Tab B" content
4. Generate review feedback items (per tab)
5. Write comments JSON and post via batch script

## Step 5 — Analyze the document

For multi-tab reviews, analyze each tab independently. Each tab may have a different purpose and audience, so adjust the review criteria accordingly. Also look for cross-tab issues: inconsistencies, contradictions, or missing cross-references between tabs.

Review the document content across these categories, adjusted based on any user-specified focus:

### Clarity & Readability
- Ambiguous or vague statements that could be misinterpreted
- Overly long or complex sentences that should be broken up
- Jargon or acronyms used without definition
- Passive voice where active voice would be clearer
- Missing context that the reader would need

### Correctness & Accuracy
- Factual claims that appear incorrect or unsupported
- Inconsistencies between different sections
- Outdated information or references
- Contradictions within the document

### Structure & Organization
- Missing sections that the document type typically requires
- Information that appears in the wrong section
- Logical flow issues (jumps between topics, missing transitions)
- Missing or inadequate introduction/conclusion
- Headings that don't accurately reflect section content

### Technical Content (if applicable)
- Incorrect technical details, commands, or code snippets
- Missing error handling or edge case considerations
- Incomplete instructions or missing steps
- Architecture decisions that aren't justified
- Security or reliability concerns not addressed

### Writing Quality
- Grammar and spelling errors
- Inconsistent terminology (same concept referred to by different names)
- Redundant or repetitive content
- Missing examples where they would help
- Tone inconsistencies

### Completeness
- Open questions or TODOs left in the document
- Missing references or links
- Gaps in the argument or proposal
- Missing stakeholder considerations

## Step 6 — Generate feedback items

For each issue found, produce a structured feedback item internally. For multi-tab reviews, also track which tab the feedback belongs to:

```
- Tab: {tab title} (omit for single-tab documents)
- Search term: {exact phrase from the document to anchor the comment to}
- Category: Clarity | Correctness | Structure | Technical | Writing | Completeness
- Comment: {concise feedback text: what's wrong and how to improve it}
```

Severity is used internally to prioritize which comments make the cut, but is **not** included in the comment text posted to the doc. Keep comments natural and conversational.

### Choosing search terms

This is critical. The Playwright script uses `Cmd+F` to find text, so the search term must:
- Be an **exact substring** from the document (copy-paste accuracy)
- Be **unique enough** to locate the right passage (prefer 3-8 words)
- Be **short enough** to type reliably (avoid very long phrases)
- Not span across paragraph boundaries
- Avoid special characters that might interfere with the find dialog

Good: `"the service will automatically retry"` (specific, findable)
Bad: `"the"` (too common, will match everywhere)
Bad: `"In this section we discuss the architecture of the new..."` (too long)

### Prioritizing feedback

- Cap at ~15-20 comments **per tab** to avoid overwhelming the author
- For multi-tab reviews, this means up to ~15-20 comments on each tab, not total
- Internally rank by importance: critical issues first, nits last
- If there are many issues, drop the least important ones
- Group related issues into a single comment where possible

### Comment text style

Comments should be concise, direct, and actionable. Write them as you would in a normal doc review. No severity tags, no numbering, no prefixes. Just the feedback.

**Never use em dashes (—) in comment text.** Use periods, commas, or colons to break up sentences instead.

Example:
```
This claim about 99.99% uptime isn't substantiated. Consider linking to the SLA or historical uptime metrics so readers can verify.
```

Another example:
```
"CQRS" is used here without definition. Not all readers will be familiar with this pattern. Consider spelling it out on first use or adding a brief explanation.
```

Bad example (do not do this):
```
"CQRS" is used here without definition — not all readers will know this pattern — consider spelling it out.
```

## Step 7 — Write the comments JSON file

Write all feedback items to `/tmp/doc-review-comments.json` as a JSON array. For multi-tab documents, include a `tabUrl` field so the batch script navigates to the correct tab before posting each comment.

### Single-tab format (backward compatible)

```json
[
  {
    "searchTerm": "the service will automatically retry",
    "comment": "How many times does it retry? Consider specifying the retry count and backoff strategy so on-call engineers know what to expect."
  }
]
```

### Multi-tab format

```json
[
  {
    "tabUrl": "https://docs.google.com/document/d/{DOCUMENT_ID}/edit?tab=t.abc123",
    "searchTerm": "the service will automatically retry",
    "comment": "How many times does it retry? Consider specifying the retry count and backoff strategy so on-call engineers know what to expect."
  },
  {
    "tabUrl": "https://docs.google.com/document/d/{DOCUMENT_ID}/edit?tab=t.xyz789",
    "searchTerm": "we chose DynamoDB for this",
    "comment": "What alternatives were considered? Adding a brief comparison would help readers understand why DynamoDB was the right choice over, say, PostgreSQL or Redis."
  }
]
```

Use the Write tool to create this file. Each entry must have:
- `searchTerm`: exact text from the document (3-8 words, unique within its tab)
- `comment`: the feedback text to post (no severity tags, no numbering)
- `tabUrl` (optional): the full URL for the tab this comment belongs to. Required for multi-tab reviews. Omit for single-tab documents (the script will use the base DOC_URL).

**Group comments by tab** in the JSON array (all comments for tab A first, then tab B, etc.) so the batch script minimizes tab navigation.

## Step 8 — Ensure Playwright is ready and post comments

### 8a. Verify prerequisites

```bash
# Check Playwright is installed in the skill directory
ls ~/.config/opencode/skills/doc-review/node_modules/playwright

# If not, install it (one-time setup)
cd ~/.config/opencode/skills/doc-review && PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 npm install
```

### 8b. Run the batch script

Post all comments in a single browser session:

```bash
node ~/.config/opencode/skills/doc-review/doc-review-batch.mjs \
  "https://docs.google.com/document/d/{DOCUMENT_ID}/edit" \
  "/tmp/doc-review-comments.json"
```

The first argument is the base document URL (used for initial authentication and as the fallback for comments without a `tabUrl`).

This script:
1. Opens ONE headless Chrome session with cached auth
2. Groups comments by `tabUrl` (or the base DOC_URL if no `tabUrl` is set)
3. Navigates to each tab URL once, then posts all comments for that tab
4. For each comment: `Cmd+F` -> type search term -> `Enter` -> `Escape` -> `Cmd+Alt+M` -> type comment -> `Cmd+Enter`
5. Closes the browser when done

The script prints progress including tab navigation (`Navigating to tab: ...`) and per-comment status (`[3/15] Searching: "..."` -> `Comment posted.`).

### Handling failures

- If the script reports a session expiry, a visible Chrome window will open. Let the user log in. The session is then saved and future runs are headless.
- If a specific comment fails (search term not found), the script logs the failure and continues with the next comment.
- If tab navigation fails, the script logs the error and skips all comments for that tab.
- Note any failed comments in the report to the user.

## Step 9 — Report back to the user

After posting, summarize what was done.

### Single-tab report

```
## Doc Review Complete

**Document:** {title}
**URL:** {doc_url}
**Comments posted:** {posted} of {total}

### Key Findings
1. {Most important finding, 1 sentence}
2. {Second most important finding}
3. ...

### Comments That Could Not Be Posted
- "{search_term}": {the feedback text, so the user still sees it}
```

### Multi-tab report

```
## Doc Review Complete

**Document:** {title}
**Tabs reviewed:** {tab_count}
**Total comments posted:** {posted} of {total}

### {Tab 1 title}
**Comments:** {posted} of {total}
**Key Findings:**
1. {finding}
2. {finding}

### {Tab 2 title}
**Comments:** {posted} of {total}
**Key Findings:**
1. {finding}

### Comments That Could Not Be Posted
- [{tab_title}] "{search_term}": {the feedback text}
```

## How the Playwright Commenting Works

### Why Playwright (not the API)

The Google Drive API **cannot** create anchored inline comments on Google Docs. The `kix.PARAGRAPH_ID` anchors required for inline highlighting are internal to Google's Kix editor engine and deliberately not exposed via any public API. This has been a confirmed limitation since 2012.

The Playwright approach automates the Google Docs UI directly, producing real anchored comments with yellow highlighting.

### Auth flow

1. Check for saved session at `/tmp/google-docs-auth.json`
2. If valid → launch headless Chrome with saved cookies
3. If expired or missing → launch visible Chrome, wait for user to log in, save session via `context.storageState()`, switch to headless

### Commenting flow (per comment, all in one browser session)

1. `Cmd+F` → type search term → `Enter` to find match
2. `Escape` to close find bar (selection stays on matched text)
3. `Cmd+Alt+M` to open comment dialog
4. Type comment text (dialog auto-focuses the input)
5. `Cmd+Enter` to submit

Google Docs uses canvas rendering, so DOM selectors don't work. Everything is keyboard shortcuts.

### Limitations

- **Not headless on first run**: Google OAuth requires a visible browser for initial sign-in
- **Session expiry**: ~30 days, then one more visible login is needed
- **Canvas timing**: sleeps are used between actions because canvas rendering has no DOM events to await
- **Duplicate comments**: the script doesn't check if a comment already exists; running the review twice will double-comment
- **Search term accuracy**: if the search term doesn't exactly match document text, the comment will land on the wrong place or fail

## Important Rules

### Do
- ALWAYS read the full document content before generating feedback
- ALWAYS use exact text from the document as search terms
- ALWAYS verify Playwright is installed before attempting to post
- ALWAYS cap comments at ~15-20 per tab to avoid overwhelming the author
- ALWAYS use the batch script (single browser session), never launch a browser per comment
- ALWAYS use `includeTabsContent: true` when fetching documents to discover tabs
- ALWAYS ask the user which tabs to review when a document has multiple tabs (use `mcp_question` with multi-select)
- ALWAYS include `tabUrl` in comments JSON for multi-tab reviews
- ALWAYS group comments by tab in the JSON file to minimize tab navigation
- Keep comments concise and conversational, 1-3 sentences
- Focus on substantive issues over minor style nits
- Be constructive: explain what's wrong AND how to improve it
- Respect the document's intended audience and purpose

### Do Not
- Do NOT post more than ~20 inline comments per tab. Focus on the most impactful feedback
- Do NOT include severity tags like `[High]` or `[Medium]` in comment text
- Do NOT include numbering like `(1)` or `#3` in comment text
- Do NOT comment on formatting/font choices unless they impair readability
- Do NOT use search terms shorter than 3 words (too many false matches)
- Do NOT use search terms that span paragraph boundaries
- Do NOT modify the document content. This is a read-only review that posts comments
- Do NOT re-run on the same doc without warning about duplicate comments
- Do NOT guess at document content. Always read it via `gws` first
- Do NOT call `docs-comment.mjs` once per comment. Use the batch script
- Do NOT use em dashes in comment text. Use commas, periods, or colons instead
- Do NOT skip tab discovery. Even single-tab documents should be fetched with `includeTabsContent: true`
- Do NOT mix up search terms between tabs. Each search term must come from the specific tab it targets
- Do NOT comment on typos or other nits, only comment material
