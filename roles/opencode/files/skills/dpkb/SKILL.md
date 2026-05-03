---
name: dpkb
description: "Ingest the current OpenCode session into the dpkb wiki (Dan Piet's Knowledge Base) as a world model an agent can plan over. Reviews the session and extracts durable content across six dimensions: domain ontology/definitions (glossary), entities and topology with state (services/ + topology), concepts/facts/runbooks/decisions, gotchas/contradictions, citable sources, and a world model layer that encodes what exists, what's possible, what interactions can occur, what pathways exist between states, what actors can act, and what invariants hold (world-model.md + pathways/). Stamps every touched page with `Last updated: YYYY-MM-DD` and runs a lint pass for staleness, missing dates, broken links, glossary gaps, topology drift, capability/world-model drift, pathway integrity, and unlabeled topology edges. Updates the wiki at github.com/ROKT/dpkb in a fresh worktree on a new branch, opens a PR via the yeet flow, and merges. Encodes the LLM-Wiki pattern from llm-wiki.md (Karpathy). Run when the user invokes /dpkb or asks to file the session into the wiki."
---

# dpkb — file the session into the wiki

## Purpose

The user's persistent knowledge base is the GitHub repo `ROKT/dpkb`. This skill takes whatever is durable and useful from the current OpenCode session — concepts, facts, decisions, runbook-shaped procedures, gotchas, links to authoritative sources — and integrates it into that wiki, in the spirit of the LLM-Wiki pattern described in `llm-wiki.md` at the repo root.

The session is the **raw source**. The wiki is the **persistent, compounding artifact**. The skill's job is to compile the former into the latter.

### The wiki is a world model, not a notebook

The first-order purpose of the wiki is to be a **world model an agent can plan over.** Future agents (and humans acting like agents) will read this wiki to answer questions like *"What exists in this environment? What can I do? What state is the system in? How do I get from state X to state Y?"* That framing changes what counts as durable content:

- **What exists** — entities and their current state. Not just "Soteria is a service" but "Soteria is *running in production*, owned by *team X*, version *Y as of YYYY-MM-DD*."
- **What's possible** — *capabilities and affordances* each entity exposes. "Buildkite can re-trigger any job by ID." "GitHub Pages can serve from `master` or from Actions output." Capabilities are the verbs an actor can invoke through an entity.
- **What interactions exist** — typed edges between entities and actors. "Service A *publishes* to Topic B." "Engineer *enables* Pages by editing Settings → Pages." Distinct from static topology dependencies — interactions describe action.
- **What pathways exist between states** — pre-condition → action → post-condition chains. "To get a private repo serving Pages: repo exists → Pages enabled → Actions enabled → Source set → first build queued → site live." This is the planning substrate.
- **What actors exist** — who/what can perform interactions. Humans, agents, CI, schedulers, scripts. Different actors have different affordances and credentials.
- **Invariants and constraints** — what must always be true, what is never allowed. "Never push directly to master." "Pages site visibility defaults to public on private repos."

Every audit pass should ask not just "what facts came up?" but **"what does this teach an agent about the world?"** When in doubt, prefer encodings that an agent could plan with over prose that only a human can read.

## Prerequisites

- `gh` CLI installed and authenticated (`gh auth status`). If not, stop and ask the user to authenticate.
- `git` >= 2.5 (worktrees).
- The dpkb repo already cloned locally at `/Users/rokt/go/src/github.com/ROKT/dpkb`. If it isn't, fall back to cloning into a fresh `/tmp/dpkb-skill-clone` and operate from there.
- Network access to github.com.

## High-level workflow

1. **Audit the session** — review every user message, assistant message, tool call, and tool result in the conversation so far. Identify content worth preserving across six dimensions: ontology/definitions, entities/topology (with state), concepts/facts/runbooks/decisions, gotchas/contradictions, citable sources, and **world model** (capabilities, pathways, actors, invariants).
2. **Set up a worktree** — `git worktree add /tmp/dpkb-{slug} -b dp/{slug}` from the existing dpkb checkout, branching off the latest `master`.
3. **Plan the edits** — decide which existing pages to update, which new pages to create, which glossary entries to add, which service/topology updates are needed, and which capabilities, pathways, or world-model index entries the session reveals. Follow the existing taxonomy where it fits; extend it when it doesn't. You are trusted to do the right thing.
4. **Write the edits** — edit/create pages in the worktree only. Maintain `glossary.md` (alphabetical), `services/` (with state, capabilities, invariants), `topology.md` (with verb-labeled edges), `world-model.md` (actors, capability index, pathway index, cross-cutting invariants), `pathways/` (state-to-state recipes), `index.md`, and append to `log.md`. Stamp every touched page with `_Last updated: YYYY-MM-DD_`. Update `README.md` TOC if new top-level pages are added.
5. **Lint pass** — sweep the wiki for staleness, missing date stamps, broken links, glossary gaps, entity/topology drift, capability/world-model drift, pathway integrity, unlabeled topology edges, orphans, and contradictions. Capture findings in the PR body.
6. **Yeet** — invoke the `yeet` skill from inside the worktree to commit, push, and open a PR.
7. **Merge** — once the PR is open, merge it via `gh pr merge --squash --delete-branch`. CI is intentionally not configured for this repo, so merging immediately is safe.
8. **Clean up** — remove the worktree and prune.
9. **Report back** — give the user the PR URL, what landed (including any new capabilities, pathways, or world-model edits), and any lint findings that need follow-up.

## Step 1: Audit the session

Before touching the wiki, do an explicit inventory pass across the dimensions below. The point of this pass is to surface durable content the wiki should hold, not to summarize what happened in chat.

### 1a. Domain ontology and definitions

The Rokt-specific *vocabulary* is one of the highest-value things this wiki can hold. It's the thing that's hardest to recover later and the thing newcomers spend the most time piecing together.

For every Rokt-specific or DP-specific term, system, acronym, or jargon word that appears in the session, ask:

- Is there already a definition in `glossary.md`?
- If not: add one.
- If yes but stale, ambiguous, or wrong: revise it.

Examples of things that belong in the glossary (illustrative, not exhaustive): "Soteria", "OP2", "wsdk", "Ratify", "CICD subnet", "SDP", "breakglass", "monitor_gate", "roktinternal", "Cortex" (the internal one — disambiguate from the upstream tool).

If a term has enough surface area to deserve its own page, link the glossary entry to that page (`See [Soteria](services/soteria.md)`).

### 1b. Entities — what exists, with state

Anything that looks like a system component — a service, a queue, a dataset, a pipeline, a third-party SaaS we depend on, a piece of infrastructure — is an **entity** in the world model. Each gets a page under `services/` (one page per entity, despite the historical "services" name) and a node in `topology.md` (the bird's-eye view).

Per entity, capture (only what was actually established in the session — don't fabricate):

- **Purpose.** One-line definition of what it does.
- **State.** Current lifecycle status: `running` | `staged` | `experimental` | `deprecated` | `decommissioned` | `planned` | `unknown`. Date-stamp the state.
- **Owner.** Team / GChat space / Cortex entity if known.
- **Repo / dashboards.** Links to the source repo, Datadog dashboards, Cortex page, runbooks.
- **Capabilities (affordances).** What this entity *enables an actor to do*. (See 1f below — this is the world-model substrate.)
- **Upstream dependencies.** What it calls / consumes / reads from.
- **Downstream consumers.** What calls it / consumes its data.
- **Trust / data boundaries.** Where authn/authz changes, where regulated data crosses (PII, PCI, secrets), where regions or VPCs change.
- **Invariants and constraints.** Things that must always be true about this entity ("only the platform team can deploy"; "writes are append-only").
- **Known gotchas.** Operational footguns specific to this entity.

`topology.md` is the index of entities with a high-level diagram (mermaid is supported by GitHub markdown rendering — use it sparingly, but a small `flowchart LR` showing the few systems touched in this session is often the most useful artifact you can produce). **Edges in the diagram should be labeled with verbs**, not just "depends on" — `publishes`, `consumes`, `writes`, `triggers`, `authenticates against`. Verbs make the topology a world model rather than a static graph.

When the session establishes a *new interaction* between two existing entities (e.g. "service A now writes to topic B"), update both entity pages, the topology diagram, **and** the relevant pathway in `world-model.md` if one exists.

### 1c. Concepts, facts, runbooks, decisions

These are the original four buckets — keep them, but they're now subordinate to the ontology and topology work above:

- **Concepts.** Patterns, design ideas, architectural choices that aren't a single service but inform how systems are built. ("How we do feature flags", "How releases are gated".)
- **Facts.** Specific established truths the wiki should hold. ("Pages source is legacy `Deploy from a branch` from `master` /", "the rendered Pages URL for this repo is `potential-adventure-qjoqm67.pages.github.io`", "we squash-merge to master".)
- **Runbooks.** Step-by-step procedures someone would want to look up later. Belong under a `how-to/` subfolder of the relevant root node. ("How to enable GitHub Pages on a private Rokt repo", "How to swap the Jekyll theme".)
- **Decisions.** Especially when alternatives were considered and rejected — the *why* is the durable value. Capture as `decisions/{slug}.md` if it's a significant architectural choice; inline as a "Why" subsection on the relevant page if smaller.

### 1d. Gotchas and contradictions

Footguns, surprising defaults, things-that-look-like-they-should-work-but-don't. These deserve prominent placement on the relevant page (often as a `> ⚠ Note:` callout near the top), not buried at the end. Examples: "Private repo Pages defaults to public visibility", "Actions disabled at repo level silently blocks legacy Pages builds", "Cayman theme is shaped for single-page sites, not multi-page wikis".

If the session contradicts something already in the wiki, do not silently overwrite — flag it inline (`> Note: superseded {YYYY-MM-DD} — was previously documented as X, see [log](../log.md)`).

### 1e. Sources to cite

Links to GitHub docs, gists, internal Cortex/Confluence/Notion pages, Datadog dashboards, design docs, slack threads (if linkable), etc. Cite them inline on the relevant page using normal markdown link syntax. Don't accumulate a separate "sources" page unless the session genuinely produced a curated reading list.

### 1f. World model — capabilities, pathways, actors, invariants

This is the **most important new dimension** if the session involved doing work, debugging, or planning. The wiki is a world model an agent can plan over; this is where you make sure that's true.

For every entity touched in the session, ask:

- **What capabilities does this entity expose?** Things an actor can invoke through it. ("GitHub Pages exposes `enable`, `set-source`, `set-visibility`, `trigger-build`." "Buildkite exposes `create-build`, `retry-job`, `cancel-build`, `tail-logs`.") File these under a `## Capabilities` section on the entity's page, each with: a verb, the actor(s) who can invoke it, the precondition(s), the post-condition, and the invocation method (UI path, CLI command, API endpoint).

- **What pathways between states did the session reveal?** A pathway is a sequence of capabilities that transforms the world from state X to state Y. ("To get a private repo serving Pages: repo exists → Pages enabled → Actions enabled → Source set → first build queued → site live.") Pathways are the planning substrate — they are what an agent reads to figure out how to accomplish a goal. File them under `pathways/{slug}.md` and cross-reference them from the relevant entity pages.

- **What actors performed interactions?** Distinguish between actors with different affordances:
  - **Human** — anyone in the org with normal credentials.
  - **Agent** — an LLM agent like OpenCode running with the user's gh/cloud creds.
  - **CI/scheduler** — automated runners (Buildkite, GitHub Actions, cron).
  - **Service account** — non-human credentials.
  An action that requires breakglass admin is not the same as one any engineer can perform; capture the distinction explicitly.

- **What invariants emerged?** Things that must always hold, or things that must never happen. ("Pages source must be set or no build is queued." "Actions must be enabled at the repo level for legacy Pages builds to fire — even though the docs don't say so.") File these under an `## Invariants` section on the entity's page, or in `world-model.md` if they cut across entities.

- **What pre-conditions and post-conditions were established?** Even when not formalized as a full pathway, individual capabilities should record: *given X, doing Y produces Z*. This is the atomic unit of planning knowledge.

The aggregate goal: after this skill runs, an agent reading the wiki should be able to answer not just *"what is X?"* but *"how do I make X happen?"* and *"what state is the world in such that X is possible?"* If you can't answer those questions from the pages you've written, the world model is incomplete.

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
- Update tooling/github.md: add section on enabling GitHub Pages
- Create tooling/how-to/enable-github-pages.md (new runbook)
- Update README.md: add link to the new how-to under Tooling
- Update index.md: add entry for the new page
- Append to log.md: ingest entry for this session
```

Use the existing taxonomy where it fits (`build/`, `compute/`, `languages/`, `network/`, `release/`, `storage/`, `tooling/`, plus root-level cheatsheets like `kubectl-cheatsheet.md`). Extend it when nothing fits — for example, if the session was about CI and there's no `ci/` folder, create one. Use lowercase kebab-case filenames. Follow the convention that folders contain an `index.md` landing page when they hold multiple pages.

When updating existing pages, integrate cleanly: don't just append a section if the right move is to revise an existing one. Flag contradictions explicitly inside the page (e.g. as a `> Note:` callout) rather than silently overwriting.

When citing the session itself, cite the date and a brief framing rather than dumping chat transcripts. The wiki is a compiled artifact, not a transcript archive.

## Step 4: Write the edits

Make all the edits in the worktree. Keep prose tight — write like a wiki page, not like a chat reply. Prefer:

- Short paragraphs over walls of text.
- Code blocks with the language tagged for syntax highlighting.
- Cross-references via relative links (`[GitHub Pages setup](../tooling/how-to/enable-github-pages.md)`) so they work both on GitHub source view and on the Pages site.
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

If `glossary.md` does not yet exist, create it. Format:

```markdown
# Glossary

_Last updated: 2026-05-02_

A catalog of Rokt-specific and DP-specific terms, acronyms, and jargon. New entries are added by the `/dpkb` skill as terms appear in sessions.

---

### Breakglass

Emergency elevated-access procedure for production systems. See [How to get breakglass access](how-to/breakglass.md).

### CICD subnet

Dedicated VPC subnet in `eng/us-west-2` that hosts CI/CD infrastructure (Buildkite agents, Nexus). See [Nexus](tooling/nexus.md).

### Cortex

Internal developer portal at `cortex-api.eng.roktinternal.com`. Distinct from the upstream `Cortex` ML/observability tooling. See [Cortex skill](https://github.com/ROKT/...).

### Soteria

{One-line definition.} See [services/soteria.md](services/soteria.md).
```

When updating the glossary:
- Insert new terms in alphabetical order; don't append at the end.
- If a term has its own page, link to it from the glossary entry.
- If a glossary entry contradicts a previously documented one, update it and bump the file's `Last updated`.
- Disambiguate aggressively when the same word is overloaded internally vs externally (e.g. "Cortex" the internal portal vs "Cortex" the external SaaS).

### `services/` and `topology.md`

Each notable entity (service, queue, dataset, pipeline, third-party SaaS) that the session establishes facts about gets a page under `services/{entity-name}.md`. Use a consistent template — note that the template has expanded to capture world-model dimensions (state, capabilities, invariants):

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

- [{Entity A}](entity-a.md) — *publishes-to* / *reads-from* / *authenticates-against* — {detail}
- {External SaaS X} — {verb} — {what we consume}

## Downstream consumers

- [{Entity B}](entity-b.md) — *consumes* / *triggers* — {what they consume from us}

## Boundaries

- Authn/authz transitions: {description}
- Data classification: {PII / PCI / public / internal}
- Region / VPC: {detail}

## Invariants

Things that must always be true, or must never happen. Be specific.

- {e.g. "Source must be set or no build queues." "Visibility defaults to public on private repos."}

## Gotchas

- {Surprising thing operators should know}

## Related

- [Glossary: {term}](../glossary.md#term)
- [Pathway: {slug}](../pathways/{slug}.md)
```

`topology.md` lives at the repo root and is the bird's-eye view: a catalog of entities with one-line summaries, plus a mermaid diagram showing the most important interactions (verbs, not just dependencies). Keep the diagram tractable — if it grows past ~25 nodes, split into per-domain subdiagrams. Format:

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

- [Soteria](services/soteria.md) — {one-line summary} — `running`
- [OP2 Workspace](services/op2.md) — {one-line summary} — `running`
- [Flipt](services/flipt.md) — {one-line summary} — `running`
```

When the session establishes a new interaction between two entities, update *both* entity pages (upstream/downstream and capabilities sections), **the labeled edge in the diagram**, and any pathway under `pathways/` that this changes.

### `world-model.md` (cross-cutting world-model index)

`world-model.md` lives at the repo root and is the explicit, agent-readable index of the world the wiki describes. It does *not* duplicate entity pages — it indexes them through a planning lens. This is what an agent reads first when asked to plan a task.

If `world-model.md` does not yet exist, create it. Format:

```markdown
# World model

_Last updated: 2026-05-02_

The model an agent uses to plan in this environment. Entities live in `services/`; their states, capabilities, interactions, and the pathways between states are indexed here.

## Actors

Different actors have different affordances; what one can do another may not.

- **Human (engineer)** — normal org credentials; can edit repos, open PRs, view dashboards.
- **Human (admin)** — `repo admin` role; can change repo settings (Pages, Actions, branch protection).
- **Agent** — LLM agent acting on a user's behalf with their gh/cloud creds; capabilities equal whatever the user has.
- **CI** — Buildkite agents and GitHub Actions runners; identity is per-pipeline service account.
- **Service account** — non-human credentials for service-to-service calls.

## Capability index

Catalog of verbs across entities. Each links to the entity page that defines it.

- *enable-pages* — [GitHub Pages on dpkb](services/github-pages.md#capabilities)
- *trigger-build* — [GitHub Pages on dpkb](services/github-pages.md#capabilities)
- *retry-job* — [Buildkite](services/buildkite.md#capabilities)
- *re-run-workflow* — [GitHub Actions](services/github-actions.md#capabilities)

## Pathways

State-to-state recipes. Each is a separate page under `pathways/`.

- [serve-private-repo-as-pages-site](pathways/serve-private-repo-as-pages-site.md) — repo with no Pages → live private Pages site
- [migrate-wiki-to-repo](pathways/migrate-wiki-to-repo.md) — GitHub Wiki → markdown in main repo

## Cross-cutting invariants

Invariants that span multiple entities.

- **Default branch is the deployment branch.** Merging to default rebuilds Pages within ~1 minute.
- **CI is intentionally absent on dpkb.** No required checks, so PRs can squash-merge immediately.
- **Pages site visibility is not the repo's visibility.** A private repo's Pages site is public unless explicitly toggled.

## Open questions

Things the agent should remember are unresolved. Move into the relevant entity page once answered.

- {e.g. "Are GHEC private Pages settings respected when an org policy is more restrictive?"}
```

Update `world-model.md` whenever the session adds a capability, a pathway, an actor distinction, or a cross-cutting invariant. If the session only added a fact to a single entity page, you do *not* need to touch `world-model.md`.

### `pathways/{slug}.md` (state-to-state recipes)

A pathway is the **planning artifact**. It describes a sequence of capabilities that transforms the world from one state to another, with explicit pre-conditions, post-conditions, and the actors who can drive each step.

Create a pathway whenever the session walks through a non-trivial multi-step procedure that an agent or human might want to repeat or replay. (Do *not* create one for a single-capability action — that lives directly on the entity page.)

Format:

```markdown
# Pathway: {Goal}

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
| 1 | [enable-pages](../services/github-pages.md#capabilities) | human (repo admin) | repo exists, default branch has README | Pages source set | Settings → Pages |
| 2 | [enable-actions](../services/github-actions.md#capabilities) | human (repo admin) | — | Actions allowed for repo | Required: legacy Pages builds run on Actions infra |
| 3 | [trigger-build](../services/github-pages.md#capabilities) | human or agent | steps 1+2 complete | first build queued | `gh api -X POST .../pages/builds` |
| 4 | (wait) | system | step 3 complete | site live at discovered URL | `gh api .../pages` returns `status: built` |

## Failure modes

- **Step 3 silently no-ops** if Actions is disabled at the org level — surface to user, escalate to GitHub admin.
- **Site 404s after step 4** if visibility is set to private and viewer is not logged into the org.

## Invariants

- Default branch must contain at least one renderable markdown file (`README.md` or `index.md`).
- Site URL is determined by Pages, not chosen — read it from `gh api repos/{owner}/{repo}/pages --jq .html_url`.

## Related

- [Topology](../topology.md)
- [World model](../world-model.md)
- [services/github-pages.md](../services/github-pages.md)
```

Pathways are append-friendly — when a new way to reach the same goal is discovered, add an *Alternative* section rather than rewriting from scratch, so the planning history is preserved.

### `index.md` (catalog)

If `index.md` does not yet exist, create it. It is content-oriented — a catalog of every page in the wiki, grouped by category, with a one-line summary per entry. Update it whenever you add or significantly revise a page. The index should always include `glossary.md` and `topology.md` as their own top-level sections so they're discoverable. Suggested format:

```markdown
# Index

_Last updated: 2026-05-02_

## Reference

- [Glossary](glossary.md) — Rokt-specific vocabulary, acronyms, and jargon
- [World model](world-model.md) — actors, capabilities, pathways, and cross-cutting invariants for agent planning
- [Topology](topology.md) — entities and how they interact

## Pathways

State-to-state recipes for reaching specific goals.

- [serve-private-repo-as-pages-site](pathways/serve-private-repo-as-pages-site.md) — turn a private repo into a live Pages site

## Services

- [Soteria](services/soteria.md) — {summary} — `running`
- [OP2 Workspace](services/op2.md) — {summary} — `running`

## Tooling

- [GitHub](tooling/github.md) — Rokt-specific GitHub usage notes
- [Enable GitHub Pages](tooling/how-to/enable-github-pages.md) — how to turn on Pages for a private Rokt repo, including the Actions gotcha

## Cheatsheets

- [Kubectl](kubectl-cheatsheet.md) — common kubectl invocations
- [Argo Rollouts](release/argo-rollouts.md) — common `kubectl argo rollouts` invocations

## Reading

- [LLM Wiki](llm-wiki.md) — Karpathy's pattern that this repo is organized around
```

Update the `Last updated` of `index.md` whenever you change it.

### `log.md` (chronological)

If `log.md` does not yet exist, create it. It is an append-only chronological record. Each entry has the form:

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

1. **Last-updated freshness.** List pages whose `Last updated:` date is more than 180 days old (`find . -name '*.md' -not -path './.git/*'` then check each). Flag them in the PR description as "potentially stale" — do not silently update their date stamps. The user can review and either confirm-still-current (touch the date) or schedule a re-ingest.
2. **Missing `Last updated:` line.** Any page that doesn't have one. If you authored or edited the page in this run, add it. If it's an existing page, list the offenders in the PR description rather than blindly editing.
3. **Glossary coverage.** For each Rokt-specific term that appeared in the session, verify it has a glossary entry. Add missing entries.
4. **Entity ↔ topology consistency.** If `services/X.md` exists, it should appear in `topology.md`'s catalog. If `topology.md` mentions an entity, the corresponding `services/X.md` should exist (a stub page is fine if the session didn't establish enough to write a full one — mark it `> Stub` and link the glossary entry).
5. **Broken relative links.** Any link of the form `[...](some/path.md)` should resolve to a real file. Run a quick check (`grep -r '\](.*\.md)' --include='*.md'` and verify targets exist) and fix any breakage in pages you touched.
6. **Orphaned pages.** Pages that aren't reachable from `README.md` or `index.md`. List them in the PR description; don't auto-link them, since the right placement requires judgment.
7. **Contradictions.** If you flagged a contradiction earlier (Step 1d), make sure the inline `> Note: superseded ...` callout is present on the relevant page.
8. **Entity state hygiene.** Every entity page must have a `## State` section with a lifecycle value. Flag entity pages whose state is `unknown` for older than 90 days (`Last updated` minus today) — they are likely actually deprecated or running and the wiki has just not learned which.
9. **Capability ↔ world-model index consistency.** Every capability listed on an entity page must appear in `world-model.md`'s capability index. Every capability in the index must be defined on at least one entity page. Surface drift in the PR description.
10. **Pathway coverage.** Every pathway file under `pathways/` must be linked from `world-model.md` and from `index.md`. Each step in a pathway must reference a capability that actually exists on the named entity page (verify the anchor `#capabilities` resolves to a real section).
11. **Edge labels in topology diagram.** Every edge in `topology.md`'s mermaid diagram should be verb-labeled (`-->|verb|`), not bare `-->`. Bare edges are a code smell — they hide what kind of interaction is happening. Flag any unlabeled edges.

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
- **World-model deltas:** new entities, lifecycle state changes, new capabilities, new pathways, new actors, new invariants. This is the substantive output — it's what an agent in a future session can plan over.
- Any topology edge changes (added, relabeled, or removed verbs).
- **Lint findings** that need user attention (stale pages, missing date stamps, orphans, contradictions, capability drift, unlabeled topology edges). Don't bury these — they're the rot-prevention output and the user should see them every run.
- The Pages site URL so they can see the rebuilt site once it deploys (~1 minute): https://potential-adventure-qjoqm67.pages.github.io/

Keep it short. The wiki itself is the durable record now.

## Conventions and constraints

- **Always branch from `origin/master`**, never from whatever the user's local checkout has.
- **Branch name** must start with `dp/` (matches the `yeet` skill).
- **One PR per `/dpkb` invocation.** If the session covers multiple unrelated topics, you may still file them in one PR, but make the PR body and the `log.md` entry call out the distinct topics. Don't open multiple PRs from one invocation.
- **Never delete pages** without an explicit instruction from the user. Updating and superseding is fine; deletion is destructive.
- **Never put secrets, tokens, internal hostnames, or PII into the wiki**, even if they showed up in the session. The repo is private but the Pages site visibility is not guaranteed to be private — assume the rendered site could be reached by anyone in the org.
- **Respect existing voice.** Pages in this wiki are written in plain, terse American English. Avoid marketing language, hedging filler ("simply", "just", "easy"), and emoji.
- **Trust the taxonomy.** Reuse `build/`, `compute/`, `languages/`, `network/`, `release/`, `storage/`, `tooling/` when they fit. Create new top-level folders sparingly and only when no existing one fits.
- **World-model first.** Before writing prose, ask: "what does an agent reading this learn about *what exists, what's possible, and how to get from state X to state Y*?" Prefer encodings (capabilities tables, pathway tables, verb-labeled edges, lifecycle state) over narrative descriptions when both could capture the same fact. Prose is fine, but it should sit alongside structured world-model artifacts, not replace them.

## Failure modes

- **Worktree creation fails** because the branch already exists locally — delete the stale branch with `git -C "$DPKB" branch -D dp/$SLUG` and retry.
- **Push fails** because the branch already exists on origin — append a counter (`dp/$SLUG-2`) and retry.
- **PR merge fails** because of branch protection — surface the failure to the user with the PR URL and stop. Do not force-merge.
- **Nothing durable in the session** — explicitly tell the user "no durable content found, skipping" and exit without creating a branch, PR, or worktree.
