# Issue Triage Prompt

You are triaging and implementing a GitHub issue.

## Environment Setup

Before running any project-specific commands (tests, linters, builds), set up the environment:

1. **Detect the project type** by checking for config files (package.json, Gemfile, requirements.txt, go.mod, Cargo.toml, etc.)
2. **Install dependencies** using the appropriate package manager
3. **Check for setup scripts** (.tool-versions, .nvmrc, Dockerfile, docker-compose.yml)

Common setups:
- **Node.js**: `npm ci` or `yarn install`
- **Ruby**: Install Ruby version if needed, then `bundle install`
- **Python**: `pip install -r requirements.txt` or `poetry install`
- **Go**: Dependencies auto-install on build

If a tool isn't available, install it or skip that step and note it.

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
   - Run relevant tests/linters to verify (set up environment first)
   - Commit with a descriptive message
   - Push the branch
   - Create a draft PR linking to the issue with "Fixes #{ISSUE_NUMBER}" in the body

4. **If not implementable** (needs clarification, question, too complex):
   - Just comment with your analysis and any questions

Use `gh` CLI for GitHub operations. The repo is already checked out.
