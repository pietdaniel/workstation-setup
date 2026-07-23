---
name: find-repo-owner
description: Find repository ownership from Cortex, CODEOWNERS, and git contributors. Use when identifying a repository's owning team, review channel, maintainers, or code owners.
---

# Find Repository Owner

Determine repository ownership from the strongest available source. Run this
from the repository root and report the evidence used. Do not infer that an
ownership file is absent from a glob result, especially for hidden directories.

## 1. Check Cortex Catalog

Check the catalog directory directly before searching it:

```bash
test -d .cortex/catalog && printf '%s\n' '.cortex/catalog exists'
```

If it exists, inspect every `.yaml` and `.yml` catalog file for
`x-cortex-owners`. Read the matching catalog file and extract each owner with
`type: group` and its `name`. This is the primary owning-team source.

Example catalog shape:

```yaml
x-cortex-owners:
  - type: group
    name: rokt-global-infrastructure
```

If a Cortex group is present, record it as the owning team and continue to
CODEOWNERS as corroborating evidence when it is present.

## 2. Check CODEOWNERS

Check these paths directly, in this order:

```text
.github/CODEOWNERS
CODEOWNERS
docs/CODEOWNERS
```

Use a direct file-existence check for each path before reading it. For a
repository-level owner, inspect the `*` rule. For a file-specific ownership
question, determine the changed or requested paths first, then match the most
specific applicable rule. Report the GitHub team or users exactly as written.

If Cortex and CODEOWNERS disagree, report the conflict and ask the user which
source should govern the current action. Do not choose silently.

## 3. Check Git Contributors

Always gather recent contributor context. Prefer contributors to the affected
files over repository-wide history. Use the merge-base against the default
branch to identify changed files; if there are no changed files, use the
repository history.

```bash
BASE=$(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main)
git diff --name-only "$BASE"...HEAD
git log --format='%aN <%aE>' --since='12 months ago' -- <affected paths> | sort | uniq -c | sort -rn
```

Report the leading contributors as suggestions, not authoritative ownership.
Contributor history is the ownership fallback only when neither Cortex nor
CODEOWNERS identifies an owner. Never use commit authorship alone to identify
a team or select a chat channel.

## Required Output

State:

- **Owning team:** Cortex group, CODEOWNERS team, or `unknown`.
- **Evidence:** exact catalog and/or CODEOWNERS path and relevant rule.
- **Corroboration:** whether Cortex and CODEOWNERS agree.
- **Suggested maintainers:** leading recent contributors, clearly labeled as
  non-authoritative when Cortex or CODEOWNERS exists.
- **Confidence:** high for matching Cortex and CODEOWNERS, medium for one
  authoritative source, low for contributor history alone.

For review requests, use the owning team only after this process completes.
When selecting a GChat space, search for the exact Cortex group name and prefer
that team's PR channel, then public engineering channel, then team channel.
