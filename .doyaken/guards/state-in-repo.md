---
name: state-in-repo
enabled: true
event: file
pattern: \.doyaken/(?!worktrees/|guards/|rules/|doyaken\.md|CLAUDE\.md|\.gitignore).*\.(state|phase|times|complete|active|prompt)
action: warn
---

Ephemeral state files must NOT be written inside the repo. State belongs in `~/.claude/.doyaken-phases/` or `~/.claude/.doyaken-loops/`, keyed by session ID.
