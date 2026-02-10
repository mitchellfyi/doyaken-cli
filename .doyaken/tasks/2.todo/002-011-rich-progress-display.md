# Task: Rich Progress Display and Status Bar

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `002-011-rich-progress-display`                        |
| Status      | `todo`                                                 |
| Priority    | `002` High                                             |
| Created     | `2026-02-06 15:30`                                     |
| Started     |                                                        |
| Completed   |                                                        |
| Blocked By  | 001-007                                                |
| Blocks      |                                                        |
| Assigned To |                                                        |
| Assigned At |                                                        |

---

## Context

Doyaken's current progress display is basic text output. Competitors like OpenCode, Gemini CLI, and Codex have rich terminal UIs with status bars, phase indicators, and real-time updates. While a full TUI (like Bubble Tea) is out of scope for a bash tool, we can significantly improve the display.

## Objective

Enhance the terminal output with a persistent status line, phase progress indicator, and better formatting for agent interactions.

## Requirements

### Status Line (Bottom Bar)
1. Persistent bottom line showing:
   - Current task ID and title (truncated)
   - Current phase with progress (e.g., `IMPLEMENT [3/8]`)
   - Timer (elapsed time for current phase)
   - Model name
   - Token/cost estimate (if available from agent output)
2. Update in-place using ANSI escape codes (no scrolling)
3. Configurable: `--no-status-line` to disable

### Phase Progress
1. Show phase pipeline with completion status:
   ```
   EXPAND ✓ → TRIAGE ✓ → PLAN ● → IMPLEMENT ○ → TEST ○ → DOCS ○ → REVIEW ○ → VERIFY ○
   ```
2. Update in real-time as phases complete
3. Show skip indicators for skipped phases

### Agent Output Formatting
1. In interactive mode, format agent responses with:
   - Syntax highlighting for code blocks (use `bat` or `pygmentize` if available, else raw)
   - Distinct styling for agent text vs tool use vs errors
   - Collapsible tool use details (show summary, expand with `/details`)
2. Markdown rendering: bold, italic, headers, lists (basic ANSI formatting)

### Notification
1. Desktop notification when task completes (use `osascript` on macOS, `notify-send` on Linux)
2. Terminal bell on completion (configurable)
3. Sound notification option (configurable, off by default)

### Configuration
```yaml
# .doyaken/manifest.yaml
display:
  status_line: true
  phase_progress: true
  syntax_highlight: auto  # auto | always | never
  notifications: true
  bell: false
```

## Technical Notes

- Status line: use `tput sc` (save cursor), `tput rc` (restore cursor), `tput cup` for positioning
- Alternative: use `\033[s` and `\033[u` ANSI sequences
- Must handle terminal resize (SIGWINCH handler)
- Don't break piped output — detect TTY before using ANSI codes
- Consider `gum` (charmbracelet) for styled output if available

## Success Criteria

- [ ] Persistent status line shows task, phase, timer
- [ ] Phase pipeline indicator updates in real-time
- [ ] Code blocks in agent output have syntax highlighting (when tools available)
- [ ] Desktop notification on task completion
- [ ] Display degrades gracefully in non-TTY (piped) mode
- [ ] Status line disabled with `--no-status-line`
