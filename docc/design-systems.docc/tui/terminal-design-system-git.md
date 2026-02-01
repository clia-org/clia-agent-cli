# Terminal Git Guidance

Git output is a high-risk UI surface. Treat every command as operator-facing.

## Safety Gate

- Show the exact command and affected paths before running any git command.
- Wait for explicit approval before `git` and destructive actions.
- For destructive flows, do the steps in this order: move files, build new output, test, then
  delete/clean last.

## Output Shape

- Lead with intent: what you are about to do and why.
- Include the smallest useful command set (`git status -sb`, targeted `git diff --stat`).
- Keep approvals explicit: “approve git”, “approve destructive”, or numbered choices.

## Submodules

- Call out submodule paths explicitly and keep commits separate per repo.
- If a submodule commit is needed, say so before running `git commit` and `git push`.
