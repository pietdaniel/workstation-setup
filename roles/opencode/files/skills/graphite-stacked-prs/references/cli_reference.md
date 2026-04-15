# Graphite CLI Reference

## Installation

**Homebrew (recommended):**

```bash
brew install withgraphite/tap/graphite
```

**NPM:**

```bash
npm install -g @withgraphite/graphite-cli@stable
```

**Prerequisites:** Git >= 2.38.0

**Auth:** `gt auth --token <token>` (get token from https://app.graphite.com/activate)

## Command Cheatsheet

### Creating & Modifying Branches

| Task                                   | Command                                    | Short             |
| -------------------------------------- | ------------------------------------------ | ----------------- |
| Create new branch                      | `gt create`                                | `gt c`            |
| Create, stage all, commit with message | `gt create --all --message "msg"`          | `gt c -am "msg"`  |
| Amend staged changes to current branch | `gt modify`                                | `gt m`            |
| Stage all and amend                    | `gt modify --all`                          | `gt m -a`         |
| Add new commit to current branch       | `gt modify --commit`                       | `gt m -c`         |
| Stage all, new commit with message     | `gt modify --commit --all --message "msg"` | `gt m -cam "msg"` |

### Syncing & Submitting

| Task                                        | Command                           |
| ------------------------------------------- | --------------------------------- |
| Pull trunk, clean merged, restack           | `gt sync`                         |
| Push current + downstack, create/update PRs | `gt submit`                       |
| Push entire stack, create/update PRs        | `gt submit --stack`               |
| Only update existing PRs                    | `gt submit --stack --update-only` |
| Auto-generate PR title/body                 | `gt submit --ai`                  |
| Preview without pushing                     | `gt submit --dry-run`             |
| Confirm before each push                    | `gt submit --confirm`             |

### Navigating

| Task                  | Command       | Short   |
| --------------------- | ------------- | ------- |
| Switch to branch      | `gt checkout` | `gt co` |
| Move up one branch    | `gt up`       | `gt u`  |
| Move down one branch  | `gt down`     | `gt d`  |
| Go to top of stack    | `gt top`      | `gt t`  |
| Go to bottom of stack | `gt bottom`   | `gt b`  |

### Viewing

| Task                  | Command        | Short   |
| --------------------- | -------------- | ------- |
| Full branch/PR info   | `gt log`       |         |
| Branch list           | `gt log short` | `gt ls` |
| Commit ancestry graph | `gt log long`  |         |

### Reorganizing

| Task                                   | Command      | Short   |
| -------------------------------------- | ------------ | ------- |
| Move branch to new parent              | `gt move`    |         |
| Fold branch into parent                | `gt fold`    |         |
| Delete branch, keep changes            | `gt pop`     |         |
| Reorder branches                       | `gt reorder` |         |
| Split branch into multiple             | `gt split`   | `gt sp` |
| Squash commits into one                | `gt squash`  | `gt sq` |
| Distribute staged changes to downstack | `gt absorb`  | `gt ab` |

### Recovery & Collaboration

| Task                        | Command       |
| --------------------------- | ------------- |
| Undo last Graphite mutation | `gt undo`     |
| Track existing Git branch   | `gt track`    |
| Fetch teammate's stack      | `gt get`      |
| Freeze branch from edits    | `gt freeze`   |
| Unfreeze branch             | `gt unfreeze` |

## Key Command Details

### gt create [name]

Creates a new branch stacked on the current branch.

- `--ai`: Auto-generate branch name and commit message
- `-a, --all`: Stage all changes
- `-m, --message`: Commit message
- `-p, --patch`: Interactively pick hunks

### gt modify

Amend or add commits, then restack descendants.

- `-a, --all`: Stage all changes
- `-c, --commit`: Create new commit (vs amend)
- `-m, --message`: Commit message
- `--into`: Amend into a specific downstack branch

### gt submit

Force push all branches from trunk to current branch, creating/updating PRs.

- `--ai`: Auto-generate PR title and description
- `-s, --stack`: Include descendants
- `-c, --confirm`: Confirm before each push
- `-e, --edit`: Interactive PR metadata entry
- `--dry-run`: Preview only

### gt restack

Rebase branches so each has its parent in commit history.

- `--downstack`: Only ancestors
- `--upstack`: Only descendants

### gt sync

Pull trunk, delete merged branches, restack remaining.

- `-f, --force`: Skip confirmations
