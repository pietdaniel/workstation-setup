---
name: gws-capabilities
description: "Use the `gws` CLI to interact with Google Workspace APIs. Read/write Google Docs, Sheets, Drive files, Chat messages, Gmail, Calendar events, and Tasks. Use when the user asks to read a Google Doc, query a spreadsheet, list Chat messages, search Drive, send emails, or perform any Google Workspace operation."
---

# Google Workspace CLI (`gws`)

## Overview

The `gws` CLI is a local Google Workspace client installed at `/opt/homebrew/bin/gws`. It provides direct access to Google Workspace APIs (Drive, Sheets, Docs, Chat, Gmail, Calendar, Tasks, and more) from the command line. Use it to read documents, query spreadsheets, list chat messages, search files, and automate Google Workspace workflows.

## Authentication

The CLI is authenticated via OAuth2 as `daniel.piet@rokt.com` with encrypted credentials stored in `~/.config/gws/`. The token auto-refreshes. Check status with:

```bash
gws auth status
```

If auth is expired, re-authenticate with:

```bash
gws auth login
```

## Authenticated Scopes

The CLI has **full read/write access** to the following services (52 scopes):

| Service | Access Level |
|---------|-------------|
| Google Drive | Full read/write (`drive`) |
| Google Sheets | Full read/write (`spreadsheets`) |
| Google Docs | Full read/write (`documents`) |
| Gmail | Full read/write/send (`gmail.modify`, `gmail.send`, `gmail.compose`) |
| Google Calendar | Full read/write (`calendar`) |
| Google Chat | Full read/write messages, spaces, memberships (`chat.messages`, `chat.spaces`) |
| Google Tasks | Full read/write (`tasks`) |
| Google Slides | Full read/write (`presentations`) |
| Google Forms | Full read/write (`forms`) |
| Google Meet | Read/write spaces (`meetings.space.*`) |
| People/Contacts | Full read/write (`contacts`, `directory.readonly`) |
| Cloud Platform | Full access (`cloud-platform`) |

## Command Syntax

```
gws <service> <resource> [sub-resource] <method> [flags]
```

### Global Flags

| Flag | Description |
|------|-------------|
| `--params <JSON>` | URL/query parameters as JSON |
| `--json <JSON>` | Request body as JSON (POST/PATCH/PUT) |
| `--format <FMT>` | Output format: `json` (default), `table`, `yaml`, `csv` |
| `--page-all` | Auto-paginate, one JSON line per page (NDJSON) |
| `--page-limit <N>` | Max pages to fetch (default: 10) |
| `--dry-run` | Validate without sending to API |
| `--upload <PATH>` | Local file to upload as media content |
| `--output <PATH>` | Output file path for binary responses |

### Helper Commands

Many services have `+helper` shortcuts prefixed with `+`. These simplify common operations:

| Helper | Description |
|--------|-------------|
| `gws sheets +read` | Read values from a spreadsheet |
| `gws sheets +append` | Append rows to a spreadsheet |
| `gws docs +write` | Append text to a document |
| `gws drive +upload` | Upload a file to Drive |
| `gws chat +send` | Send a message to a Chat space |
| `gws gmail +send` | Send an email |
| `gws gmail +triage` | Show unread inbox summary |
| `gws gmail +read` | Read a specific email message |
| `gws gmail +reply` | Reply to a message |
| `gws gmail +reply-all` | Reply-all to a message |
| `gws gmail +forward` | Forward a message |
| `gws gmail +watch` | Watch for new emails (NDJSON stream) |
| `gws calendar +agenda` | Show upcoming events |
| `gws calendar +insert` | Create a new calendar event |
| `gws workflow +standup-report` | Today's meetings + open tasks |
| `gws workflow +meeting-prep` | Prep for next meeting |
| `gws workflow +email-to-task` | Convert email to a task |
| `gws workflow +weekly-digest` | Weekly summary |
| `gws workflow +file-announce` | Announce a Drive file in Chat |

### API Schema Introspection

Use `gws schema` to discover the exact parameters any API method accepts:

```bash
gws schema drive.files.list
gws schema sheets.spreadsheets.values.get
gws schema chat.spaces.messages.list
```

This outputs the full JSON schema with parameter names, types, descriptions, and whether they're required.

---

## Services & Resources

### Google Drive (`drive`)

Resources: `files`, `permissions`, `comments`, `replies`, `revisions`, `drives`, `changes`, `about`, `apps`, `channels`

### Google Sheets (`sheets`)

Resources: `spreadsheets` (sub-resources: `values`, `sheets`, `developerMetadata`)

### Google Docs (`docs`)

Resources: `documents`

### Google Chat (`chat`)

Resources: `spaces` (sub-resources: `messages`, `members`, `spaceEvents`), `customEmojis`, `media`, `users`

### Gmail (`gmail`)

Resources: `users` (sub-resources: `messages`, `threads`, `labels`, `drafts`, `history`, `settings`)

### Google Calendar (`calendar`)

Resources: `events`, `calendars`, `calendarList`, `acl`, `freebusy`, `settings`, `colors`

### Google Tasks (`tasks`)

Resources: `tasklists`, `tasks`

### Google Slides (`slides`)

Resources: `presentations` (sub-resources: `pages`)

### Google Forms (`forms`)

Resources: `forms` (sub-resources: `responses`, `watches`)

---

## Common Workflows

### 1. Read a Google Doc

```bash
# Get full document content (structured JSON with body elements)
gws docs documents get --params '{"documentId": "DOCUMENT_ID"}'

# Append text to a document
gws docs +write --document DOCUMENT_ID --text 'New content here'
```

**Extracting the document ID:** From a Google Docs URL like `https://docs.google.com/document/d/DOCUMENT_ID/edit`, the ID is the string between `/d/` and `/edit`.

**Tip:** The `documents get` response contains deeply nested structural content. The body text is in `body.content[].paragraph.elements[].textRun.content`. For quick reading, pipe through jq:

```bash
gws docs documents get --params '{"documentId": "DOC_ID"}' \
  | jq -r '.body.content[].paragraph?.elements[]?.textRun?.content // empty'
```

### 2. Read a Google Sheet

```bash
# Read a range using the helper (simplest)
gws sheets +read --spreadsheet SPREADSHEET_ID --range "Sheet1!A1:D10"

# Read an entire sheet
gws sheets +read --spreadsheet SPREADSHEET_ID --range "Sheet1"

# Read with table output for human-readable display
gws sheets +read --spreadsheet SPREADSHEET_ID --range "Sheet1!A1:D10" --format table

# Get spreadsheet metadata (sheet names, properties)
gws sheets spreadsheets get --params '{"spreadsheetId": "SPREADSHEET_ID"}'

# Read using the raw values API (more control)
gws sheets spreadsheets values get --params '{"spreadsheetId": "SPREADSHEET_ID", "range": "Sheet1!A1:Z100"}'

# Read multiple ranges at once
gws sheets spreadsheets values batchGet --params '{"spreadsheetId": "SPREADSHEET_ID", "ranges": ["Sheet1!A:A", "Sheet1!C:C"]}'
```

**Extracting the spreadsheet ID:** From a URL like `https://docs.google.com/spreadsheets/d/SPREADSHEET_ID/edit#gid=0`, the ID is between `/d/` and `/edit`.

**Writing to a sheet:**

```bash
# Append a single row
gws sheets +append --spreadsheet SPREADSHEET_ID --values 'Alice,100,true'

# Append multiple rows
gws sheets +append --spreadsheet SPREADSHEET_ID --json-values '[["Alice",100],["Bob",200]]'

# Update a specific range
gws sheets spreadsheets values update \
  --params '{"spreadsheetId": "SPREADSHEET_ID", "range": "Sheet1!A1:B2", "valueInputOption": "USER_ENTERED"}' \
  --json '{"values": [["Name","Score"],["Alice",100]]}'
```

### 3. Read Google Chat Messages

```bash
# List all Chat spaces you're a member of
gws chat spaces list

# List spaces with a filter (named spaces only)
gws chat spaces list --params '{"filter": "spaceType = \"SPACE\""}'

# List messages in a space (most recent first)
gws chat spaces messages list --params '{"parent": "spaces/SPACE_ID"}'

# List messages with pagination (get more messages)
gws chat spaces messages list --params '{"parent": "spaces/SPACE_ID", "pageSize": 100}' --page-all

# Get a specific message
gws chat spaces messages get --params '{"name": "spaces/SPACE_ID/messages/MESSAGE_ID"}'

# Send a message to a space
gws chat +send --space "spaces/SPACE_ID" --text "Hello team!"

# Search for a specific space by display name
gws chat spaces list --format json | jq '.spaces[] | select(.displayName | test("team-name"; "i"))'
```

**Finding the space ID:** Run `gws chat spaces list --format table` to see all spaces with their names. The space name is in the format `spaces/AAAA...`.

### 4. Search Google Drive Files

```bash
# List recent files
gws drive files list --params '{"pageSize": 10}'

# Search by name
gws drive files list --params '{"q": "name contains '\''quarterly report'\''", "pageSize": 10}'

# Search by MIME type (Google Docs only)
gws drive files list --params '{"q": "mimeType = '\''application/vnd.google-apps.document'\''", "pageSize": 10}'

# Search Google Sheets
gws drive files list --params '{"q": "mimeType = '\''application/vnd.google-apps.spreadsheet'\''", "pageSize": 10}'

# Search in a specific folder
gws drive files list --params '{"q": "'\''FOLDER_ID'\'' in parents", "pageSize": 20}'

# Full-text search across file contents
gws drive files list --params '{"q": "fullText contains '\''budget 2024'\''", "pageSize": 10}'

# Get file metadata
gws drive files get --params '{"fileId": "FILE_ID"}'

# Get file metadata with specific fields
gws drive files get --params '{"fileId": "FILE_ID", "fields": "id,name,mimeType,webViewLink,modifiedTime"}'

# Download a file
gws drive files get --params '{"fileId": "FILE_ID", "alt": "media"}' --output ./downloaded-file.pdf

# Export a Google Doc as PDF
gws drive files export --params '{"fileId": "FILE_ID", "mimeType": "application/pdf"}' --output ./doc.pdf

# Upload a file
gws drive +upload ./report.pdf
gws drive +upload ./report.pdf --parent FOLDER_ID
```

**Common MIME types for `q` filter:**
- Google Docs: `application/vnd.google-apps.document`
- Google Sheets: `application/vnd.google-apps.spreadsheet`
- Google Slides: `application/vnd.google-apps.presentation`
- Google Forms: `application/vnd.google-apps.form`
- Folders: `application/vnd.google-apps.folder`
- PDFs: `application/pdf`

### 5. Gmail Operations

```bash
# Triage inbox (see unread messages)
gws gmail +triage
gws gmail +triage --max 10 --format table

# Search for specific emails
gws gmail +triage --query 'from:alice@rokt.com subject:deploy'

# Read a specific message (get ID from triage)
gws gmail +read --id MESSAGE_ID
gws gmail +read --id MESSAGE_ID --headers

# List messages with raw API
gws gmail users messages list --params '{"userId": "me", "q": "is:unread from:notifications@github.com", "maxResults": 10}'

# Send an email
gws gmail +send --to alice@rokt.com --subject "Update" --body "Here's the update..."

# Reply to a message
gws gmail +reply --id MESSAGE_ID --body "Thanks for the update!"

# Forward a message
gws gmail +forward --id MESSAGE_ID --to bob@rokt.com
```

### 6. Calendar Operations

```bash
# See today's agenda
gws calendar +agenda

# See upcoming events with table format
gws calendar +agenda --format table

# List events in a date range
gws calendar events list --params '{"calendarId": "primary", "timeMin": "2026-03-23T00:00:00Z", "timeMax": "2026-03-24T00:00:00Z", "singleEvents": true, "orderBy": "startTime"}'

# Create an event
gws calendar +insert --summary "Team Sync" --start "2026-03-24T10:00:00" --end "2026-03-24T10:30:00"

# Prep for next meeting
gws workflow +meeting-prep
```

### 7. Tasks Operations

```bash
# List task lists
gws tasks tasklists list

# List tasks in a task list
gws tasks tasks list --params '{"tasklist": "TASKLIST_ID"}'

# Create a task
gws tasks tasks insert --params '{"tasklist": "TASKLIST_ID"}' --json '{"title": "Review PR", "notes": "Check the new feature branch"}'
```

### 8. Cross-Service Workflows

```bash
# Morning standup: calendar + tasks summary
gws workflow +standup-report

# Prep for next meeting: attendees, agenda, linked docs
gws workflow +meeting-prep

# Convert an email to a task
gws workflow +email-to-task --message-id MESSAGE_ID

# Weekly digest: this week's meetings + unread count
gws workflow +weekly-digest

# Announce a Drive file in a Chat space
gws workflow +file-announce --file-id FILE_ID --space "spaces/SPACE_ID"
```

---

## Pagination

For endpoints that return paginated results:

```bash
# Auto-paginate (NDJSON, one JSON object per page)
gws drive files list --params '{"pageSize": 100}' --page-all

# Limit to N pages
gws drive files list --params '{"pageSize": 100}' --page-all --page-limit 5

# Add delay between pages (ms) to avoid rate limits
gws drive files list --params '{"pageSize": 100}' --page-all --page-delay 200
```

## Output Formats

```bash
# JSON (default)
gws sheets +read --spreadsheet ID --range "Sheet1" --format json

# Table (human-readable)
gws sheets +read --spreadsheet ID --range "Sheet1" --format table

# CSV
gws sheets +read --spreadsheet ID --range "Sheet1" --format csv

# YAML
gws sheets +read --spreadsheet ID --range "Sheet1" --format yaml
```

## Extracting IDs from Google URLs

| URL Pattern | ID Location |
|-------------|-------------|
| `https://docs.google.com/document/d/{ID}/edit` | Between `/d/` and `/edit` |
| `https://docs.google.com/spreadsheets/d/{ID}/edit` | Between `/d/` and `/edit` |
| `https://docs.google.com/presentation/d/{ID}/edit` | Between `/d/` and `/edit` |
| `https://docs.google.com/forms/d/{ID}/edit` | Between `/d/` and `/edit` |
| `https://drive.google.com/file/d/{ID}/view` | Between `/d/` and `/view` |
| `https://drive.google.com/drive/folders/{ID}` | After `/folders/` |
| `https://mail.google.com/mail/u/0/#inbox/{ID}` | After `#inbox/` |
| Chat space URL | Run `gws chat spaces list` to find `spaces/AAAA...` names |

## Tips

- Use `--dry-run` to preview API calls without executing them.
- Use `gws schema <service.resource.method>` to discover exact parameters for any API method.
- Use `--format table` for human-readable output; `--format json` for piping to `jq`.
- For large result sets, use `--page-all` with `--page-limit` to control pagination.
- Quote JSON carefully in bash: use single quotes around the `--params` value and escape inner quotes as needed.
- The `+helper` commands handle common patterns (auth, pagination, formatting) automatically — prefer them over raw API calls when available.
- All `+read`/`+triage`/`+agenda` helpers are **read-only** and never modify data.

## Error Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | API error (Google returned an error) |
| 2 | Auth error (credentials missing/invalid — run `gws auth login`) |
| 3 | Validation error (bad arguments) |
| 4 | Discovery error (could not fetch API schema) |
| 5 | Internal error |
