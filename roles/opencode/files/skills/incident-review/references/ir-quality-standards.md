# Incident Review Quality Standards

Original guidance on writing high-quality incident reviews at Rokt.

## 1. Root Causes vs. Triggers

We are frequently conflating triggers with root causes.

Root causes are the inherent weaknesses in your system. Triggers are edge cases, human errors, or environmental conditions that activate a weakness, causing a failure condition.

"An engineer ran the wrong script" or "unexpected traffic increase" or "partner error" is not a root cause. Root causes should describe limitations in systems or processes. They typically address one of:

- Architecture
- Testing strategy
- Deployment process
- Monitoring coverage
- Operational controls
- Risk modeling
- Ownership boundaries

If your IR ends with "human error" or "client error" as the root cause, you have almost certainly stopped thinking too early.

## 2. Remediations Require Owners and Completion Dates

Many IRs include "recommended actions" with no DRI or no committed delivery date. That is not acceptable. If a remediation has no DRI and no date, it is not a remediation. It is a suggestion. This violates our value of "act like an owner." System owners are responsible for managing risk in their domains. An incident is a risk signal. System owners must:

- Decide what risk remains
- Decide what level of risk is acceptable
- Explicitly commit to remediation or document why not

Every action item must include:

- DRI
- Committed date
- Clear success criteria

## 3. Write for the Entire Company

IRs are formal engineering documents. They are not gChat threads. Common problems:

- Conversational tone
- Unexplained acronyms
- Team-specific shorthand
- Implicit assumptions

An IR should be consumable by:

- Engineers outside your team
- Executive leadership
- Legal
- Customer Success

Write as if the reader has context on engineering principles, but not your system. If another team cannot learn from your IR, you have reduced the opportunities for cross-team learning.

## 4. Fix the Class of Problems, Not the Instance

Many remediation steps address the narrow incident case rather than the broader class of issues.

Example:

- Narrow: "Add validation to this endpoint."
- Higher leverage: "Introduce schema validation at the service boundary for all external inputs."

Incidents are signals of structural weakness. Ask:

- What category of risk does this represent?
- Where else / how else could this manifest?
- How do we eliminate this entire class of failure conditions?

## 5. Precision in Language

Imprecise language weakens technical documents. Writers should replace words like "substantial", "many", "frequent", "several" with precise numbers. Writers should replace words like "probably", "possibly", "potentially" with either a probability distribution, quantitative evidence, or an uncertainty range. Units of measurement and timezones should remain consistent throughout your document. Engineering writing should reduce ambiguity, not introduce it.

## 6. Chronologies Must Be Curated, Not Dumped

Exporting a timeline from Datadog or incident tooling is often not sufficient. A raw event dump is not a narrative. Your responsibility is to:

- Curate the timeline
- Summarize key inflection points
- Explain why decisions were made
- Add context from other systems (logs, PRs, alerts, customer reports)

The goal is not to preserve every event. The goal is to maximize organizational learning. Resolution and clarity matter more than exhaustiveness.

## 7. Visuals Require Interpretation

Charts, dashboards, and screenshots without explanation are not useful. Every visual must include:

- What the reader is looking at
- Why it matters
- What changed
- What signal it provided (or failed to provide)

Assume the reader has never seen that dashboard before.

## 8. Business Impact Is Not Optional

Too many IRs understate or omit impact. Impact must be translated into business terms:

- Customer count affected
- Revenue exposure
- SLA breach duration
- Data integrity risk
- Reputational risk
- Operational cost (e.g., engineering hours)

"Service degraded" is not an impact statement. If we do not articulate business impact, we cannot properly prioritize risk.

## 9. Additional Patterns to Avoid

A few other recurring anti-patterns:

- Overly linear narratives that imply inevitability rather than intentional decision points.
- Lack of counterfactual thinking (What would have prevented each of these cascading failure conditions?).
- No discussion of detection latency (How long were we blind? Why didn't the smoke alarm go off?)
- No assessment of residual risk after remediation.
- No consideration of options to accelerate recovery time.

High-quality IRs examine:

- Prevention
- Detection
- Mitigation
- Recovery
- Communication

If we treat IRs as compliance artifacts, we will stagnate. If we treat them as learning opportunities, our learning rate compounds. There has never been a broader range of high-quality example IRs to learn from (Google, AWS, GitHub -- note the correct use of the terms "root cause" and "trigger" in this summary). There has also never been an easier time to write high-quality IRs -- every engineer has an AI cowriter, doc reviewer, and critic available to them 24/7.
