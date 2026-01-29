---
name: notify-slack
description: Send a notification to Slack about task progress
requires:
  - slack
args:
  - name: channel
    description: Slack channel to post to
    required: true
  - name: message
    description: Custom message (optional, auto-generates if not provided)
  - name: type
    description: Notification type (progress, complete, error)
    default: "progress"
---

# Slack Notification

You are sending a Slack notification about task progress.

## Context

Project directory: {{DOYAKEN_PROJECT}}
Channel: {{ARGS.channel}}
Notification type: {{ARGS.type}}
Custom message: {{ARGS.message}}

## Instructions

1. **Gather Project Status**
   - Count tasks in each state (blocked, todo, doing, done)
   - Get recent completions (last 24h)
   - Get current in-progress tasks

2. **Build Notification Message**

   If custom message provided, use it. Otherwise, generate based on type:

   **Progress** (type=progress):
   ```
   📊 *Doyaken Progress Update*

   *Project:* project-name

   *Tasks:*
   • Blocked: N
   • Todo: N
   • In Progress: N
   • Done: N

   *Currently Working On:*
   • task-title-1
   • task-title-2
   ```

   **Completion** (type=complete):
   ```
   ✅ *Task Completed*

   *Project:* project-name
   *Task:* task-title

   Summary of what was done...

   *Commits:* N commits
   *Files changed:* N files
   ```

   **Error** (type=error):
   ```
   ⚠️ *Doyaken Alert*

   *Project:* project-name
   *Issue:* Description of error...

   *Details:*
   Error details...
   ```

3. **Send to Slack**
   Use Slack MCP to post to the specified channel.

4. **Confirm Delivery**
   Report success or failure.

## Output Format

```
Slack Notification Sent
=======================
Channel: #channel-name
Type: progress
Message ID: xxxxx
```

## Rules

- Ensure channel exists before posting
- Use appropriate emoji for notification type
- Keep messages concise but informative
- Include project name for context
