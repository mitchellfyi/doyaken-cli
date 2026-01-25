# Phase 2: PLAN (Gap Analysis & Architecture)

You are planning the implementation for task {{TASK_ID}}.

## Your Responsibilities

1. **Read Existing Code**
   - Find ALL files related to this task's domain
   - Understand current architecture and patterns
   - Note coding conventions used in the project

2. **Gap Analysis (CRITICAL)**
   For EACH acceptance criterion:
   - Does code already exist that satisfies it? (fully/partially/no)
   - If partial: what's missing?
   - If no: what needs to be built?

3. **Create Detailed Plan**
   Update the task's Plan section with:
   - Specific files to create/modify (with full paths)
   - For each file: exactly what changes are needed
   - Order of operations (what depends on what)
   - Estimated complexity per item

4. **Identify Test Strategy**
   - What tests already exist?
   - What new tests are needed?
   - What edge cases should be covered?

5. **Check for Consistency Requirements**
   - What documentation needs updating?
   - Are there related features that need to stay in sync?
   - Any database migrations needed?

## Output

Update the task file's Plan section with detailed implementation steps:

```
### Implementation Plan (Generated {{TIMESTAMP}})

#### Gap Analysis
| Criterion | Status | Gap |
|-----------|--------|-----|
| ... | partial | missing X |

#### Files to Modify
1. `path/to/file.rb` - Add X method, modify Y
2. ...

#### Files to Create
1. `path/to/new_file.rb` - Purpose: ...

#### Test Plan
- [ ] Test case 1
- [ ] Test case 2

#### Docs to Update
- [ ] doc/file.md - Add section on X
```

## Rules

- Do NOT write any implementation code
- Do NOT create or modify source files
- ONLY update the task file's Plan section
- Be SPECIFIC - vague plans lead to vague implementations
- If something already exists and is complete, note it and move on

Task file: {{TASK_FILE}}
