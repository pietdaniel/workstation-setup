---
name: incident-review
description: "Write or review incident reviews (IRs) against Rokt engineering standards. Use when drafting a new IR, reviewing an existing one, or improving IR quality. Covers root cause analysis, remediation ownership, business impact, chronology, and writing standards."
---

# Incident Review

Write or review incident reviews that maximize organizational learning.

## Setup

On invocation, read the reference documents in this skill's `references/` directory to load Rokt-specific context. Resolve them relative to this `SKILL.md` file:

1. `references/ir-quality-standards.md` -- the 9 quality standards that every IR must satisfy
2. `references/jumpkit.md` -- Rokt incident response procedures, severity definitions (SEV-1 through SEV-5), escalation contacts, IC responsibilities, and postmortem workflow
3. `references/official-dd-template.md` -- the official Datadog postmortem template that engineers start from

The skill directory is `~/.config/opencode/skills/incident-review/` — read these files with the Read tool using absolute paths if needed (e.g. `~/.config/opencode/skills/incident-review/references/ir-quality-standards.md`).

## Invocation

The user may provide:

- A draft IR document (file path, pasted text, or Confluence link)
- An incident description to draft an IR from scratch
- A request to review an existing IR

Determine the mode:

| Mode        | Trigger                                              |
| ----------- | ---------------------------------------------------- |
| **Review**  | User provides an existing IR to critique             |
| **Draft**   | User asks to write/start an IR                       |
| **Improve** | User asks to fix specific sections of an existing IR |

---

## Quality Standards

Apply every standard defined in `references/ir-quality-standards.md` (sections 1-9). When reviewing, cite specific violations by section name (e.g., "Root Causes vs. Triggers", not "sec 1"). When drafting, satisfy every standard proactively.

For each standard, follow these mode-specific behaviors:

### Review mode

- Flag root causes that describe triggers rather than structural weaknesses (Root Causes vs. Triggers)
- Flag action items missing DRI, date, or success criteria; flag items assigned to teams rather than individuals (Remediations Require Owners and Completion Dates)
- Flag conversational tone, unexplained acronyms, team-specific shorthand (Write for the Entire Company)
- Flag remediations that address only the instance, not the class (Fix the Class of Problems, Not the Instance). For each weak remediation, propose a concrete higher-leverage alternative that addresses the structural weakness — don't just flag the problem, show what a better action item looks like
- Flag vague quantifiers and hedging language; ask for specific numbers (Precision in Language)
- Flag timelines that read like raw exports; identify missing decision context and unexplained gaps (Chronologies Must Be Curated, Not Dumped)
- Flag visuals without interpretation (Visuals Require Interpretation)
- Flag missing or vague impact sections; ask for specific numbers (Business Impact Is Not Optional)
- Flag anti-patterns: linear inevitability narratives, missing counterfactuals, no detection latency discussion, no residual risk assessment, no recovery acceleration analysis (Additional Patterns to Avoid)

### Draft mode

- For each trigger, iterate "what structural weakness allowed this?" until reaching a system/process limitation (Root Causes vs. Triggers)
- Format every remediation as a checkbox with sub-bullets for metadata (Remediations Require Owners and Completion Dates):

  ```markdown
  - [ ] [Action]
    - DRI: [Name] ([team])
    - Due: [YYYY-MM-DD]
    - Done when: [criteria]
    - Ticket: [PIA-XXXX]
  ```

- Flag unowned items prominently (Remediations Require Owners and Completion Dates)
- Expand all acronyms on first use (Write for the Entire Company)
- For each remediation, ask: what class of risk? where else could it manifest? how to eliminate the class? (Fix the Class of Problems, Not the Instance)
- Use precise numbers, evidence, and UTC timestamps throughout (Precision in Language)
- Curate the timeline to key inflection points with decision context (Chronologies Must Be Curated, Not Dumped)
- Annotate every visual with what, why, what changed, and what signal it provided (Visuals Require Interpretation)
- Include an explicit impact section with every applicable dimension quantified (Business Impact Is Not Optional)
- Examine all five dimensions: prevention, detection, mitigation, recovery, communication (Additional Patterns to Avoid)

---

## Output Format

### Review Mode

Produce a structured review:

```markdown
# IR Review

## Overall Assessment

[1-2 sentence summary: does this IR meet the standard?]

## Critical Issues (must fix before publishing)

- [ ] [Standard violated (section name)] -- [specific quote or section] -- [what to fix]

## Important Issues (should fix)

- [ ] [Standard violated (section name)] -- [specific quote or section] -- [what to fix]

## Suggestions

- [Other improvements that would strengthen the IR]

When existing action items are weak, instance-level, or missing, propose concrete higher-leverage alternatives:

| Current Action Item          | Problem                 | Suggested Alternative              |
| ---------------------------- | ----------------------- | ---------------------------------- |
| [existing item or "Missing"] | [why it's insufficient] | [concrete class-level remediation] |

Additional remediations to consider:

- [remediation targeting architecture, operational controls, blast radius, or detection gaps]

When the IR is missing a Defense Layer Analysis, include a suggested table based on incident facts:

| Defense Layer           | Status                    | Details                              |
| ----------------------- | ------------------------- | ------------------------------------ |
| **Design/Architecture** | [Held / Failed / Missing] | [assessment based on incident facts] |
| **Input Validation**    | [Held / Failed / Missing] | [assessment]                         |
| **Testing**             | [Held / Failed / Missing] | [assessment]                         |
| **Deployment Controls** | [Held / Failed / Missing] | [assessment]                         |
| **Monitoring/Alerting** | [Held / Failed / Missing] | [assessment]                         |
| **Runbooks/Playbooks**  | [Held / Failed / Missing] | [assessment]                         |
| **Human Review**        | [Held / Failed / Missing] | [assessment]                         |

## Strengths

- [What the IR does well]
```

### Draft Mode

Produce the IR using this structure. This aligns with the official Datadog postmortem template while incorporating the quality standards.

```markdown
# Incident Review: [Title]

## Incident Properties

| Property               | Value                                                   |
| ---------------------- | ------------------------------------------------------- |
| **Status**             | [Resolved / Monitoring]                                 |
| **Severity**           | [SEV-1/2/3/4/5]                                         |
| **Started**            | [YYYY-MM-DD HH:MM UTC]                                  |
| **Duration**           | [total duration]                                        |
| **Detection Method**   | [method] ([N] minutes from incident start to detection) |
| **Incident Commander** | [name]                                                  |
| **Author**             | [name]                                                  |
| **Incident Overview**  | [link to Datadog incident]                              |

## Summary of Incident & Response

Structure as four paragraphs:

1. Start and end time of the incident. Summary of customer/client impact and their experience. Primary symptom (e.g., out-of-memory, file missing, corrupt data).
2. When and how the incident was detected. When clients were notified (if applicable). How the incident was mitigated and/or resolved.
3. The trigger that started the incident (e.g., button click, script ran, deployment). The root cause identified via 5-Whys -- the structural weakness, not the trigger.
4. Action items to address root cause(s) and the broader class of failure.

Write so that a non-engineer at Rokt can understand. Use the 4 C's: Clear, Concise, Complete, Correct. The reader should finish with confidence that neither this incident nor similar issues will recur.

## Impact on Customers

[Detailed customer/client impact description]

### Total Cost to Rokt

Work with stakeholders to calculate:

- Revenue lost: [amount]
- "Make it right" adjustments: [amount]
- Customers affected: [number]
- SLA breach: [duration, which SLAs]
- Data integrity risk: [assessment]
- Engineering cost: [hours spent on incident + remediation]

## Why Did It Happen?

### Trigger

[The specific event or condition that activated the underlying weakness -- e.g., deployment, script execution, traffic spike, partner error. This is NOT the root cause.]

### Root Cause

[The structural weakness in the system or process. Must address architecture, testing, deployment, monitoring, operational controls, risk modeling, or ownership boundaries. If it says "human error" or "client error", dig deeper.]

### 5 Whys Analysis

Use the [5 Whys](https://en.wikipedia.org/wiki/Five_whys) method to drill from the trigger to the structural root cause. If you have fewer than 5, you probably haven't gone deep enough.

**Why 1:** [Surface-level cause]

**Why 2:** [Why did that happen?]

**Why 3:** [Why did that happen?]

**Why 4:** [Why did that happen?]

**Why 5:** [Structural weakness -- this should match the Root Cause above]

### Contributing Factors

- [Other conditions that worsened the impact or delayed recovery]

## Timeline (UTC)

| Time  | Event           | Context                                     |
| ----- | --------------- | ------------------------------------------- |
| HH:MM | [curated event] | [why this matters / what decision was made] |

Review carefully for clarity. Remove all timeline entries that are non-critical. Explain why decisions were made at each inflection point.

## How Do We Prevent It in the Future?

### Five Dimensions Analysis

#### Prevention

[How do we eliminate this class of failure? Not just this instance -- where else could it manifest?]

#### Detection

[How do we catch this faster? What was the detection latency? Why didn't existing monitoring catch it?]

#### Mitigation

[How do we limit blast radius when this class of failure occurs?]

#### Recovery

[How do we restore service faster? Could recovery have been accelerated?]

#### Communication

[How do we keep stakeholders informed? What worked and what didn't during the response?]

### Action Items

Actions should BOTH eliminate the chance of the same incident recurring AND mitigate similar incidents (e.g., audit platform for similar code/configurations).

- [ ] [Action]
  - DRI: [Name] ([team])
  - Due: [YYYY-MM-DD]
  - Done when: [criteria]
  - Ticket: [PIA-XXXX]
- [ ] [Action]
  - DRI: [Name] ([team])
  - Due: [YYYY-MM-DD]
  - Done when: [criteria]
  - Ticket: [PIA-XXXX]

### Counterfactual Analysis

[What would have prevented each stage of the cascading failure? Work backwards from impact to trigger.]

### Residual Risk

[What risk remains after planned remediations? Is this acceptable? Why or why not?]

## How Can We Improve Our Incident Response Process?

[Meta-retrospective: what went well and what went poorly in the response itself? Communication gaps? Tooling issues? Escalation delays?]

## Defense Layer Analysis (Swiss Cheese Model)

Incidents are not caused by a single failure. They occur when weaknesses in multiple defensive layers align simultaneously. For each layer below, identify whether it held, had holes, or was missing entirely.

| Defense Layer           | Status (Held / Failed / Missing) | Details                                                              |
| ----------------------- | -------------------------------- | -------------------------------------------------------------------- |
| **Design/Architecture** | [status]                         | [Did the system design prevent this class of failure?]               |
| **Input Validation**    | [status]                         | [Were bad inputs caught at the boundary?]                            |
| **Testing**             | [status]                         | [Did tests cover this scenario?]                                     |
| **Deployment Controls** | [status]                         | [Did rollout safeguards (canary, feature flags, rollback) catch it?] |
| **Monitoring/Alerting** | [status]                         | [Did alerts fire? How fast?]                                         |
| **Runbooks/Playbooks**  | [status]                         | [Did operational procedures guide the response?]                     |
| **Human Review**        | [status]                         | [Was there a review step that could have caught this?]               |

For each layer that failed or was missing: what remediation closes that hole? Where else in the system is the same layer weak?
```

### Improve Mode

When the user asks to fix specific sections of an existing IR:

1. Read the existing IR document
2. Identify which sections need improvement by checking against the quality standards
3. Rewrite only the affected sections, preserving the rest of the document unchanged
4. For each rewritten section, briefly explain what was wrong and what standard it violated

Output the rewritten sections inline, clearly marked:

```markdown
# IR Improvements

## Changes Made

### [Section name] (was: [brief description of problem])

**Standard violated:** [standard name]

[Rewritten section content]

---

## Remaining Issues

- [ ] [Any issues that require input from the user to resolve, e.g., missing data]
```

---

## PIA Jira Integration

Every incident SEV-1 through SEV-4 must have a corresponding PIA Jira ticket. SEV-5 incidents do not require a PIA ticket unless the user explicitly requests one.

### Constants

All Jira calls use **cloudId:** `rokt.atlassian.net` and **projectKey:** `PIA`.

### Severity Mapping

Map the incident SEV level directly to the PIA "Incident Severity" field. PIA does not support SEV-5; map SEV-5 to SEV-4.

### Prerequisites

Before starting the workflow, determine the **IR number** and the **Datadog incident link**:

1. The IR number comes from the **Datadog incident ID** (e.g., Datadog incident `142` → `IR-142`)
2. Get the Datadog incident link from the IR's "Incident Overview" property, or search using `search_datadog_incidents` with the incident title or date range
3. If the Datadog incident cannot be found, **ask the user** -- never use a placeholder IR number

### Workflow

#### 1. Check for existing PIA ticket

Search for an existing ticket using `searchJiraIssuesUsingJql`:

```jql
project = PIA AND issuetype = Incident AND summary ~ "IR-XXX"
```

If the search returns multiple results, list them for the user and ask which one to use. If a matching ticket exists, use it -- do not create duplicates.

#### 2. Create the PIA incident ticket

If no ticket exists, create one using `createJiraIssue`:

- **issueTypeName:** `Incident`
- **summary:** `IR-XXX: <incident title>` (e.g., `IR-142: Payment processing timeout in AU region`)
- **contentFormat:** `markdown`
- **description:** Must include the **Datadog Incident link** (primary source of truth), link to the IR document, and a brief summary of customer/business impact
- **assignee_account_id:** Look up the **Incident Commander** using `lookupJiraAccountId`. If the lookup fails, create the ticket unassigned and warn the user.
- **additional_fields:** Set "Incident Severity" to the mapped value (e.g., `SEV-2`). If the field is not recognized or the call fails, report the error to the user -- the field name or format may need to be verified in PIA project settings via `getJiraIssueTypeMetaWithFields`
- **transition:** After creation, transition the ticket to **In Progress** using `getTransitionsForJiraIssue` to find the correct transition ID, then `editJiraIssue` to apply it

Report the created ticket key (e.g., `PIA-1234`) back to the user. If ticket creation fails, report the full error and suggest checking project permissions and issue type configuration.

#### 3. Create subtasks for each action item

If the PIA ticket already has subtasks (from a prior run), fetch them first and only create subtasks for action items that do not already have a corresponding subtask.

For every action item in the IR's remediation list, create a subtask using `createJiraIssue`:

- **issueTypeName:** `Sub-task`
- **parent:** The PIA incident ticket key from step 2
- **summary:** The action item description
- **contentFormat:** `markdown`
- **description:** Include DRI, due date, and done-when criteria from the IR
- **assignee_account_id:** Look up the DRI using `lookupJiraAccountId`. If the lookup fails or returns multiple results, create the subtask without an assignee and warn the user: "Could not resolve Jira account for [DRI name] -- manual assignment required."

After attempting all subtasks, present a summary showing each action item, whether its subtask was created, and the ticket key. If any failed, offer to retry.

#### 4. Update the IR

Update each action item's `Ticket` field with the PIA subtask link: `[PIA-XXXX](https://rokt.atlassian.net/browse/PIA-XXXX)`. If the IR is a Confluence page, use `updateConfluencePage`. If it is a local file, use the Edit tool. If the IR was provided as pasted text, output the updated action items for the user to copy.

> **Manual step:** Prompt the user to link `PIA-XXXX` in the Datadog incident's Jira link field. This cannot be done programmatically.

### When to prompt for PIA tickets

- **Draft mode:** After generating the IR, offer to create the PIA incident ticket and subtasks.
- **Review mode:** First check the IR document for existing PIA ticket references (links matching `rokt.atlassian.net/browse/PIA-`). If none found, search Jira. If no ticket exists, flag it as a critical issue: "No PIA ticket found for this incident."
- **Improve mode:** If action items are added or changed, offer to create/update the corresponding subtasks.

---

## Gathering Context

Use available MCP tools (Datadog, Confluence, GitHub, Kubernetes, Atlassian) to gather incident context if available. Ask the user for anything you cannot find. Do not fabricate details.
