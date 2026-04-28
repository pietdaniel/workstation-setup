# Official Datadog Postmortem Template

This is the template used when generating postmortems from Datadog Incidents. The `{{incident.*}}` variables are pre-filled by Datadog.

---

INCIDENT PROPERTIES ||
-|-
**Status** | {{incident.state}}
**Severity** | {{incident.severity}}
**Started** | {{incident.created}}
**Detection Method** | <method> (minutes_from_incident_start_to_incident_detection)
**Commanders** | {{incident.commander}}
**Incident Overview** | [IR-{{incident.id}}](/incidents/{{incident.id}})

_You can generate a postmortem [from any resolved incident](https://rokt.datadoghq.com/incidents?query=state%3Aresolved) with these fields pre-filled, along with incident metadata and timeline._

# Summary of Incident & Response

_Suggested structure of summary_
* _Paragraph 1: start & endtime of incident, summary of customer/client impact & customer/client experience, primary symptom (e.g. out-of-memory, file missing, corrupt data)_
* _Paragraph 2: when & how incident was detected, when clients were notified (if applicable),how incident was mitigated and/or resolved_
* _Paragraph 3: Trigger that started in incident (e.g. button click, script ran, deployment), Root cause(s) identified via 5-Whys_
* _Paragraph 4: action items to address root case(s)_

_Hints_
* _Assume your reader works at Rokt but is not an engineer. Make sure they can understand_
* _Use 4 C's of Crisp writing: Clear, Concise, Complete, and Correct_
* _Reading summary gives reader confidence neither the incident nor similar issues will happen again_
* _complete below sections, refine after feedback then write the the summary last_

## Impact on Customers

{{incident.customer_impact}}

### Total Cost to Rokt

*Work with stakeholders to calculate revenue lost and "make it right" adjustments*

# Why Did it Happen?

### Root Cause

### What Happened?
{{incident.root_cause}}
_Review and expand this section ensure clarity_

### 5 Whys analysis

_Use the [5-Why's Analysis](https://en.wikipedia.org/wiki/Five_whys) method
to drill down on the root cause and gain clearer insight into the necessary action
items. If you don't have 5 why's, you probably haven't gone deep enough._

***Why 1:***

***Why 2:***

***Why 3:***

***Why 4:***

***Why 5:***

# Timeline

{{incident.timeline_important_only}}

_review carefully for clarity; remove all timeline entries that are non-critical_

# How do we prevent it in the future?

### Action Items

{{incident.tasks}}

_actions should BOTH eliminate chance of same incident from happening AND mitigate similar incidents from happening (e.g. audit platform for similar code/configurations)_

# How can we improve our incident response process?

---

### Copy Contents into a Google Doc and Upload to Google Drive

Once an Incident Review has been completed, within the settings sub-menu (gear in
top right corner of screen), select an option to copy contents and paste into a doc
into Google Drive [here](https://drive.google.com/drive/folders/11tyvimgmlJSEXBFkdYgXs3ThC0H55BU4)
(ROKT BUSINESS/RPD/Incident Post Mortems). Naming convention should be YEAR-MONTH-DAY-Incident-Name.

### Incorporation of Failure Mode and Effects Analysis (FMEA)

How likely is a future incident in this area likely to be given:

  - The **Severity (SEV)** of another failure
  - The probability of another **Occurrence**
  - How difficult the failure is to **Detect**

What steps can be taken to reduce and/or eliminate risk across these three dimensions
going forward? What other services can have their risk posture improved across these
dimensions?

For more information and examples, please view this [lightning rod](https://docs.google.com/document/d/19B3m-NlHhsdLZfCOO2EV3qmopFkcQTw5mVVu68-A8Z4/edit#heading=h.hdt292sshfti).
