---
name: "yeet"
description: "Use only when the user explicitly asks to stage, commit, push, and open a GitHub pull request in one flow using the GitHub CLI (`gh`)."
---

## Prerequisites

- Require GitHub CLI `gh`. Check `gh --version`. If missing, ask the user to install `gh` and stop.
- Require authenticated `gh` session. Run `gh auth status`. If not authenticated, ask the user to run `gh auth login` (and re-run `gh auth status`) before continuing.

## Naming conventions

- Branch: `dp/{description}` when starting from main/master/default.
- Commit: `{description}` (terse).
- PR title: `{description}` summarizing the full diff.

## Workflow

- If on main/master/default, create a branch: `git checkout -b "dp/{description}"`
- Otherwise stay on the current branch.
- Confirm status, then stage everything: `git status -sb` then `git add -A`.
- Commit tersely with the description: `git commit -m "{description}"`
- Run checks if not already. If checks fail due to missing deps/tools, install dependencies and rerun once.
- Push with tracking: `git push -u origin $(git branch --show-current)`
- If git push fails due to workflow auth errors, pull from master and retry the push.
- Open a PR and edit title/body to reflect the description and the deltas: `GH_PROMPT_DISABLED=1 GIT_TERMINAL_PROMPT=0 gh pr create --fill --head $(git branch --show-current)`
- Write the PR description to a unique-per-run file under `/tmp` with real newlines, then pass it to `gh pr create --body-file <path>` to avoid `\n`-escaped markdown. Generate the path with `BODY=$(mktemp /tmp/yeet-pr-body.XXXXXX) && mv "$BODY" "$BODY.md" && BODY="$BODY.md"` (note: macOS `mktemp -t` always uses `$TMPDIR` and ignores `/tmp`, so pass the full template path). Fallback: `BODY=/tmp/yeet-pr-body-$(date +%s)-$$.md`. Concurrent yeet runs get distinct paths and cannot clobber each other. Always anchor under `/tmp` (not `$TMPDIR` / `/var/folders/...`). Clean up the file after the PR is created.
- PR description (markdown) must be detailed prose covering the issue, the cause and effect on users, the root cause, the fix, and any tests or checks used to validate.
