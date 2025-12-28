---
name: block-destructive-commands
enabled: true
event: bash
pattern: rm\s+-(?:[a-z]*r[a-z]*f|[a-z]*f[a-z]*r)[a-z]*\s+(?:--\s+)?(?:(?:/|~|\$HOME|\.)/?(?:\s|$|[;&|])|\*(?:\s|$|[;&|]))|dd\s+if=|mkfs|format\s+[a-z]:
action: block
---

BLOCKED: Destructive system command detected.

This command could cause irreversible data loss. Please verify the exact path and use a safer approach.

Caught patterns: `rm -rf /`, `rm -rf ~`, `rm -rf ~/`, `rm -rf $HOME`, `rm -rf .`, `rm -rf ./`, `rm -rf *`, and variants with reordered flags (`-fr`, etc.). Paths with subdirectories (e.g., `rm -rf ./build`, `rm -rf /tmp`) are NOT blocked — only the root/home/cwd targets themselves. Also blocks `dd if=`, `mkfs`, and `format X:`.
