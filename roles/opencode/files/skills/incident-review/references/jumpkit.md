# **_Incident Response_** Jumpkit for RPD Teams

## [go/jumpkit](http://go/jumpkit) v.5.3.3

# Introduction

When something goes wrong, whether it’s an outage or a broken feature, teams need to respond quickly to restore service for our customers. This process is called **incident response**. This document outlines how Rokt approaches incident response leveraging Datadog Incidents and Slack.

# Expectations

Engineering teams are responsible for the health of their services. As such, Rokt expects engineers to be part of their team's on-call rotation \- Rokt’s culture of “_you build it, you run it, you own it_'' means that we expect all engineers to be on call for their systems. This breeds operational excellence among the teams and shares the responsibility throughout engineering to better our overall customer experience.

Individual expectations when on call are:

- Carry a laptop
- Have a phone accessible and within reception
- Be able to respond to page and begin analysis within 15 min of alert

Team expectations are:

- Rotation of team members
- Escalation to fall back to Team then Manager

# Responsibilities

## Incident Commander

The Incident Commander is either a first responder or a nominated individual who identifies or picks up the issue within Engineering. They own the incident identification, communication, escalation, and coordination. The commander retains this responsibility until remediation or until an official handover to another commander. The commander does not have to write the post mortem but they are responsible for the quality and completeness of following the incident process. This includes the post mortem document, datadog incident telemetry, and incident review.

# How to Respond

Once a responder has acknowledged an alert, they must investigate if an alert is categorized as an incident. Here is a quick guide to assessing if an alert is categorized as an incident:

- Revenue impact
- Customer/Client impact
- Monitoring failure (‘we are blind’)
- Security compromise (e.g., data loss of any kind) or compliance failure

Once an incident is identified, follow these steps:

1. Use the [severity definitions](#severity-definitions) to make an initial guess at the severity.

2. Declare a new incident. This can be done in one of three ways:
   1. Using the [Datadog UI](#through-datadog-incidents) (http://go/dd-incidents)
   2. [Using the UI](#through-ui) available at [http://go/new-incident](http://go/new-incident) (Requires SDP Enabled)
   3. [Using Slack](#through-slack)

After declaring, the initial responder should fill out the [relevant incident fields](#heading=h.omlagrgnjt7a) (“incident commander”, “effects”, “cause”, “mitigations”, and “next update”) to the best of their abilities.

3. [Details](#changing-an-incident’s-severity) about the incident can be changed throughout the lifetime of the incident through either the Datadog UI or the Datadog Slack integration. Ensure that the “services”, “teams”, and “customer impact” fields are filled out and updated throughout the incident by the IC as it improves reporting.
4. No manual incident updates go into Google Chat. Rokt’s [Incidents](http://go/gh/incidents) service handles mirroring between Datadog Incidents and the appropriate Google Chat channels with our Rokt-standard format. Example Google Chat Message:

After the appropriate people respond, the incident should be contained. Responders should establish the cause of the incident and actions to be taken that stop the incident from getting worse.

When the impact of the incident is contained, responders should work to resolve the incident as appropriate so that the service is recovered and operating normally. As long as steps taken and/or updates are made within Datadog Incidents itself, timeline actions will be summarized upon [Post Mortem generation](#creating-an-incident-postmortem).

## Declaring an Incident

Anyone is empowered to declare an incident. Declare an incident through one of the [3 means described in the appendix](#declaring-an-incident).

It is better to err on the side of caution here. There is little disruption and mostly utility in declaring a SEV-5 incident and escalating. On-call engineers should **default to SEV-5 over no incident** when system impact is suspected and elevate the level as impact is assessed.

## Declaring a Retroactive Incident

There are many reasons to declare an incident after it has already been resolved, including to bring organizational awareness or to go through the postmortem process to document exact steps taken for future improvements.

To declare a retroactive incident, first follow the [standard steps](#declaring-an-incident) to declare the incident. In the title, clearly state it it is a not an ongoing incident (eg. `[RETRO-ACTIVE] Rest of Title`), but set the severity to the actual severity of the incident. Immediately after creating the incident, set the “Next Update” field to be “retroactive” and then [resolve](#resolving-the-incident) the incident. Update the [Google Chat Thread Fields](#heading=h.omlagrgnjt7a) as well as the “services”, “teams”, and “customer impact” fields and then follow the [Incident Review](#incident-review) steps to create a postmortem notebook and book the Incident Review meeting.

When filling out the postmortem, details around main timeline events will need to be input manually.

## Changing an Incident’s Severity {#changing-an-incident’s-severity}

As an incident is investigated and mitigated, the severity of the incident may change. Incident responders are empowered to escalate or deescalate the incident severity. To change the incident's severity use one of the [2 means described in the appendix](#changing-an-incident’s-severity-1).

## Change Impacted Teams / Services

As the scope of an incident is fully identified, teams and services may be identified with the incident. It is possible to associate particular teams and services with the incident using one of the [2 methods outlined in the appendix](#change-impacted-teams-/-services).

## Changing the Incident Commander

As an incident unfolds, it is possible that the incident commander will need to be set or changed. This can be done using one of the [2 methods outlined in the appendix](#changing-the-incident-commander).

## Resolving the Incident

Incidents can be resolved using either the Datadog Incident user interface or the Datadog Slack application. Details can be [found in the appendix](#resolving-the-incident).

Make sure to follow the steps to generate a postmortem in the next section. This should ideally be done as soon as the incident is resolved.

## Paging

Once an incident has been assessed, your first responders might be all the people required to resolve the incident. However, in some scenarios, the Incident Commander may need to escalate to other teams by paging them if their own alerts haven’t kicked in. Paging of teams can be done through the dispatcher bot in Google Chat. Details on how to do so can be [found in the appendix](#paging).

## Considerations for SEV-1

Due to the scope and impact of SEV-1 incidents, a special set of requirements must be upheld. They are as follows

- A technical ExCo member paged. Currently [Claire Southey](mailto:claire.southey@rokt.com) or [Andrew Katz](mailto:akatz@mparticle.com)
- ExCo is updated every 15 minutes on the impact, mitigation, and status of the incident
- A root cause analysis ready for stakeholder consumption within 4 hours after resolution
- A comprehensive IR with full remediation implementation plan, timeline, and DRI's assigned, within 7 days.

## Seems like a malicious attack?

If you suspect we're under a malicious attack, refer to the [Network Integrity handbook](http://go/nihb). If the incident isn't listed here, page the Security team immediately.

# Incident Review {#incident-review}

Incidents happen. At Rokt, we understand we’re building complex systems, and 100% availability is unlikely. We strive for a blameless culture where we learn together from these events so that we can improve our services and drive towards lowering our Mean Time To Recovery (MTTR).

After an incident has been resolved, responders are responsible for:

- Building a complete timeline of actions taken. As long as the incident has been accurately kept up to date in Datadog Incidents, this step is largely automated upon post-mortem creation
- Determining the root cause of the incident
- Listing what actions will be taken to stop this incident (and similar incidents) from recurring again
  - Assigning owners and due dates to each of the actions

## Creating an Incident Postmortem {#creating-an-incident-postmortem}

Results will be summarized within an [Incident Postmortem](https://rokt.datadoghq.com/incidents?query=-postmortem%3Afalse) in Datadog Incidents then copied to [Incident Post Mortems](https://drive.google.com/drive/folders/11tyvimgmlJSEXBFkdYgXs3ThC0H55BU4) in Google. The Incident Commander is responsible for ensuring that the postmortem and the “Incident Review Checklist for Incident Commander” is complete; this may involve them liaising with other teams.

Creating an Incident Postmortem in Datadog Incidents is straightforward. After an Incident has been marked as “Resolved”, simply:

1. Create placeholder document the appropriate quarter's folder within the drive folder [Incident Post Mortems](https://drive.google.com/drive/folders/11tyvimgmlJSEXBFkdYgXs3ThC0H55BU4) | [http://go/incident-post-mortems](http://go/incident-post-mortems). Naming convention should be  
   **`YEAR-MONTH-DAY - IR-XXX - SEV-X - Incident-Name`**
2. Post a link to the post mortem in the G-Chat thread
3. Click the “Generate Postmortem” field within the heading of the incident. Be sure to [flag timeline items](#incident-timeline-flagging) as important prior.

4. Click the “Generate” button with the “Rokt Post Mortem Template” template selected.

5. Ensure “Enable Markdown” is selected in Google Docs \> Tools \> Preferences

6. In Datadog, Click “Download as Markdown”

7. Copy the Markdown to your Clipboard

   `cat ~/Downloads/$FILE.md | pbcopy`

8. In Google Docs, Right Click \> Paste from Markdown

9. Continue to fill in additional relevant details in the generated Datadog post-mortem notebook as needed for completeness. Because we only have 7 days of log retention, if any queries or graphs of log data are relevant for the incident, please capture them in the IR with a screen shot instead of an in-line notebook query. This preserves the insights for future readers and auditors.
10. The timeline may contain irrelevant information; **remove any superfluous information**.
11. After the post-mortem is completed, link the google document in the "Why it happened" section of the post-mortem.

## Incident Review Meeting {#incident-review-meeting}

The IR report should be presented within **the time defined in the table below** by the Incident Commander. It is the responsibility of the Incident Commander to schedule the IR review meeting and invite their team, anyone involved, the group [incidentreview@rokt.com](mailto:incidentreview@rokt.com), and also invite the “Incident Review” Google calendar to keep this meeting visible for everyone.

After the completion of the IR Review, it is the responsibility of the Incident Command to ensure all identified follow up work is completed.

**_If you would like to see upcoming Incident Reviews you can subscribe to the “[Incident Review](https://calendar.google.com/calendar/u/0?cid=Y180NmxyczNxcG1kaTdvN2ZxMDFpbmlndjY2OEBncm91cC5jYWxlbmRhci5nb29nbGUuY29t)” Google calendar._**

For **SEV-1** Incidents one of the following individuals must attend:

- [Claire Southey](mailto:claire.southey@rokt.com)
- [Andrew Katz](mailto:akatz@mparticle.com)
- [Reuben Kan](mailto:reuben.kan@rokt.com)
- [Dan Piet](mailto:daniel.piet@rokt.com)
- [Sam Dozor](mailto:sdozor@mparticle.com)

# Severity

Rokt has five severity levels. To reduce noise, they correspond to the following high-level action plans.

**SEV 5 \-\>** First responder proactively communicates a potentially risky action about to be undertaken.

**SEV 4 \-\>** First responder coordinates the incident at the team level.

**SEV 3 \-\>** First responder coordinates incident at team level, escalating to other teams as needed.

**SEV 2 \-\>** Page incident response on-call for an incident commander to take over to coordinate.

**SEV 1 \-\>** Page "Incident Response Team" to inform of the incident to pull all hands on deck.

### Severity Definitions {#severity-definitions}

| Severity |                  Description                   |                                         Business Impact                                         |                                  Internal Response                                  |                                    External Impact                                     | Incident Review Time |
| :------: | :--------------------------------------------: | :---------------------------------------------------------------------------------------------: | :---------------------------------------------------------------------------------: | :------------------------------------------------------------------------------------: | :------------------: |
|  SEV-1   |    Critical incident with very high impact.    | Existential threat to the business; potential for catastrophic financial and reputational loss. | All hands on deck; executive team, legal, and all relevant departments are engaged. |              Affects all customers; public and shareholders are notified.              |        7 Days        |
|  SEV-2   |    Major incident with significant impact.     |          Significant service outage; major disruption to a specific business function.          |      All hands on decks; coordination across RPD, Solutions, Success, and GTM.      |       Affects a subset of customers; may require customer-centric post-mortems.        |        7 Days        |
|  SEV-3   |        Minor incident with low impact.         |                      Noticeable revenue and customer impact; affects SLOs.                      |                 Internal to RPD; requires cross-team coordination.                  | Affects customers in a noticeable but not crippling way; workarounds may be available. |       14 Days        |
|  SEV-4   | Low-priority incident impacting a single team. |          Minor customer impact; affects SLOs but is contained within a specific area.           |                       Internal to a single engineering team.                        |              Minor inconvenience to customers or performance degradation.              |       14 Days        |
|  SEV-5   |        Informational or cosmetic issue.        |     No direct customer or revenue impact; warrants using the incident process for learning.     |       Internal to an engineering team; may be resolved during working hours.        |        No customer impact; typically cosmetic issues or internal tool problems.        |       Optional       |

Here are the core definitions for each severity level at Rokt:

- **SEV-1 (Critical):** Reserved for the most impactful incidents. These are existential threats to the business that require an immediate, all-hands-on-deck response. A SEV-1 incident would include a complete outage of a customer-facing service for all users, a massive data breach, or a ransomware attack. Such events necessitate executive outreach, public post-mortems, and formal communications with shareholders.
- **SEV-2 (High):** A significant service outage affecting a large number of customers. While not an existential threat, a SEV-2 incident demands an "all hands on deck" response from multiple teams. It requires coordinated efforts across the organization, including engineering, solutions, success, and Go-To-Market teams, and may involve customer-centric post-mortems. A SEV-2 could be a core functionality issue affecting a subset of customers or a major degradation of service.
- **SEV-3 (Moderate):** An incident that has a noticeable impact on customers and revenue but can typically be handled during normal working hours. These issues are internal to the Rokt Product Development (RPD) organization but require coordination across multiple engineering teams. They impact Service Level Objectives (SLOs) and may cause a moderate inconvenience to customers or a slowing of business operations.
- **SEV-4 (Low):** A minor issue that is generally contained within a single engineering team. While it has a customer impact and affects SLOs, it does not cause a widespread service disruption. An example might be a minor bug that affects a small portion of users or a slower-than-average load time for a non-critical feature. These issues can often be addressed during a team's normal working hours.
- **SEV-5 (Informational):** The least severe level, used for incidents that have no customer impact but still warrant using the incident process for post-mortems and documentation. These are often cosmetic issues, such as a typographical error, or minor internal tool performance issues that do not affect core functionality.

### Communication by Severity Level

- **SEV-1:** These are our most critical incidents and require the highest level of communication. Executive outreach is mandatory, involving a coordinated response from leaders like CEO [Bruce Buchanan](mailto:bruce@rokt.com), CFO [Jacqui Purcell](mailto:jacqui@rokt.com), and CTO [Andrew Katz](mailto:ak@rokt.com). For this type of event, a mass notification system would be used to instantly inform all of our employees across our global offices. Communication with external stakeholders is equally critical. A consistent communication style and cadence, defined in our style guide, is critical for delivering a unified message and avoiding a public relations crisis.
- **SEV-2:** As a "major incident", a SEV-2 requires frequent internal and potentially external communication. Teams like Solutions and Success need a consistent flow of information to share with affected clients.13 The communication must be frequent and transparent to keep stakeholders informed of progress and next steps. For larger incidents, a public status page would be updated regularly.
- **SEV-3, SEV-4:** The communication scope for these incidents is more contained. A SEV-3 issue may involve cross-team updates within RPD, while a SEV-4 may only require a formal communication within a single engineering team. A SEV-5 incident, used primarily for internal learning, may not require a company-wide update at all, but rather a short note in an internal channel to initiate the post-mortem process.
- **SEV-5:** SEV-5's are used to mark a non-incident. This allows teams to utilize the machinery of the incident process to manage complex rollouts and migrations. Post mortems are not required as there is no customer impact for a SEV-5.

# Incident Commanders

The following Exco Prod Eng list makes up the available Incident Commanders (IC) for SEV-1 incidents. During a SEV-1 it is mandatory one of the following individuals is selected as incident commander. The selection process is ordered. If the first entry is not available use the following entry until an incident commander is chosen.

| Name/Commanders (hover for email and mobile)           | Title                           |
| ------------------------------------------------------ | ------------------------------- |
| [Claire Southey](mailto:claire.southey@rokt.com)       | Chief AI Officer                |
| [Prashanth Mekala](mailto:prashanth.mekala@rokt.com)   | Chief Security Officer          |
| [Andrew Katz](mailto:akatz@mparticle.com)              | Chief Technology Officer        |
| [Reuben Kan](mailto:reuben.kan@rokt.com)               | SVP of Engineering              |
| [Sam Dozor](mailto:sdozor@mparticle.com)               | SVP of Engineering              |
| [John Walzer](mailto:john.walzer@rokt.com)             | VP of Engineering               |
| [Dan Piet](mailto:daniel.piet@rokt.com)                | VP of Engineering               |
| [DJ Seo](mailto:dj.seo@rokt.com)                       | VP of Engineering               |
| [Art Shamsutdinov](mailto:artur.shamsutdinov@rokt.com) | VP of Engineering               |
| [Jinli Liang](mailto:paul.liang@rokt.com)              | VP of Engineering               |
| [Stuart FitzRoy](mailto:stuart@rokt.com)               | Managing Director \- APAC & DPO |
| [Thomas Lapp](mailto:thomas.lapp@rokt.com)             | Director, Operations            |

# External Contacts

Find here additional external contacts that might be useful.

| Organization                                                      | Contact                                                                                                                                                                                                                                         | Email                                                                                 | Phone                                                                                                         |
| :---------------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------ | :------------------------------------------------------------------------------------------------------------ |
| Forensic Investigation Consultancy & Independent Security Advisor | Stroz Friedberg (AON Company) Austin Tippett, VP Cyber Solutions                                                                                                                                                                                | austin.tippett@strozfriedberg.com                                                     | \+1 206 887 2840 24/7 monitored line: (US) 1800 519 2743                                                      |
|                                                                   | Kroll, LLC [Kroll Points of Contact - (March 2025).pdf](https://drive.google.com/file/d/1x6uIz8T6icso3GrVQkKbq1Rf64384mYR/view?usp=drive_link)                                                                                                  | cyberresponse@kroll.com CC: eric.hasty@kroll.com, jerry.cotellesse@kroll.com          | 24/7/365 monitored line: \+1 877 300 6816                                                                     |
| Privacy Counsel                                                   | Linklaters Ieuan Jolly Caitlin Metcalf                                                                                                                                                                                                          | ieuan.jolly@linklaters.com caitlin.metcalf@linklaters.com cyberhotline@linklaters.com | \+1 212 903 9574 \+1 202 654 9240 hotline: 212 903 9224                                                       |
| Breach Coach / Counsel                                            | Coughlin Mullen Kevin Dolan John Mullen                                                                                                                                                                                                         | kdolan@mullen.law jmullen@mullen.law                                                  | \+1 267 973 2206 \+1 267 930 4791                                                                             |
| Cloud Service Provider                                            | [ISMS-DOC-A17-2_01 BCP lists all contact details of agencies and people who may be useful depending on the nature of the incident](https://docs.google.com/document/d/1zSRRfT34s2b3U_xI6EubvTCGzUptKqvWNv8zwbHcXqM/edit#heading=h.cf7r77lk3o08) |                                                                                       |                                                                                                               |
| Cyber Insurance                                                   | Kristin Hanson (Aon)                                                                                                                                                                                                                            | kristin.k.hanson@aon.com                                                              | \+1 415 214 0961                                                                                              |
|                                                                   | Aman Mittal (Aon)                                                                                                                                                                                                                               | aman.mittal3@aon.com                                                                  | \+1 650 714 2446                                                                                              |
| Call Center                                                       | CallRuby (external answering service)                                                                                                                                                                                                           | n/a                                                                                   | \+1 866 611 7829                                                                                              |
|                                                                   | RingCentral (external answering service)                                                                                                                                                                                                        | n/a                                                                                   | US: \+1 646 624 2600 AU: \+61 2 7259 3123 UK: \+44 20 3808 3480 SG: \+65 3163 3369 JP: \[set up in progress\] |

For more details, refer to Rokt’s official [Incident Response Procedure](https://docs.google.com/document/d/1kE12DrJ4kvAOjim9eAIWzF852cO9ChKlM2czMDs17sE/edit?usp=sharing).

# TicketMaster SEV-1 Escalation & Communication

TicketMaster is one of Rokt's few truly tier-1 customers. This means extra care must be taken when handling incidents which impact their service availability.

For incidents classified as **SEV-1** and deemed business critical to Ticketmaster’s core operations, the following escalation process is to be followed.

**1\. Executive Escalation**  
One of the following individuals is responsible for determining if customer outreach is required.

- [Claire Southey](mailto:claire.southey@rokt.com)
- [Andrew Katz](mailto:akatz@mparticle.com)
- [Reuben Kan](mailto:reuben.kan@rokt.com)
- [Sam Dozor](mailto:sdozor@mparticle.com)
- [Dan Piet](mailto:daniel.piet@rokt.com)

**2\. Direct Communication**  
If notification is warranted, this senior leader must personally reach out to Ticketmaster to communicate the incident details. For details on how to communicate to TicketMaster, view [this section](#notifying-ticketmaster-on-slack) in the appendix.

# Appendix

## Meet / Slack / GChat / Incident Thread

There are four locations where incident updates are broadcasted. These are listed in the incident post in either **Engineering \- Incidents** or **Tech Emergencies.** Their use case is defined below.

#### Incident Thread

This thread should be treated as read-only. Its purpose is to provide updates to the broader organization during an incident. Think of it as a centralized bulletin board for high-level communication.

#### Google Meet

When an incident is declared, a Google Meet is created. The Incident Commander is responsible for starting the recording upon joining. This meeting serves as the primary channel for high-bandwidth, real-time communication to drive resolution.

#### Google Chat Channel {#google-chat-channel}

This channel is dedicated to active incident response. Use it for coordination, operational questions, and real-time discussion related to the incident.

#### Slack Channel

Because Google Chat does not support message mirroring, Slack is used to document structured notes during the incident. This includes commands executed, key decisions, action items for the postmortem, and links to relevant dashboards and metrics. These notes are mirrored into the Datadog incident record to ensure a well-structured, timestamped account that supports a thorough postmortem.

## Declaring an Incident {#declaring-an-incident}

There are three ways you can declare an incident.

### Through Datadog Incidents {#through-datadog-incidents}

1. Go to [Datadog Incidents](http://go/dd-incidents). If you have not SAML’d into datadog previously, use the Non-RPD [declaration method](#through-ui).
2. In the upper right hand corner, select “+ Declare Incident”

3. Complete incident form and submit with “Declare Incident”

### Through Slack {#through-slack}

1. Go to [rokt.slack.com](http://rokt.slack.com)
2. In any message box run: `/dd incident`
3. Complete the form that appears in slack and then select “Declare Incident”

### Through UI {#through-ui}

1. Go to [our website](http://go/new-incident) for creating a new incident. (Requires AppGate SDP to be on)
2. Complete the form (all fields must be completed) and then hit “Submit”.

## Changing an Incident’s Severity {#changing-an-incident’s-severity-1}

### Through Slack

1. Go to the slack channel associated with an incident. This link is included with incident updates to Google Chat incident channels.
2. Run the command in that channel’s chat:

`/dd incident update`

3. Update the “Severity” field then click “Update”

### Through Datadog Incidents

1. Within the specific incident page on [Datadog incidents](http://go/dd-incidents), simply select a new incident severity level.

## Change Impacted Teams / Services {#change-impacted-teams-/-services}

### Through Slack

1. Go to the slack channel associated with an incident. This link is included with incident updates to Google Chat incident channels.
2. Run the command in that channel’s chat:

```
/dd incident update
```

3. Scroll to the bottom of the “Edit Incident” window, search and multi-select for desired “Services” (based on Datadog APM) and “Teams” then click “Update”.

### Through Datadog Incidents

1. Within the specific incident page on [Datadog incidents](http://go/dd-incidents), scroll to the bottom of the page and select/remove desired “Services” (From APM) or “Teams” from the incident.

## Changing the Incident Commander {#changing-the-incident-commander}

### Through Datadog Incidents

1. Within the specific incident page on [Datadog incidents](http://go/dd-incidents), scroll to the bottom of the page and change the “Incident Commander” field.

## Resolving the Incident {#resolving-the-incident}

### Through Slack

1. Go to the slack channel associated with an incident. This link is included with incident updates to Google Chat incident channels.
2. Run the command in that channel’s chat:

```
/dd incident update
```

3. Update the “State” field to “Resolved” then click “Update”

### Through Datadog Incidents

1. Within the specific incident page on [Datadog incidents](http://go/dd-incidents), in the upper left hand corner change the status to “Resolved”.

## Paging {#paging}

Once an incident has been assessed, your first responders might be all the people required to resolve the incident. However, in some scenarios, the Incident Commander may need to escalate to other teams by paging them if their own alerts haven’t kicked in. Paging of teams can be done through the Dispatcher bot in Google Chat. You can do this in the incident thread or the preferred "[Incidents \- Dispatcher](https://mail.google.com/chat/u/0/#chat/space/AAAAXcyw01U)" channel

1. ### Go to the [“Incidents \- Dispatcher”](https://mail.google.com/chat/u/0/#chat/space/AAAAXcyw01U) channel in Google Chat

2. Page the teams or users needed. Note that a user is specified by their full ROKT email address.

```
# Use the 'new' slash command/dispatcher_page# Alternatively use the legacy @ command# Page a user
@Dispatcher page user1@rokt.com

# Page a team
@Dispatcher page "team1"
```

3. To see a list of all teams:

```
@Dispatcher list teams --all
```

4. For help:

```
@Dispatcher help
```

For a full list of commands, refer to the [Dispatcher docs](https://github.com/ROKT/dispatcher/blob/master/docs/usage.md).

### GTM & PMM Involvement

Any incident with confirmed or suspected **customer or revenue impact** (or Sev2+ incident) should be surfaced to the relevant product and GTM leads as soon as possible in the appropriate incident response [chat channel](#google-chat-channel).

_This group will determine the scope of broader team notification, proactive client communications, and any remediation required, following the process below._

**Individuals to Notify** (in RPD x GTM Leads Chat)

| Product area                  | Product                                      | Product Marketing                                 | GTM                                                                                                                                         |
| ----------------------------- | -------------------------------------------- | ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| **Rokt Pay+**                 | [Matt Vincent](mailto:matt.vincent@rokt.com) | [Emily Klein](mailto:emily.klein@rokt.com)        | [Cal Donnelly](mailto:callum.donnelly@rokt.com)[Laura Cosgrove](mailto:laura.cosgrove@rokt.com)                                             |
| **Rokt Thanks**               |                                              | [Lauren Ally](mailto:lauren.ally@rokt.com)        |                                                                                                                                             |
| **Rokt Ads**                  | [Max Dowaliby](mailto:max.dowaliby@rokt.com) | [Eva Xu](mailto:eva.xu@rokt.com)                  | [Jon Humphrey](mailto:jon.humphrey@rokt.com)                                                                                                |
| **Rokt Catalog**              | [Liam Kinney](mailto:liam.kinney@rokt.com)   | [Josh Fleishman](mailto:josh.fleishman@rokt.com)  | [Bennett Carroccio](mailto:bennett.carroccio@rokt.com)                                                                                      |
| **Rokt mParticle**            | [Jason Lynn](mailto:jason.lynn@rokt.com)     | [Ava Ginsberg](mailto:ava.ginsberg@mparticle.com) | [Jillian Burnett](mailto:jillian.burnett@rokt.com)                                                                                          |
| **Shoppable Ads / AfterSell** | [Chris Arnold](mailto:chris.arnold@rokt.com) | [Josh Fleishman](mailto:josh.fleishman@rokt.com)  | [Cal Donnelly](mailto:callum.donnelly@rokt.com)[Laura Cosgrove](mailto:laura.cosgrove@rokt.com)[Jon Humphrey](mailto:jon.humphrey@rokt.com) |

### **_GTM Response process_**

|  \#   | Step                                                                                                                                     | Owner(s)                                   | Details                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| :---: | :--------------------------------------------------------------------------------------------------------------------------------------- | :----------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1** | **Declare Incident & Notify Leads**                                                                                                      | Incident Commander                         | RPD declares incident and assigns Incident Commander to own E2E incident response  IC notifies [incident gChat channel](#google-chat-channel) with severity assessment and known scope; tag relevant Product Lead, GTM lead, and PMM (see chart above)                                                                                                                                                                                                |
| **2** | **Share ‘Incident Summary Post’** in incident chat room                                                                                  | Incident Commander                         | Pin a summary post in the incident chat room covering: Problem Estimated Impact (ongoing) Estimated time for next update _Keep this post updated as the incident evolves_                                                                                                                                                                                                                                                                             |
| **3** | **Notify broader GTM team**                                                                                                              | PMM                                        | Post a general "investigating issue" message in appropriate GTM channels (e.g. GTM \- Ads, RPD x GTM Leads Chats) with link to incident chat room _Pod leads should direct all AM questions to incident chat room_                                                                                                                                                                                                                                    |
|   4   | **Create Incident Response Guide** ([example](https://docs.google.com/document/u/0/d/1MnX2HedEgXCvjBm2DMWUvwmucppHb100N5hxrI0RUO0/edit)) | PMM                                        | Create \+ share **Incident Response Guide** covering: high-level incident overview, impact scope, and required GTM actions                                                                                                                                                                                                                                                                                                                            |
|       |                                                                                                                                          | Incident Commander                         | Attach an **impact analysis gSheet** _(“IR XX \- Impact Analysis”)_ with these columns: Account manager name Account ID Account Name Campaign ID (if relevant) Campaign Name (if relevant) Pod Name Impact analysis (dependent on incident details) Expected metrics/amounts (in local \+ USD) Actual metrics/amounts (in local \+ USD) Delta (expected vs. actual) GTM Checklist columns Reviewed by CS? Credit Required? Reached out to the client? |
|       |                                                                                                                                          | PMM x GTM lead(s)                          | (Internal) Remediation plan (credit required, next steps); loop in [Steve Kall](mailto:stephen.kall@rokt.com)for visibility on client credits                                                                                                                                                                                                                                                                                                         |
|       |                                                                                                                                          | PMM                                        | (External) Client Comms template (Requires GTM lead signoff)                                                                                                                                                                                                                                                                                                                                                                                          |
|   5   | **Client Outreach (as needed)**                                                                                                          | PMM                                        | Update all open GTM threads with the finalized impact analysis, remediation plan, and client comms guidance from Step 4 AMs execute client outreach using approved templates and update the impact analysis tracker                                                                                                                                                                                                                                   |
|   6   | **Credits delivery** (if required)                                                                                                       | [Steve Kall](mailto:stephen.kall@rokt.com) | Queue \+ deliver approved advertiser credits from step \#4                                                                                                                                                                                                                                                                                                                                                                                            |
|   7   | **Incident Analysis document**                                                                                                           | Incident commander                         | Formal postmortem: root cause, timeline, remediation steps, and measures to prevent recurrence                                                                                                                                                                                                                                                                                                                                                        |
|   8   | **IR Review Meeting**                                                                                                                    | Incident commander                         | Schedule and lead stakeholder [review](#incident-review-meeting) with Product, Engineering, and GTM.                                                                                                                                                                                                                                                                                                                                                  |

##

## Notifying Ticketmaster on Slack {#notifying-ticketmaster-on-slack}

Rokt shares a slack channel with our daily engineering, product, and commercial stakeholders called [‘tm-rokt’](https://rokt.slack.com/archives/CDE6J1BJ5). Please start a thread in this slack channel following this protocol:

Title of the post: **Sev level, Topic name, Tags appropriate members**

- For TM, please ALWAYS tag [keenan.seguncia@ticketmaster.com](mailto:keenan.seguncia@ticketmaster.com)
- For TM , please tag the other contacts based on which product the incident is impacting:

| Product                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | TM Rep to Tag   | Rokt Rep to Tag                                                                                    |
| :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :-------------- | :------------------------------------------------------------------------------------------------- |
| **Ticketmaster Hotels/ Rokt Ads** Account Name: Live Nation \- Global Solutions Team Account ID: 3148152371751954573                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | Zainab Lauchard | [Isrra Kang](mailto:isrra.kang@rokt.com), [Matt Higgins](mailto:matt.higgins@rokt.com)             |
| **Upcart by Rokt** Account Name(s): Live Nation Worldwide, Inc. (TM US), Live Nation Worldwide, Inc. (LN US) Account ID(s) : 227, 253                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | Keenan Seguncia | [Isrra Kang](mailto:isrra.kang@rokt.com), [Akshay Talegaonkar](mailto:akshay.talegaonkar@rokt.com) |
| **Pay+** Account Name: Live Nation Worldwide, Inc. (TM US) Account ID: 227                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | Keenan Seguncia | [Isrra Kang](mailto:isrra.kang@rokt.com), [Akshay Talegaonkar](mailto:akshay.talegaonkar@rokt.com) |
| **Rokt Thanks** Account Name(s): Live Nation Canada Inc (TM CA) Live Nation Worldwide, Inc. (LN US) Live Nation Worldwide, Inc. (TM US) Ticketmaster Australasia Pty Ltd (TM AU) Ticketmaster Belgium (TM BELG) Ticketmaster Denmark (TM DK) Ticketmaster GmbH (TM DE) Ticketmaster Ireland (TM IE) Ticketmaster Mexico (TM MX) Ticketmaster Netherlands (TM NL) Ticketmaster New Zealand. (TM NZ) Ticketmaster Spain SAU (TM ESP) Ticketmaster Sweden (TM SE) Ticketmaster UK Limited (TM UK) TICKETNET SAS (TM FR) Account ID(s) : 227 249 250 251 253 280 344 404 2534379838388866524 2562150491334379217 2671376238430696211 2806519879775293718 2856514896828575405 2916342176354147158 3142350059913660698 | Keenan Seguncia | [Isrra Kang](mailto:isrra.kang@rokt.com), [Matt Higgins](mailto:matt.higgins@rokt.com)             |

## AWS Break Glass Privileges

To effectively contain an incident, elevated privileges to AWS may be needed. Any Engineering Manager can [grant temporary AWS SSO BreakGlass access](https://github.com/ROKT/glass/blob/main/docs/operations/managing-breakglass-role-users.md#getting-temporary-access-to-the-breakglass-role) to responders as and when needed. [http://go/breakglass](http://go/breakglass) for more information.[http://go/breakglass](http://go/breakglass)

## Incident Timeline Flagging {#incident-timeline-flagging}

When creating an incident. Before you click the "Generate Postmortem" button.

Be sure to flag any item in the timeline you believe is important.

The post-mortem will inline the first **100** important items into the post-mortem.
