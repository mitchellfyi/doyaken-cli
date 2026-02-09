---
name: zsh-in-lib
enabled: true
event: file
pattern: (?:lib/|hooks/|bin/).*\.sh
action: warn
---

You are editing a bash or bash/zsh-compatible script. Do NOT use zsh-only syntax here (e.g., `${(j: :)@}`, zsh arrays). Only `dk.sh` may use zsh features. Verify bash compatibility with `bash -n`.
