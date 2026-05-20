---
name: dpkb
description: "Ingest the current OpenCode session into the dpkb wiki (Dan Piet's Knowledge Base) as a world model an agent can plan over. Reviews the session and extracts durable content across nine dimensions: ontology (glossary), entities (services/), concepts/ontology (concepts/), runbooks (runbooks/), gotchas, citable sources, the world-model layer (world-model/ — actors and indexes of capabilities + pathways), cheatsheet-worthy commands that worked (cheatsheets/), and datalake queries that ran successfully (datalake/queries/). Capabilities are inlined on entity pages; invariants live on the entity they constrain (or as a concept when they describe a pattern). Stamps every touched page with `Last updated: YYYY-MM-DD` and runs a lint pass for staleness, missing dates, broken links, glossary gaps, topology drift, capability/world-model drift, runbook integrity, concept ↔ entity bidirectionality, unlabeled topology edges, and cheatsheet/datalake-query drift. Updates the wiki at github.com/ROKT/dpkb in a fresh worktree on a new branch, opens a PR via the yeet flow, and merges. Encodes the LLM-Wiki pattern from llm-wiki.md (Karpathy). Run when the user invokes /dpkb or asks to file the session into the wiki."
---

# dpkb — file the session into the wiki

## Purpose

The user's persistent knowledge base is the GitHub repo `ROKT/dpkb`. This skill takes whatever is durable and useful from the current OpenCode session — concepts, facts, decisions, runbook-shaped procedures, gotchas, links to authoritative sources — and integrates it into that wiki, in the spirit of the LLM-Wiki pattern described in `llm-wiki.md` at the repo root.

The session is the **raw source**. The wiki is the **persistent, compounding artifact**. The skill's job is to compile the former into the latter.

### The wiki is a world model, not a notebook

The first-order purpose of the wiki is to be a **world model an agent can plan over.** Future agents (and humans acting like agents) will read this wiki to answer questions like *"What exists in this environment? What can I do? What state is the system in? How do I get from state X to state Y?"* That framing changes what counts as durable content:

- **What exists** — entities and their current state. Not just "Soteria is a service" but "Soteria is *running in production*, owned by *team X*, version *Y as of YYYY-MM-DD*." Filed under `services/`.
- **What's possible** — *capabilities and affordances* each entity exposes. "Buildkite can re-trigger any job by ID." "GitHub Pages can serve from `master` or from Actions output." Capabilities are the verbs an actor can invoke through an entity. **Inlined on the entity page**; indexed in `world-model/capability-index.md`.
- **What interactions exist** — typed edges between entities and actors. "Service A *publishes* to Topic B." "Engineer *enables* Pages by editing Settings → Pages." Filed on the entity pages and shown in `topology.md`.
- **What pathways exist between states** — pre-condition → action → post-condition chains. Filed as runbooks under `runbooks/`; indexed in `world-model/pathways.md`.
- **What actors exist** — who/what can perform interactions. Humans, agents, CI, schedulers, scripts. Filed in `world-model/actors.md`.
- **What concepts the environment runs on** — mental models, design patterns, and business primitives that span multiple entities ("ROAS bidding", "real-time services", "medallion datalake architecture", "shadow forwarding", "hub-spoke replication"). Concepts are the **ontology layer** — they make the wiki teachable to a newcomer. Filed under `concepts/`.

### Knowledge, not questions

The wiki captures *established* facts, patterns, capabilities, and procedures. It is not a backlog.

- **Don't file open questions.** If you don't know the answer, leave the gap; another session will surface and fill it. "We should investigate X" belongs in chat or in a log entry, not on a wiki page.
- **Don't file todos.** Same reason.
- **Don't file speculations.** Only what was observed, established, or directly verified during the session.

When you're tempted to write "is this true?" or "what about Y?", stop and either find the answer (then write it as a fact) or skip it.

### Invariants live on the entity they constrain

There is **no global cross-cutting invariants page**. Invariants are properties of entities or properties of concepts.

- If an invariant constrains one entity, it lives in that entity's `## Invariants` section.
- If an invariant constrains 2+ entities ("the same rule applies on both side X and side Y"), repeat it on each affected entity, with cross-references. A reader landing on either entity sees the constraint.
- If an invariant is actually a *pattern* that recurs across many systems (e.g. "Go heap mapped CSVs amplify RSS 3–5×", "ambient mesh egress drops silently under `REGISTRY_ONLY`"), that's a **concept**, not an invariant — file it under `concepts/` with the entities-where-it-shows-up listed.

## Prerequisites

- `gh` CLI installed and authenticated (`gh auth status`). If not, stop and ask the user to authenticate.
- `git` >= 2.5 (worktrees).
- The dpkb repo already cloned locally at `/Users/rokt/go/src/github.com/ROKT/dpkb`. If it isn't, fall back to cloning into a fresh `/tmp/dpkb-skill-clone` and operate from there.
- Network access to github.com.

## High-level workflow

1. **Audit the session** — review every user message, assistant message, tool call, and tool result in the conversation so far. Identify content worth preserving across nine dimensions: ontology/definitions, entities (with state), concepts/patterns, runbooks (multi-step procedures), gotchas, citable sources, the world-model layer (actors, capability index, pathway index), cheatsheet-worthy commands that worked, and datalake queries that ran successfully.
2. **Set up a worktree** — `git worktree add /tmp/dpkb-{slug} -b dp/{slug}` from the existing dpkb checkout, branching off the latest `master`.
3. **Plan the edits** — decide which existing pages to update, which new pages to create, which glossary entries to add, which service/topology updates are needed, which concept pages to author or extend, and which capability/pathway-index entries the session reveals. Follow the existing taxonomy where it fits; extend it when it doesn't. You are trusted to do the right thing.
4. **Write the edits** — edit/create pages in the worktree only. Maintain `glossary.md` (alphabetical), `services/` (with state, capabilities inlined, invariants on the entity), `concepts/` (cross-cutting patterns), `tooling/` (one folder per tool we use but don't run), `topology.md` (with verb-labeled edges), `world-model/` (actors + capability index + pathway index), `runbooks/` (state-to-state recipes), `index.md`, and append to `log.md`. Stamp every touched page with `_Last updated: YYYY-MM-DD_`. Update `README.md` TOC only if a new top-level folder was added.
5. **Lint pass** — sweep the wiki for staleness, missing date stamps, broken links, glossary gaps, entity/topology drift, capability/world-model drift, runbook integrity, concept ↔ entity bidirectionality, unlabeled topology edges, orphans, contradictions, and forbidden content (open-questions sections, cross-cutting invariants pages). Capture findings in the PR body.
6. **Yeet** — invoke the `yeet` skill from inside the worktree to commit, push, and open a PR.
7. **Merge** — once the PR is open, merge it via `gh pr merge --squash --delete-branch`. CI is intentionally not configured for this repo, so merging immediately is safe.
8. **Clean up** — remove the worktree and prune.
9. **Report back** — give the user the PR URL, what landed, world-model deltas, concept deltas, topology edge changes, and any lint findings that need follow-up.

## Step 1: Audit the session

Before touching the wiki, do an explicit inventory pass across the dimensions below. The point of this pass is to surface durable content the wiki should hold, not to summarize what happened in chat.

### 1a. Glossary — domain ontology and definitions

The Rokt-specific *vocabulary* is one of the highest-value things this wiki can hold. It's the thing that's hardest to recover later and the thing newcomers spend the most time piecing together.

For every Rokt-specific or DP-specific term, system, acronym, or jargon word that appears in the session, ask:

- Is there already a definition in `glossary.md`?
- If not: add one.
- If yes but stale, ambiguous, or wrong: revise it.

Examples of things that belong in the glossary (illustrative, not exhaustive): "Soteria", "OP2", "wsdk", "Ratify", "CICD subnet", "SDP", "breakglass", "monitor_gate", "roktinternal", "Cortex" (the internal one — disambiguate from the upstream tool).

If a term has enough surface area to deserve its own page, link the glossary entry to that page (`See [Soteria](services/soteria.md)`). If the term names a *pattern* rather than a *thing*, link to a concept page (`See [Concept: ROAS bidding](concepts/roas-bidding.md)`).

### 1b. Entities — what exists, with state

Anything that looks like a system component — a service, a queue, a dataset, a pipeline, a third-party SaaS Rokt runs — is an **entity** in the world model. Each gets a page under `services/` (one page per entity, despite the historical "services" name) and a node in `topology.md` (the bird's-eye view).

Per entity, capture (only what was actually established in the session — don't fabricate):

- **Purpose.** One-line definition of what it does.
- **State.** Current lifecycle status: `running` | `staged` | `experimental` | `deprecated` | `decommissioned` | `planned` | `unknown`. Date-stamp the state.
- **Owner.** Team / GChat space / Cortex entity if known.
- **Repo / dashboards.** Links to the source repo, Datadog dashboards, Cortex page, runbooks.
- **Capabilities (affordances).** What this entity *enables an actor to do*. Inlined on the entity page. See Step 1g.
- **Upstream dependencies.** What it calls / consumes / reads from.
- **Downstream consumers.** What calls it / consumes its data.
- **Trust / data boundaries.** Where authn/authz changes, where regulated data crosses (PII, PCI, secrets), where regions or VPCs change.
- **Invariants and constraints.** Things that must always be true about this entity. Filed under `## Invariants` on the entity page. **If the invariant also constrains another entity, repeat it on that entity** — do not create a global invariants file. If the invariant is really a recurring *pattern*, file it as a concept instead.
- **Concepts it exemplifies.** If the entity is a load-bearing example of a concept (e.g. transactions-gateway is a load-bearing example of "real-time services at Rokt"), link the concept under Related. The concept page back-links to the entity.
- **Known gotchas.** Operational footguns specific to this entity.

`topology.md` is the index of entities with a high-level diagram. Mermaid is used; **edges must be labeled with verbs** — `publishes`, `consumes`, `writes`, `triggers`, `authenticates against`. Verbs make the topology a world model rather than a static graph.

When the session establishes a *new interaction* between two existing entities (e.g. "service A now writes to topic B"), update both entity pages, the topology diagram, **and** the relevant runbook in `runbooks/` if one exists.

### 1c. Concepts — patterns and mental models

A **concept** is a cross-cutting mental model, design pattern, or business primitive that's *not* a single entity and *not* a single procedure. It's an *ontology layer* over the entities. Concepts make the wiki teachable to a newcomer; they answer "*how do I think about this part of Rokt?*"

Examples of things that belong in `concepts/`:

- Business / domain primitives: "ROAS bidding", "Attribution model", "Customer journey orchestration", "Real-time services at Rokt".
- Architectural patterns: "Medallion datalake architecture", "Shadow forwarding / dual-publish", "Hub-spoke replication", "Wave-based deploys", "Canary analysis with Argo Rollouts".
- Infrastructure patterns: "Ambient mesh egress under REGISTRY_ONLY", "IRSA pod identity", "Reference-data refresh on a CronJob → S3 → consumer-side hot-reload cadence".
- Operational patterns: "Buildkite plan-on-PR / apply-on-master for IaC", "Cortex catalog as ownership source of truth".

For each concept the session illuminates, ask:

- Is there already a concept page? If yes, extend it with the new entity that exemplifies the concept or the new wrinkle the session revealed.
- If no: file `concepts/{slug}.md` (or `concepts/{topic}/index.md` if the concept needs sub-pages). Don't stub — only create a concept page when the session establishes enough to write a real definition, a "where it shows up at Rokt" section with at least 1 entity link, and at least one disambiguation.

**Concepts cite entities; entities can cite back to concepts.** This is the bidirectional ontology — the lint pass enforces it.

If you can't decide whether something is a concept or an entity: if you'd say "Rokt runs it", it's an entity. If you'd say "Rokt does it this way", it's a concept.

### 1d. Runbooks — multi-step procedures with state transitions

A **runbook** is a sequence of capability invocations that transforms the world from a defined initial state to a defined goal state. The previous name for this directory was `pathways/`; it's now `runbooks/` to match how engineers actually refer to these.

File a new runbook when **all three** are true:

- The procedure has a defined starting state (a precondition the reader can verify).
- The procedure has a defined ending state (a postcondition the reader can verify).
- The sequence is 2+ capability invocations, not a single action.

If the procedure has no starting-state precondition (it's "how to do X" with no entry condition), it's a **how-to**, not a runbook. How-tos live next to the entity they're about, under `services/<entity>/how-to/` or `tooling/<tool>/how-to/`.

If the procedure is a single capability invocation, it doesn't need a runbook — the capability description on the entity page suffices.

Runbooks are filed under `runbooks/<surface>/<verb>.md`. The surface is the folder (`kafka/`, `k8s/`, `release/`, `data-replication/`, `carbon/`, …); the verb is the start of the filename (`diagnose-`, `forecast-`, `bump-`, `enable-`, `live-patch-`, `canonicalize-`, `debug-`). Surface is the concern; verb is what the runbook does.

Index the runbook in `world-model/pathways.md` (note: the page is named `pathways.md` for continuity with the world-model vocabulary, but it indexes files that live under `runbooks/`).

### 1e. Gotchas and contradictions

Footguns, surprising defaults, things-that-look-like-they-should-work-but-don't. These deserve prominent placement on the relevant page (often as a `> ⚠ Note:` callout near the top), not buried at the end. Examples: "Private repo Pages defaults to public visibility", "Actions disabled at repo level silently blocks legacy Pages builds", "Cayman theme is shaped for single-page sites, not multi-page wikis".

If the session contradicts something already in the wiki, do not silently overwrite — flag it inline (`> Note: superseded {YYYY-MM-DD} — was previously documented as X, see [log](../log.md)`).

### 1f. Sources to cite

Links to GitHub docs, gists, internal Cortex/Confluence/Notion pages, Datadog dashboards, design docs, slack threads (if linkable), etc. Cite them inline on the relevant page using normal markdown link syntax. Don't accumulate a separate "sources" page unless the session genuinely produced a curated reading list.

### 1g. Actors, capability index, pathway index

The world model has three pieces the skill maintains as durable artifacts in `world-model/`:

- **Actors** (`world-model/actors.md`) — who/what can invoke capabilities. Distinguish between actors with different affordances. An action that requires breakglass admin is not the same as one any engineer can perform.
  - **Human (engineer)** — normal org credentials.
  - **Human (admin / breakglass / role-specific)** — elevated; named per role.
  - **Agent** — LLM agent acting on a user's behalf.
  - **CI / scheduler** — Buildkite, GitHub Actions, k8s CronJobs.
  - **Service account / system** — non-human credentials for service-to-service calls; named per service.
  When the session introduces a new actor or a new affordance distinction, add or revise the entry on `world-model/actors.md`.

- **Capability index** (`world-model/capability-index.md`) — a flat, sorted list of verbs across all entities, each linked to the `#capabilities` anchor on the defining entity page. **The capability itself is inlined on the entity page** (verb, actor, precondition, postcondition, invocation method) — the index just routes the reader to it. When a session adds a new capability on an entity page, append a line to `world-model/capability-index.md` referencing it.

- **Pathway index** (`world-model/pathways.md`) — a flat list of every runbook file under `runbooks/`, each with a one-line "initial state → goal state" summary. When a session creates a new runbook, append a line here.

The aggregate goal: after this skill runs, an agent reading the wiki should be able to answer not just *"what is X?"* but *"how do I make X happen?"* and *"what state is the world in such that X is possible?"* If you can't answer those questions from the pages you've written, the world model is incomplete.

### 1h. Cheatsheet-worthy commands that worked

For every command the session ran that **produced the intended outcome** (i.e. didn't error, didn't return junk, didn't get filtered through three retries before working), ask:

- Is the command non-trivial? Skip pure listings (`ls`, `git status`), one-off `echo`s, and anything copy-pasteable from a man page.
- Is it likely to be useful again, on a future task? Pure-investigation commands (`grep`, ad-hoc `kubectl get pod`) typically aren't — but a working invocation of `kubectl patch deployment ... --type=json -p '...'` against an Argo Rollout, or a `gh api repos/.../pages/builds`, or a `aws ecr describe-repositories --profile ... --registry-id ...` cross-account pattern absolutely is.
- Does the command capture a *Rokt-specific* or *DP-specific* quirk? Profile names (`rokt-prod`, `rgi-prod-bg`, `txn-prod-bg`), endpoint shapes (`master.<rg>.<sg>.<region-suffix>.cache.amazonaws.com`), ECR registry IDs (`035088524874`, `862031682474`), required flags learned the hard way — these are exactly what cheatsheets are for.
- Was it a CLI flag or option combination that took non-obvious investigation to land on? `kubectl patch ... --type=json` (because Argo Rollouts rejects strategic-merge), `redis-cli --tls --no-auth-warning -a $SECRET`, `gh api -X POST -F build_type=legacy`, `aws eks describe-cluster --profile cross-account-profile --registry-id 035088524874` — yes, these all qualify.

If yes to ≥2 of those, the command belongs in a cheatsheet. Identify which cheatsheet — see Step 4 `### cheatsheets/` — or add a new one if the command is for a tool we don't have a cheatsheet for yet.

**Skip pure read commands you used for investigation in this session unless the command itself was hard to find.** The bar isn't "I ran this in the session"; it's "I want this at my fingertips next time."

**Skip commands that already appear verbatim in an existing cheatsheet.** If the session's command is a strict subset of an existing entry, no edit is needed. If it's a generalization or a corrected version, update the existing entry rather than appending a near-duplicate.

### 1i. Datalake queries that ran successfully

For every SQL query the session **ran and got useful results from** against the datalake (Trino, Spark Connect, or Superset), ask:

- Did it answer a real business or debugging question? (One you could state in a sentence — see [datalake/how-to/write-a-new-query.md](https://github.com/ROKT/dpkb/blob/master/datalake/how-to/write-a-new-query.md) at the wiki for the question-first principle.)
- Is the query non-trivial? A bare `SELECT * FROM <table> LIMIT 10` for schema discovery is not query-catalog material. A query with at least one of {CTE, join, partition predicate, `approx_distinct`, time-bounded aggregation, `FILTER` over `UNNEST`, `row_number()` dedup} is.
- Does the result format generalize? If you'd reach for this query again next time someone asks a related question, file it. If it was a one-off "is this thing happening at all" inspection, skip.
- Were the tables it touched documented? If yes, the query reinforces the table page's "queries that use this table" cross-references. If a table page is missing, that's a gap — either add a minimal stub or skip the query until a future session can write the page.

Use [`datalake/how-to/write-a-new-query.md`](https://github.com/ROKT/dpkb/blob/master/datalake/how-to/write-a-new-query.md) as the source of truth for the query-page template. Land each query under `datalake/queries/<domain>/<short-slug>.md` and follow the template exactly — *Intent*, *Technique*, *Tables*, *Query*, *Sample output / typical row count* sections. The `<domain>` matches an existing folder (`sessions-attributes`, `revenue-cost`, `conversions`, `identity`, `audiences-experiments`, `cost-management`, `discovery-meta`, `external-match`, `account-lookup`) or you create a new one only if the question doesn't fit any existing folder.

**Skip queries that are duplicates of existing pages**, unless the new query is a clear improvement (uses better techniques, runs faster, handles edge cases the old one missed). When it's an improvement, update the existing page and note the revision in the file's prose; don't accumulate near-duplicates.

**Skip queries you ran but that errored or returned wrong results.** Wrong-result queries are anti-patterns; they belong nowhere. (The exception is a known-pitfall query that the wiki documents *as* an anti-pattern, e.g. in `datalake/techniques.md` — those are intentional cautionary examples.)

### Filter

The bar is: *would a future me, six months from now, be glad this was filed?* Skip:

- Anything purely transient ("ran ls").
- Anything already documented elsewhere in the wiki, unless this session contradicts or extends it.
- Anything so generic it's not Rokt-specific or DP-specific (e.g. "what is Kubernetes").

If after this pass you find nothing worth preserving, do not open a PR. Tell the user the session had no durable content and stop. Empty PRs are noise.

## Step 2: Set up the worktree

```bash
DPKB=/Users/rokt/go/src/github.com/ROKT/dpkb
SLUG="{kebab-case description, e.g. enable-github-pages, migrate-wiki, swap-theme-to-primer}"
WORKTREE=/tmp/dpkb-$SLUG

# Make sure local master is current.
git -C "$DPKB" fetch origin master
git -C "$DPKB" worktree add -B "dp/$SLUG" "$WORKTREE" origin/master
cd "$WORKTREE"
```

Operate exclusively inside `$WORKTREE` for the rest of the run. Do not touch the user's primary checkout.

If `$DPKB` doesn't exist or is dirty in a way that prevents a worktree, fall back to:

```bash
git clone git@github.com:ROKT/dpkb.git /tmp/dpkb-skill-clone
cd /tmp/dpkb-skill-clone
git checkout -b "dp/$SLUG" origin/master
```

## Step 3: Plan the edits

Before writing anything, list each intended change:

```
PLAN
- Update services/transactions-gateway/index.md: add new capability
- Create concepts/ambient-mesh-egress.md (new concept page)
- Create runbooks/k8s/declare-egress-serviceentry.md (new runbook)
- Update tooling/buildkite/index.md: add gotcha
- Update glossary.md: add 3 new terms
- Update world-model/capability-index.md: add 1 new line
- Update world-model/pathways.md: add 1 new line
- Update topology.md: add new verb-labeled edge
- Update index.md: link new concept and runbook
- Append to log.md: ingest entry for this session
```

Use the existing taxonomy where it fits. Top-level folders today:

- `services/` — entities Rokt runs.
- `concepts/` — patterns, mental models, business primitives.
- `runbooks/` — state-to-state procedural recipes (formerly `pathways/`).
- `tooling/` — tools Rokt uses but doesn't run (Buildkite, GitHub, Nexus, yeet, the dpkb skill itself).
- `cheatsheets/` — flat invocation references.
- `datalake/` — curated datalake query catalog.
- `reference/` — background reading.
- `world-model/` — actors, capability index, pathway index.

Extend when nothing fits. Use lowercase kebab-case filenames. Folders contain an `index.md` landing page when they hold multiple pages.

When updating existing pages, integrate cleanly: don't just append a section if the right move is to revise an existing one. Flag contradictions explicitly inside the page (e.g. as a `> Note:` callout) rather than silently overwriting.

When citing the session itself, cite the date and a brief framing rather than dumping chat transcripts. The wiki is a compiled artifact, not a transcript archive.

## Step 4: Write the edits

Make all the edits in the worktree. Keep prose tight — write like a wiki page, not like a chat reply. Prefer:

- Short paragraphs over walls of text.
- Code blocks with the language tagged for syntax highlighting.
- Cross-references via relative links (`[GitHub Pages setup](../tooling/github/how-to/enable-pages.md)`) so they work both on GitHub source view and on the Pages site.
- Headings starting at `# Title` (one H1 per page), then `## Section`, etc.

### Per-page conventions

**Every page must carry a `Last updated:` line directly under the H1 title.** Format:

```markdown
# Page Title

_Last updated: 2026-05-02_

Body starts here...
```

When you edit an existing page (any non-trivial edit), update the date to today (`date -u +%Y-%m-%d`). When you create a new page, add the line. Do not skip this — staleness detection and rot prevention depend on it.

When you cite a fact, link to the source if there is one and prefer specific dates over relative phrasing ("as of 2026-05-02" rather than "recently").

### `glossary.md` (single flat alphabetical glossary)

The glossary is the single source of truth for Rokt-specific and DP-specific vocabulary. One file at the repo root, alphabetical by term, each term as `### Term` heading.

Format:

```markdown
# Glossary

_Last updated: 2026-05-02_

A catalog of Rokt-specific and DP-specific terms, acronyms, and jargon. New entries are added by the `/dpkb` skill as terms appear in sessions.

---

### Breakglass

Emergency elevated-access procedure for production systems. See [How to get breakglass access](services/<...>/how-to/breakglass.md).

### CICD subnet

Dedicated VPC subnet in `eng/us-west-2` that hosts CI/CD infrastructure (Buildkite agents, Nexus). See [Nexus](tooling/nexus/index.md).

### Cortex

Internal developer portal at `cortex-api.eng.roktinternal.com`. Distinct from the upstream `Cortex` ML/observability tooling. See [services/cortex/](services/cortex/index.md).

### Soteria

{One-line definition.} See [services/soteria/](services/soteria/index.md).
```

When updating the glossary:
- Insert new terms in alphabetical order; don't append at the end.
- If a term has its own page, link to it from the glossary entry (entity → `services/`, pattern → `concepts/`, tool → `tooling/`).
- If a glossary entry contradicts a previously documented one, update it and bump the file's `Last updated`.
- Disambiguate aggressively when the same word is overloaded internally vs externally.

### `services/` and `topology.md`

Each notable entity (service, queue, dataset, pipeline, third-party SaaS Rokt runs) that the session establishes facts about gets a page under `services/<entity-name>/index.md`. Use a consistent template:

```markdown
# {Entity Name}

_Last updated: 2026-05-02_

> {One-paragraph definition of what this entity is and why it exists.}

## State

- Lifecycle: running | staged | experimental | deprecated | decommissioned | planned | unknown
- As of: 2026-05-02
- Version / region / cluster (if applicable): {detail}

## Owner

- Team: {team name}
- GChat: {space}
- Cortex: {url}

## Repo and observability

- Source: {github url}
- Dashboards: {datadog url}
- Runbooks: {url}

## Capabilities

What an actor can do *through* this entity. Each capability lists the verb, the actor(s) authorized, the precondition, the postcondition, and the invocation. List actually-established capabilities only.

- **enable-pages** — actor: `human (repo admin)` — pre: `repo exists` — post: `Pages source set, first build queued` — invocation: `Settings → Pages → Source: Deploy from a branch` or `gh api -X POST repos/{owner}/{repo}/pages -f build_type=legacy ...`
- **trigger-build** — actor: `human | agent` — pre: `Pages enabled, Actions enabled` — post: `pages-build-deployment workflow runs` — invocation: `gh api -X POST repos/{owner}/{repo}/pages/builds`

## Upstream dependencies

- [{Entity A}](../entity-a/index.md) — *publishes-to* / *reads-from* / *authenticates-against* — {detail}
- {External SaaS X} — {verb} — {what we consume}

## Downstream consumers

- [{Entity B}](../entity-b/index.md) — *consumes* / *triggers* — {what they consume from us}

## Boundaries

- Authn/authz transitions: {description}
- Data classification: {PII / PCI / public / internal}
- Region / VPC: {detail}

## Invariants

Things that must always be true *about this entity*. Be specific. If the same invariant also constrains another entity, repeat it on that entity's page rather than creating a global invariants file.

- {e.g. "Source must be set or no build queues." "Visibility defaults to public on private repos."}

## Concepts this exemplifies

- [Concept: real-time services at Rokt](../../concepts/realtime-services.md) — this entity is a load-bearing example.
- [Concept: hub-spoke replication](../../concepts/hub-spoke-replication.md) — applies to this entity's S3 backend.

## Gotchas

- {Surprising thing operators should know}

## Related

- [Glossary: {term}](../../glossary.md#term)
- [Runbook: {slug}](../../runbooks/{surface}/{slug}.md)
```

`topology.md` lives at the repo root and is the bird's-eye view: a catalog of entities with one-line summaries, plus mermaid diagrams showing the most important interactions (verbs, not just dependencies). Keep each diagram tractable — if it grows past ~25 nodes, split into per-domain subdiagrams. Format:

```markdown
# Topology

_Last updated: 2026-05-02_

High-level view of Rokt entities and how they interact. Each node links to its entity page. Edges are labeled with verbs.

## Diagram

\`\`\`mermaid
flowchart LR
    soteria[Soteria] -->|publishes events to| op2[OP2 Workspace]
    op2 -->|writes to| kafka[(Kafka)]
    kafka -->|consumed by| flipt[Flipt]
\`\`\`

## Entities

- [Soteria](services/soteria/index.md) — {one-line summary} — `running`
- [OP2 Workspace](services/op2/index.md) — {one-line summary} — `running`
- [Flipt](services/flipt/index.md) — {one-line summary} — `running`
```

When the session establishes a new interaction between two entities, update *both* entity pages (upstream/downstream and capabilities sections), **the labeled edge in the diagram**, and any runbook under `runbooks/` that this changes.

### `concepts/` (cross-cutting patterns and mental models)

Each concept gets a page at `concepts/<slug>.md` (or `concepts/<topic>/index.md` if it needs sub-pages). Template:

```markdown
# Concept: {Name}

_Last updated: 2026-05-02_

> One-paragraph definition. What is the concept? Why is it Rokt-specific (or Rokt-flavored)?

## What it is

{Plain-English explanation that a newcomer to Rokt would understand. Avoid jargon; if jargon is needed, link to glossary entries.}

## Why it matters at Rokt

{Why does this pattern recur? What does adopting it buy us? What goes wrong if it's mis-applied?}

## Where it shows up

- [services/<entity-1>](../services/<entity-1>/index.md) — how this concept manifests there
- [services/<entity-2>](../services/<entity-2>/index.md) — ...
- [services/<entity-3>](../services/<entity-3>/index.md) — ...

(At least one entity must be listed. If you can't list even one, the concept page is premature — file it as a glossary entry until enough context accumulates.)

## Disambiguations

- Distinct from [{related-concept}](other-concept.md): {how they differ}
- Distinct from {external sense of the term}: {how the Rokt-internal sense differs}

## Common confusions

- {Misreading 1 — what people new to this think it means}
- {Misreading 2 — common mis-application}

## Related

- [Glossary: <term>](../glossary.md#term)
- [Concept: <related>](<related>.md)
```

When a session reveals a new entity that exemplifies an existing concept, add a line under "Where it shows up." When a session reveals a new concept entirely, file the page and back-link from every entity that exemplifies it.

**Do not create empty / stub concept pages.** A concept page must have a real definition, at least one entity in "Where it shows up", and at least one disambiguation. If the session doesn't establish that much, file the term as a glossary entry instead and revisit on a later session.

### `tooling/` (tools Rokt uses but doesn't run)

Each tool the session uses non-trivially gets a folder at `tooling/<tool>/`:

- `tooling/<tool>/index.md` — the tool entity page (same template shape as a service: state, owner, capabilities, gotchas, invariants), but oriented toward how Rokt-specifically uses the tool rather than what the tool is generically.
- `tooling/<tool>/how-to/<slug>.md` — tool-specific how-tos (procedures with no entry-state precondition).

Tools the wiki already covers: `tooling/github/`, `tooling/nexus/`, `tooling/yeet/`. Likely additions over time: `tooling/buildkite/`, `tooling/gh-cli/`, `tooling/bk-cli/`, `tooling/gws/`, `tooling/helm/`, `tooling/kubectl/` (if the cheatsheet outgrows itself), `tooling/dpkb/` (the skill itself).

When the session uses a tool that doesn't have a page yet, file at least an `index.md` with the canonical CLI / API / auth pattern the session used. Tools differ from services in that we don't run them — but the wiki must still capture *how Rokt-specifically uses them* (which profile, which endpoint, which gotcha applies in our environment).

### `cheatsheets/` (flat invocation references)

Cheatsheets are append-friendly, flat-structured `.md` files at `cheatsheets/<tool-or-topic>.md`. They hold copy-paste-ready commands organized by what the command *does*, not by what the command *is*. The reader scans the section headings looking for a verb that matches their task, then copies the snippet underneath.

Cheatsheets the wiki already covers: `cheatsheets/kubectl.md`, `cheatsheets/argo-rollouts.md`. Cheatsheets are kept as flat files rather than folders because the reader's mental model is "Ctrl-F for the verb I want."

Add or extend a cheatsheet whenever the session's audit Step 1h surfaces commands worth filing. Choose the file:

- If the command's primary CLI matches an existing cheatsheet (`kubectl ...` → `cheatsheets/kubectl.md`; `kubectl argo rollouts ...` → `cheatsheets/argo-rollouts.md`), extend that one.
- If the command belongs to a tool that has a `tooling/<tool>/` entity page but no cheatsheet, consider whether the verb belongs in `tooling/<tool>/index.md`'s `## Capabilities` section (single load-bearing invocation) vs `cheatsheets/<tool>.md` (one of many invocations). Capability if it's *the* canonical way to do X; cheatsheet entry if it's one verb among many that the tool supports.
- If neither fits, create a new `cheatsheets/<tool>.md` from the template below. Keep tool names lowercase and kebab-case.

Cheatsheet template (use this exact section ordering when creating a new file):

```markdown
# {Tool name} Cheatsheet

_Last updated: YYYY-MM-DD_

## {Verb category, e.g. "Configuration" / "Viewing resources" / "Patching" / "Debugging"}

```bash
# Brief description if non-obvious — one line, in prose, above the snippet.
kubectl config get-contexts
kubectl config use-context <context-name>
```

## {Next verb category}

```bash
...
```
```

Conventions for cheatsheet entries:

- **One snippet per verb.** If two different invocations do the same thing with different flags, prefer the one that's *most likely to be the right default* and either omit the alternative or note it inline.
- **Use placeholders, not real values**, except where a real value is *the* Rokt convention (e.g. `--profile rokt-prod`, `--registry-id 035088524874`). Placeholder format is `<angle-brackets>`.
- **Group related commands under one `### Heading`**, with a single fenced code block holding multiple lines. Don't fragment into many separate fences.
- **No prose paragraphs.** Cheatsheets are scanned, not read. If the snippet needs explanation, that explanation belongs on the entity / tool page; the cheatsheet entry should just have a one-line comment above the snippet.
- **No emoji.** No marketing language.
- **Update the `_Last updated:_` line.** Every edit to the file.

When updating an existing cheatsheet:

- Find the right verb-category section first. If none fits, add a new `## <Category>` heading in alphabetical order among sibling H2s.
- If you're adding a snippet that's already there verbatim, skip the edit. If it's a corrected or generalized version, replace the old one rather than appending.
- If a snippet in the cheatsheet has been superseded by a different command (e.g. a deprecation), mark it: a single line above the old snippet like `# Superseded YYYY-MM-DD by ...` is enough, and replace the body.
- Single cheatsheet outgrows itself (file > ~500 lines, or one tool's surface dominates) → promote to a tooling page. Move the verb categories to `tooling/<tool>/index.md` and `tooling/<tool>/how-to/<verb>.md` files, and leave the cheatsheet as a stub redirect.

### `datalake/queries/<domain>/<slug>.md` (curated query catalog)

The datalake query catalog is the wiki's living record of analytical SQL that **ran and produced useful results**. It's organized into `datalake/queries/<domain>/<slug>.md`, where the `<domain>` is one of the established business domains:

- `sessions-attributes/` — attribute coverage, canonicalization parity, attribute extraction
- `revenue-cost/` — revenue per partner / placement, COGS attribution
- `conversions/` — attributed conversions, conversion lift, attribution model audits
- `identity/` — identity-graph queries, FLZ matching, lake_identity exploration
- `audiences-experiments/` — audience composition, experiment-bucketing audits
- `cost-management/` — Cloud Cost / chargeback rollups
- `discovery-meta/` — *meta* queries (schema discovery, table inventory)
- `external-match/` — third-party identity match-rate audits
- `account-lookup/` — account / advertiser / partner directory queries

If the session's query doesn't fit an existing domain, don't invent one without checking [`datalake/queries/index.md`](https://github.com/ROKT/dpkb/blob/master/datalake/queries/index.md) — the existing folders are the established taxonomy and adding a new top-level domain is a bigger decision than adding a query. If you must add a new domain, do it in the PR description as an explicit call-out.

**Always use the template from [`datalake/how-to/write-a-new-query.md`](https://github.com/ROKT/dpkb/blob/master/datalake/how-to/write-a-new-query.md).** The skill should not duplicate that template here — the source of truth is the how-to page in the wiki. The required sections at minimum are:

1. `# Query: <short title>` — H1, descriptive of the *question*.
2. `_Last updated: YYYY-MM-DD_`
3. **Intent** — the business / debugging question, in prose. One paragraph.
4. **Technique** — which named patterns from `datalake/techniques.md` are at play. Bullet list.
5. **Tables** — which source tables. Bullet list with links to `tables/<table>.md` pages.
6. **Query** — the SQL, in a single fenced block, tagged `sql`. Include all CTEs, all comments preserved.
7. **Sample output / typical row count** — what the reader should expect to see when they run it.

Conventions:

- **Pre-write the query for the next reader.** Strip session-specific accident — replace hardcoded account IDs with `<account-id-placeholder>` unless the account ID is a load-bearing example. Add a `WHERE eventtime > now() - interval '1' HOUR` placeholder where the session used a wider window for one-off investigation.
- **Cite the techniques.** Cross-reference `datalake/techniques.md` entries by name. The technique section is what makes a query *teachable*, not just *re-runnable*.
- **Cross-link table pages.** Each table mentioned should be a link to its `tables/<table>.md` page. If the page doesn't exist, do not silently skip — either add a minimal stub page or call out the gap in the PR description.
- **Engine matters.** If the query needs Spark Connect (large reads, Iceberg DDL, writes), say so in the Intent section. Default assumption is Trino-via-Superset.
- **One query per file.** Don't bundle "and here's a variation that uses the other table" into the same page — make a second file in the same `<domain>/` folder and cross-link.

When updating an existing query page:

- If the new version is an improvement (faster, more correct, handles a previously-unknown edge case), revise the existing file and add a short note in the prose indicating what changed and when. Do not create a near-duplicate page.
- If the session ran the same query but with a different time window or against a different partner, that's not a new query — note the variation in the existing file's Intent section if it materially changes the result interpretation, or skip.

### `world-model/` (folder)

The world-model layer is a small folder of index pages. It is *not* a content store — every fact lives on the entity, concept, or runbook page it concerns. The world-model pages exist to route a planning-oriented reader to the right content.

Files:

- `world-model/index.md` — landing page. One paragraph on what's in this folder, links to the sub-pages.
- `world-model/actors.md` — the actor catalog.
- `world-model/capability-index.md` — every capability across every entity, sorted by verb, each linked to the `#capabilities` anchor on the defining page.
- `world-model/pathways.md` — every runbook under `runbooks/`, sorted by surface, each with an initial-state → goal-state one-liner.

`world-model/index.md` skeleton:

```markdown
# World model

_Last updated: 2026-05-02_

The model an agent uses to plan in this environment. Entities live in `services/`; concepts live in `concepts/`; runbooks live in `runbooks/`. This folder indexes them through a planning lens.

- [actors.md](actors.md) — who / what can perform actions, and what their affordances are
- [capability-index.md](capability-index.md) — every capability across the system, sorted by verb
- [pathways.md](pathways.md) — every runbook, sorted by surface, with state-transition summaries

## How to use this

When asked "*how do I make X happen?*", start in `pathways.md` and look for a runbook that ends in state X.
When asked "*can entity Y do Z?*", start in `capability-index.md` and look for the verb that names Z.
When asked "*who is allowed to do Z?*", start in `actors.md`.
```

`world-model/actors.md` skeleton:

```markdown
# Actors

_Last updated: 2026-05-02_

Different actors have different affordances; what one can do another may not. New actors are added by `/dpkb` as sessions surface them.

- **Human (engineer)** — normal Rokt org credentials; can edit repos, open PRs, query Datadog.
- **Human (admin / role-specific)** — elevated; one bullet per named role (e.g. storage admin, rollout-edit, breakglass profiles).
- **Agent** — LLM agent acting on a user's behalf with their gh / Datadog / kube / AWS creds; capabilities ≤ user's.
- **CI (Buildkite, GitHub Actions)** — pipeline-scoped service-account identities.
- **System (<name>)** — non-human / service-account / scheduled actors. One bullet per named system.
```

`world-model/capability-index.md` skeleton:

```markdown
# Capability index

_Last updated: 2026-05-02_

Every capability across the wiki, sorted by verb. Each links to the entity page that defines it. New capabilities are added inline on the entity page first; this index just routes the reader.

- *create-notebook* — [Datadog](../services/datadog/index.md#capabilities)
- *enable-pages* — [GitHub Pages on dpkb](../services/github-pages/index.md#capabilities)
- *retry-job* — [Buildkite](../tooling/buildkite/index.md#capabilities)
- ...
```

`world-model/pathways.md` skeleton:

```markdown
# Pathway index

_Last updated: 2026-05-02_

Every runbook in the wiki, grouped by surface, with a one-line state-transition summary. The runbook files themselves live under `runbooks/`.

## kafka/

- [diagnose-disk-pressure](../runbooks/kafka/diagnose-disk-pressure.md) — Datadog page → at-risk brokers identified, root cause, mitigation chosen
- ...

## k8s/

- [debug-istio-ambient-egress-failure](../runbooks/k8s/debug-istio-ambient-egress-failure.md) — app sees TCP EOF to external FQDN → owner identified for next step
- ...

## release/

- ...
```

**What does NOT belong in `world-model/`:**

- ❌ A cross-cutting invariants page. Invariants are properties of entities (or, when patterns, of concepts). There is no global file.
- ❌ Open questions / todos. The wiki is for established knowledge. If a session leaves a question open, it stays in chat — let the next session find the answer.
- ❌ Decisions / rejected alternatives. These belong on the entity page (as a "Why" subsection) or, if architecturally significant, as a concept page that explains the pattern that was chosen and why.

Update `world-model/` whenever the session adds a capability, a runbook, or a new actor distinction. If the session only added a fact to a single entity page, you do *not* need to touch `world-model/`.

### `runbooks/{surface}/{slug}.md` (state-to-state recipes)

A runbook is the **planning artifact**. It describes a sequence of capabilities that transforms the world from one state to another, with explicit pre-conditions, post-conditions, and the actors who can drive each step.

Create a runbook whenever the session walks through a non-trivial multi-step procedure that an agent or human might want to repeat or replay, and the procedure has both a defined starting state and a defined ending state. Single-capability actions don't need a runbook — they live on the entity page.

Format:

```markdown
# Runbook: {Goal}

_Last updated: 2026-05-02_

> {One-line statement of the goal. Example: "Get a private repo serving as a GitHub Pages site, gated to org members."}

## Initial state

- {Pre-condition 1}
- {Pre-condition 2}

## Goal state

- {Post-condition 1}
- {Post-condition 2}

## Steps

| # | Capability | Actor | Pre-condition | Post-condition | Notes |
|---|---|---|---|---|---|
| 1 | [enable-pages](../../services/github-pages/index.md#capabilities) | human (repo admin) | repo exists, default branch has README | Pages source set | Settings → Pages |
| 2 | [enable-actions](../../services/github-actions/index.md#capabilities) | human (repo admin) | — | Actions allowed for repo | Required: legacy Pages builds run on Actions infra |
| 3 | [trigger-build](../../services/github-pages/index.md#capabilities) | human or agent | steps 1+2 complete | first build queued | `gh api -X POST .../pages/builds` |
| 4 | (wait) | system | step 3 complete | site live at discovered URL | `gh api .../pages` returns `status: built` |

## Failure modes

- **Step 3 silently no-ops** if Actions is disabled at the org level — surface to user, escalate to GitHub admin.
- **Site 404s after step 4** if visibility is set to private and viewer is not logged into the org.

## Invariants

Properties that hold throughout the procedure. (These are *runbook* invariants — they apply to the recipe, not to a single entity.)

- Default branch must contain at least one renderable markdown file (`README.md` or `index.md`).
- Site URL is determined by Pages, not chosen — read it from `gh api repos/{owner}/{repo}/pages --jq .html_url`.

## Related

- [Topology](../../topology.md)
- [World model](../../world-model/index.md)
- [services/github-pages/](../../services/github-pages/index.md)
- [Concept: GitHub Pages at Rokt](../../concepts/github-pages-at-rokt.md) (if a relevant concept page exists)
```

Runbooks are append-friendly — when a new way to reach the same goal is discovered, add an *Alternative* section rather than rewriting from scratch, so the planning history is preserved.

### `index.md` (catalog)

The repo-root `index.md` is content-oriented — a catalog of every page in the wiki, grouped by category. Update it whenever you add or significantly revise a page. Skeleton:

```markdown
# Index

_Last updated: 2026-05-02_

## Reference

- [Glossary](glossary.md) — Rokt-specific vocabulary, acronyms, jargon
- [World model](world-model/index.md) — actors, capability index, pathway index
- [Topology](topology.md) — entities and how they interact
- [Log](log.md) — chronological record of dpkb ingests
- [README](README.md) — front door

## Services

- [services/<entity>](services/<entity>/index.md) — {summary} — `running`
- ...

## Concepts

- [concepts/<concept>](concepts/<concept>.md) — {one-line definition}
- ...

## Runbooks

- [runbooks/<surface>/<slug>](runbooks/<surface>/<slug>.md) — {initial state → goal state}
- ...

## Tooling

- [tooling/<tool>](tooling/<tool>/index.md) — {how Rokt uses it}
- ...

## Datalake

- [datalake/](datalake/index.md) — start here
- ...

## Cheatsheets

- [cheatsheets/<topic>](cheatsheets/<topic>.md) — {flat invocation reference}
- ...

## Reading

- [reference/llm-wiki.md](reference/llm-wiki.md) — Karpathy's pattern that this repo is organized around
```

Update the `Last updated` of `index.md` whenever you change it.

### `log.md` (chronological)

Append-only chronological record. Each entry has the form:

```markdown
## [YYYY-MM-DD] ingest | {short title}

{1-3 sentence description of what was filed and why.}

Touched:
- {path/to/page1.md} — {what changed}
- {path/to/page2.md} — {what changed}
```

Use the actual current date (run `date -u +%Y-%m-%d`). Append the new entry to the bottom of the file. Do not rewrite earlier entries.

### `README.md`

Only edit `README.md` if a new top-level page or a new top-level folder was added that should appear in the navigation. Don't churn the README on every ingest.

## Step 5: Lint pass

Before yeeting, do a quick lint sweep over the wiki — even pages you didn't touch in this ingest. Rot is the dominant failure mode of any knowledge base; this step is what keeps it healthy.

Run these checks:

1. **Last-updated freshness.** List pages whose `Last updated:` date is more than 180 days old. Flag them in the PR description as "potentially stale" — do not silently update their date stamps. The user can review and either confirm-still-current (touch the date) or schedule a re-ingest.
2. **Missing `Last updated:` line.** Any page that doesn't have one. If you authored or edited the page in this run, add it. If it's an existing page, list the offenders in the PR description rather than blindly editing.
3. **Glossary coverage.** For each Rokt-specific term that appeared in the session, verify it has a glossary entry. Add missing entries.
4. **Entity ↔ topology consistency.** If `services/X/index.md` exists, it should appear in `topology.md`'s catalog. If `topology.md` mentions an entity, the corresponding `services/X/index.md` should exist (a stub page is fine if the session didn't establish enough — mark it `> Stub` and link the glossary entry).
5. **Broken relative links.** Any link of the form `[...](some/path.md)` should resolve to a real file.
6. **Orphaned pages.** Pages that aren't reachable from `README.md` or `index.md`. List them in the PR description; don't auto-link them.
7. **Contradictions.** If you flagged a contradiction earlier (Step 1e), make sure the inline `> Note: superseded ...` callout is present on the relevant page.
8. **Entity state hygiene.** Every entity page must have a `## State` section with a lifecycle value. Flag entity pages whose state is `unknown` for more than 90 days.
9. **Capability ↔ world-model index consistency.** Every capability listed on an entity page must appear in `world-model/capability-index.md`. Every capability in the index must be defined on at least one entity page. Surface drift in the PR description.
10. **Runbook ↔ world-model pathway index.** Every file under `runbooks/` must be linked from `world-model/pathways.md` and from `index.md`. Each step in a runbook must reference a capability that actually exists on the named entity page (verify the anchor `#capabilities` resolves to a real section).
11. **Concept ↔ entity bidirectionality.** Every concept page must list at least one entity under "Where it shows up." Every entity that's a load-bearing example of a concept should link back to that concept under "Concepts this exemplifies." Surface drift in the PR description.
12. **Edge labels in topology diagram.** Every edge in `topology.md`'s mermaid diagram(s) should be verb-labeled (`-->|verb|`), not bare `-->`. Bare edges are a code smell — they hide what kind of interaction is happening. Flag any unlabeled edges.
13. **Cheatsheet hygiene.** For each file in `cheatsheets/`, verify (a) it has a `_Last updated:_` line, (b) sections are H2 verb-categories not H3-on-H1, (c) no duplicate snippets within a section, (d) no prose paragraphs (cheatsheets are scanned, not read), (e) no placeholder values that should be real conventions (e.g. `--profile <profile>` where the convention is `--profile rokt-prod` or `--profile rgi-prod-bg`). Flag violations in the PR description.
14. **Datalake query template compliance.** For each file in `datalake/queries/<domain>/`, verify it follows the template from `datalake/how-to/write-a-new-query.md` — required sections are Intent, Technique, Tables, Query, Sample output. Verify that every table referenced in the Tables section has a corresponding `datalake/tables/<table>.md` page; flag missing table pages as a gap (don't auto-create). Verify that techniques referenced in the Technique section actually exist in `datalake/techniques.md`; flag missing or stale technique cross-references.
15. **Forbidden content.** Surface and flag (do not silently delete) anything that violates the wiki's content rules:
    - Any "Open questions" or "TODO" or "Backlog" section on any page → call out for removal.
    - Any cross-cutting invariants file (e.g. a legacy `invariants.md` or an invariants section in `world-model/`) → call out for migration to entity / concept pages.
    - Any concept page with no entities listed under "Where it shows up" → premature; recommend demoting to a glossary entry.
    - Any runbook with no defined initial state and goal state → not a runbook; recommend moving to a `how-to/` under the relevant entity.
    - Any cheatsheet entry that's pure prose with no command underneath → either move to the tool's entity page or delete.
    - Any datalake query page that doesn't run successfully on a fresh attempt (note: this skill can't actually verify by running the query, but if you have evidence the query is broken from the session, flag it for review).

Capture the lint findings in a structured section of the PR body so the user can see at-a-glance what's healthy and what needs follow-up.

## Step 6: Yeet

From inside `$WORKTREE`, invoke the yeet flow. The worktree is on `dp/$SLUG` already, so you can stage, commit, push, and open the PR directly per the `yeet` skill. The PR description must be detailed prose: what the session was about, what was extracted, why those things were chosen, what was added vs updated, and a list of touched files.

PR title format: `dpkb ingest: {short summary}`

Use a HEREDOC or temp file for the body, never inline `\n`-escaped markdown.

## Step 7: Merge

Immediately merge the PR after it's opened:

```bash
gh pr merge --squash --delete-branch --auto $(gh pr view --json number -q .number)
```

If `--auto` rejects (no required checks configured), fall back to:

```bash
gh pr merge --squash --delete-branch $(gh pr view --json number -q .number)
```

This repo has no CI, so squash-merge is safe and immediate. Do not push directly to `master` — always go through the PR for the audit trail.

## Step 8: Clean up

After the merge succeeds:

```bash
cd "$DPKB"
git worktree remove "$WORKTREE"
git worktree prune
git fetch origin master
git -C "$DPKB" checkout master 2>/dev/null || true
git -C "$DPKB" pull --ff-only
```

Don't fail loudly if the user's primary checkout is on a different branch — just leave it where it is. The point is to reclaim disk space and not litter `/tmp`.

## Step 9: Report back

Give the user:

- The PR URL.
- The merge commit SHA.
- A bulleted list of pages touched (paths only), grouped by created vs updated.
- A short summary of glossary entries added/updated.
- **Concept deltas:** new concept pages, new entities added under existing concepts' "Where it shows up", any concept disambiguation revised.
- **World-model deltas:** new entities, lifecycle state changes, new capabilities (note: inlined on the entity; surfaced in `world-model/capability-index.md`), new runbooks (surfaced in `world-model/pathways.md`), new actors (in `world-model/actors.md`). This is the substantive output — it's what an agent in a future session can plan over.
- Any topology edge changes (added, relabeled, or removed verbs).
- **Lint findings** that need user attention (stale pages, missing date stamps, orphans, contradictions, capability drift, unlabeled topology edges, premature concept pages, forbidden content). Don't bury these — they're the rot-prevention output and the user should see them every run.
- The Pages site URL so they can see the rebuilt site once it deploys (~1 minute): https://potential-adventure-qjoqm67.pages.github.io/

Keep it short. The wiki itself is the durable record now.

## Conventions and constraints

- **Always branch from `origin/master`**, never from whatever the user's local checkout has.
- **Branch name** must start with `dp/` (matches the `yeet` skill).
- **One PR per `/dpkb` invocation.** If the session covers multiple unrelated topics, you may still file them in one PR, but make the PR body and the `log.md` entry call out the distinct topics. Don't open multiple PRs from one invocation.
- **Never delete pages** without an explicit instruction from the user. Updating and superseding is fine; deletion is destructive.
- **Never put secrets, tokens, internal hostnames, or PII into the wiki**, even if they showed up in the session. The repo is private but the Pages site visibility is not guaranteed to be private — assume the rendered site could be reached by anyone in the org.
- **Respect existing voice.** Pages in this wiki are written in plain, terse American English. Avoid marketing language, hedging filler ("simply", "just", "easy"), and emoji.
- **Trust the taxonomy.** Reuse the existing top-level folders (`services/`, `concepts/`, `runbooks/`, `tooling/`, `cheatsheets/`, `datalake/`, `reference/`, `world-model/`) when they fit. Create new top-level folders sparingly and only when no existing one fits.
- **Knowledge, not questions.** The wiki captures established facts and patterns. Open questions, todos, and "we should investigate X" belong in chat or log entries, not on entity pages or in `world-model/`.
- **Invariants live on the entity they constrain.** Don't create cross-entity invariants pages. If an invariant spans 2+ entities, repeat it on each with a cross-reference. If it's really a recurring *pattern*, file it as a concept.
- **Concepts are the ontology layer.** When a session uses a term that points at a mental model rather than a thing, file or extend a concept page. Concepts make the wiki teachable to a newcomer.
- **World-model first.** Before writing prose, ask: "what does an agent reading this learn about *what exists, what's possible, and how to get from state X to state Y*?" Prefer encodings (capabilities tables, runbook tables, verb-labeled edges, lifecycle state) over narrative descriptions when both could capture the same fact. Prose is fine, but it should sit alongside structured world-model artifacts, not replace them.
- **Working commands compound — file them.** Every session-confirmed non-trivial command that worked is a candidate for `cheatsheets/`. Filter aggressively (see Step 1h) — most commands aren't cheatsheet material — but file the ones that pass the bar without prompting. The wiki's value compounds because the *next* time someone reaches for the same verb, the cheatsheet entry shortcuts the rediscovery work.
- **Running queries compound — file them.** Every session-confirmed datalake query that ran and returned useful results is a candidate for `datalake/queries/<domain>/`. Filter via Step 1i — schema-discovery one-offs don't qualify, but real-question queries do. Follow the template at `datalake/how-to/write-a-new-query.md`. Cross-link tables and techniques so the query teaches, not just executes.

## Failure modes

- **Worktree creation fails** because the branch already exists locally — delete the stale branch with `git -C "$DPKB" branch -D dp/$SLUG` and retry.
- **Push fails** because the branch already exists on origin — append a counter (`dp/$SLUG-2`) and retry.
- **PR merge fails** because of branch protection — surface the failure to the user with the PR URL and stop. Do not force-merge.
- **Nothing durable in the session** — explicitly tell the user "no durable content found, skipping" and exit without creating a branch, PR, or worktree.
- **Concept page proposed but the session doesn't establish enough.** Don't create a stub. File the term as a glossary entry until a later session accumulates enough context to write a real concept page (definition + at least one entity under "Where it shows up" + at least one disambiguation).
- **Runbook proposed but the procedure has no defined initial state or no defined goal state.** It's a how-to, not a runbook. File it under `services/<entity>/how-to/` or `tooling/<tool>/how-to/` instead.
- **Tooling page proposed but the tool is only used once.** Still create it — the first use is the most valuable thing to capture (which CLI, which profile, which Rokt-specific quirk applied). Just keep the page minimal.
- **Cheatsheet entry proposed but the command is a one-line man-page recipe.** Skip. `kubectl get pods` doesn't need to be in a cheatsheet; `kubectl patch deployment --type=json -p '...'` does. The bar is "would I want this at my fingertips" not "did I use it this session."
- **Cheatsheet entry proposed but it duplicates a `## Capabilities` entry on a tooling page.** Pick one home: capability if it's *the* canonical invocation for a load-bearing operation; cheatsheet entry if it's one of many invocations of the same tool. Don't keep both.
- **Datalake query proposed but it errored or returned wrong data.** Skip. Wrong-result queries are anti-patterns and belong nowhere. The single exception is documenting a known-pitfall query *as* an anti-pattern in `datalake/techniques.md`.
- **Datalake query proposed but no matching table page exists.** Don't silently skip — either add a minimal stub `datalake/tables/<table>.md` page that captures what the session learned about the table (schema, partition column, typical row count, sample value shapes), or call out the gap in the PR description and leave the query unfilled. Filing a query that references a non-existent table page leaves a broken cross-reference that the lint pass will surface anyway.
- **Datalake query references a technique not in `techniques.md`.** Either add the technique to `techniques.md` (if it's a recurring pattern that should be teachable) or rewrite the query's Technique section to use only documented patterns. Don't ship a query that references undocumented techniques.
