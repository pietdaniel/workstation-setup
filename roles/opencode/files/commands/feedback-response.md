---
description: Address PR feedback, push fixes, respond to comments, and ensure CI is green
---

Load the "pr-feedback-review" skill and analyze all feedback on the PR. For each piece of feedback:

1. If the feedback warrants a code change, make the fix locally.
2. If the feedback does not warrant a change, note why so you can respond explaining your reasoning.

Once all feedback has been addressed, commit and push the changes. Then respond to every feedback comment on the PR:
- For feedback you acted on, reply with a summary of what you changed.
- For feedback you chose not to act on, reply explaining why no change was needed.

After pushing and responding, load the "fix-ci" skill and follow its instructions to check CI status. If there are any failures, diagnose and fix them, push again, and repeat until CI is green.

$ARGUMENTS
