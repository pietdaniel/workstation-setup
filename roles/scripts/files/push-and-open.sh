#!/usr/bin/env zsh
MESSAGE=$1

if [ -z "$MESSAGE" ]; then
    echo "Usage: push-and-open <commit-message>"
    exit 1
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
    echo "Cannot push and open a PR from $BRANCH. Please switch to a feature branch."
    exit 1
fi

# check if opencode exists
if ! command -v opencode &> /dev/null
then
    echo "opencode could not be found, please install it first."
    exit 1
fi

git add -A
git commit -m "$MESSAGE"
git push -u origin "$BRANCH"

PR_URL=$(gh pr create --fill 2>&1)
if [ $? -ne 0 ]; then
    echo "Failed to create PR: $PR_URL"
    exit 1
fi

echo "PR created: $PR_URL"

opencode run "Please update the Title and Description of this PR: $PR_URL"
