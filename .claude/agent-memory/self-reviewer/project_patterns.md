---
name: project_patterns
description: Recurring patterns, known issues, and common mistakes in the doyaken codebase
type: project
---

## State File Cleanup Patterns

dk_cleanup_session() in lib/session.sh is the canonical way to remove all loop+phase state files for a session. It covers: .state, .complete, .active, .prompt (loop files) + .phase, .times (phase files).

dkloop (shell function) intentionally does a SUBSET cleanup (only loop files, no .active or phase files) because it never creates .active or phase state. This is not an inconsistency.

## Install/Uninstall Symmetry

install.sh checks for existing install with: `grep -q 'doyaken/dk.sh' "$ZSHRC"` — this assumes DOYAKEN_DIR path contains 'doyaken'. This is a pre-existing assumption.

**Known regression (as of 2026-03-21):** install.sh now writes `export DOYAKEN_DIR="..."` in addition to the source line, but the idempotency check (line 112) only looks for the source line. Users with a pre-existing install who re-run `dk install` will not get the new DOYAKEN_DIR export line added. They need to manually add it or fully reinstall.

uninstall.sh uses `grep -v 'DOYAKEN_DIR'` to remove the export line — this is intentionally broad and will also remove any user-written DOYAKEN_DIR references in .zshrc.

## awk ENVIRON Pattern

config.sh uses `_DKTMP="$path" awk '... ENVIRON["_DKTMP"] ...'` to pass file paths to awk programs. This is the correct pattern to avoid: (1) shell injection via string interpolation, (2) BSD awk multiline -v bugs, (3) whitespace/quoting issues in paths.

## Session ID Derivation

dk_session_id() without args: reads from worktree path or current branch name. With arg: returns "worktree-{name}". IDs are NOT cryptographically random — documented in session.sh.

dk_unique_session_id() (added 2026-03-21): appends PID + epoch to branch-based ID. Used by dkloop to prevent collisions across concurrent invocations. The unique ID is passed via DOYAKEN_SESSION_ID env var so phase-loop.sh and skills (dkloop, dkcomplete) use the correct ID.

Implication: dkloop now generates a NEW session ID every run. Stale .prompt, .state, .active, .complete files from prior interrupted runs are NOT cleaned by the next run (unique ID means the next run can't find the old files by name). dkclean handles .state/.complete/.active after 7 days but does NOT clean .prompt files.

## dkloop Two-Phase Architecture (as of 2026-03-21)

dkloop now runs two sequential Claude sessions: (1) Plan session in --permission-mode plan (no stop hook), (2) Implement session in bypassPermissions with stop hook active. DOYAKEN_SESSION_ID is set for both sessions. Plan interruption exits early and cleans up all state files.

## lib/worktree.sh (added 2026-03-21)

New library providing: dk_wt_branch, dk_wt_remove, dk_cleanup_last_session, dk_cleanup_stale_files. Sourced via common.sh. The header claims "Used by bin scripts (uninit.sh)" but uninit.sh does not call any functions from worktree.sh directly — it uses session.sh functions only. The header is inaccurate for uninit.sh.

## Commit Message Pattern

All commits in this repo use single-word messages ("init", "fix", "rename") — this is the established style.
