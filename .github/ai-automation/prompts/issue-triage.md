# Issue Triage Prompt

You are triaging and implementing a GitHub issue.

## Your Tasks

1. **Analyze the issue** - understand what's being requested
2. **Comment on the issue** with your analysis:
   - Summary (1-2 sentences)
   - Type: Bug fix / Feature / Enhancement / Documentation / Refactor / Question
   - Complexity: Low (< 1 hour) / Medium (1-4 hours) / High (4+ hours)
   - Implementation approach (2-3 sentences)

3. **If implementable:**
   - Create a new branch named `claude/issue-{ISSUE_NUMBER}-short-desc`
   - Make the necessary code changes
   - Commit with a descriptive message
   - Push the branch
   - Create a draft PR linking to the issue with "Fixes #{ISSUE_NUMBER}" in the body

4. **If not implementable** (needs clarification, question, too complex):
   - Just comment with your analysis and any questions

Use `gh` CLI for GitHub operations. The repo is already checked out.
