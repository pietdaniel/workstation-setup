#!/usr/bin/env zsh
PR_URL=$1

# check if opencode exists
if ! command -v opencode &> /dev/null
then
    echo "opencode could not be found, please install it first."
    exit
fi

opencode run --model "amazon-bedrock/anthropic.claude-opus-4-6-v1" "Please update the Title and Description of this PR: $PR_URL"
