IMPORTANT: Follow these steps in order. Use the ticket tracker configured in doyaken.md § Integrations. If no tracker is configured, skip tracker steps.

1. Gather ticket context from the configured ticket tracker:

   - Read ticket {{TICKET_NUM}} — title, description, acceptance criteria, relations, and comments.
   - If the tracker supports assignees: check the assignee. If assigned to someone else, STOP and warn. If unassigned, assign to yourself.
   - If no tracker is configured: use the branch name `{{BRANCH}}` and the local filesystem for context. Ask the user what they want to work on.

2. Rename the branch and create a draft PR:

   **If ticket context was found**:
   - Rename to match the ticket's suggested branch name:
     ```
     git branch -m {{BRANCH}} <suggested-branch-name>
     git push -u origin <suggested-branch-name>
     gh pr create --draft --title "<type>(<scope>): <ticket-title>" --body "<ticket-url>"
     ```

   **If no ticket context**:
   - Keep the current branch name `{{BRANCH}}`.
   - Push and create a draft PR using the branch name as the title:
     ```
     git push -u origin {{BRANCH}}
     gh pr create --draft --title "<type>(<scope>): <description from user>" --body ""
     ```

3. Set the ticket status to "In Progress" via the configured tracker. If no tracker, skip.

4. Check the ticket description (if a ticket was found):
   - If the description is empty, unclear, or missing acceptance criteria:
     a. Read related issues, comments, and explore the relevant code.
     b. Draft a short description (2-3 sentences) and acceptance criteria checklist.
     c. Present to the user for review.
     d. Once confirmed, update the ticket via the configured tracker.
   - If clear, skip to step 5.

5. Read the relevant AGENTS.md or README.md for the areas of code involved. Explore the codebase to understand scope and context.

6. Summarise your understanding and confirm you are ready to work.
