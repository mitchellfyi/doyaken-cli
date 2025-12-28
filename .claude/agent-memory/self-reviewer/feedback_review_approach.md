---
name: review_approach
description: Preferences and patterns for reviewing this doyaken codebase
type: feedback
---

Review approach for this codebase:

- Working tree may have uncommitted changes that don't appear in `git diff main...HEAD` — always diff HEAD vs working tree (`diff <(git show HEAD:file) file`) for files the prompt specifically calls out.
- The project uses shellcheck (install at /opt/homebrew/bin/shellcheck). SC2088 (tilde in quotes) is a known accepted pattern in user-facing messages — don't report it.
- SC1091 (not following sourced files) is expected across all shell scripts — suppress it in shellcheck runs.
- lib/*.sh files are bash/zsh compatible libraries with `# shellcheck shell=bash` directives — this is correct, not a bug.
- dk.sh is zsh-only with `# shellcheck shell=bash disable=SC2296` — SC2296 suppression is intentional.

**Why:** The codebase deliberately spans bash and zsh contexts and shellcheck can't follow dynamic sources.

**How to apply:** When running shellcheck, filter SC1091 and SC2088 before reporting findings.
