# Feature Discovery

## Mindset

- Start with problems, not solutions
- Validate need before building
- Simple solutions beat complex ones
- Consider the whole user journey, not just features

## Discovery Sources

### 1. User Feedback

**Direct Sources:**
- GitHub Issues (feature requests)
- Discussions and Q&A
- Support emails/tickets
- User interviews
- Surveys

**Indirect Sources:**
- How users work around limitations
- Unexpected use cases
- Questions in docs/tutorials
- Social media mentions

### 2. Competitive Intelligence

- Features competitors have that we don't
- Features competitors are adding
- User complaints about competitors
- Gaps in the market

### 3. Industry Trends

- New technologies enabling new capabilities
- Changing user expectations
- Emerging standards and best practices
- Adjacent spaces innovations

### 4. Internal Analysis

- Technical capabilities not exposed to users
- Natural extensions of existing features
- Pain points in our own usage
- Architectural improvements enabling new features

## Prioritization Framework

### Impact vs Effort Matrix

```
              High Impact
                   │
    ┌──────────────┼──────────────┐
    │    QUICK     │   MAJOR      │
    │    WINS      │   PROJECTS   │
    │  Do these!   │   Plan       │
Low ┼──────────────┼──────────────┼ High
Effort│   FILL-INS  │   QUESTION   │ Effort
    │   Maybe      │   Needs more │
    │   later      │   thought    │
    └──────────────┼──────────────┘
                   │
              Low Impact
```

### RICE Scoring

For each feature idea:

- **Reach**: How many users affected? (per quarter)
- **Impact**: How much value? (0.25=minimal, 0.5=low, 1=medium, 2=high, 3=massive)
- **Confidence**: How sure? (100%=high, 80%=medium, 50%=low)
- **Effort**: Person-weeks to build

**RICE Score = (Reach × Impact × Confidence) / Effort**

### Must-Have vs Nice-Have

**Must-Have (P0):**
- Users can't accomplish core jobs without it
- Competitors all have it
- Blocking adoption

**Should-Have (P1):**
- Significantly improves core experience
- Addresses common pain point
- Competitive advantage

**Nice-Have (P2):**
- Convenience/polish
- Edge case support
- Future-proofing

## Feature Specification Template

```
## Feature: [Name]

### Problem Statement
**Who** has this problem: [user segment]
**What** is the problem: [specific pain point]
**Why** does it matter: [impact of not solving]
**Current workaround**: [how users cope today]

### Proposed Solution
**Summary**: [one paragraph description]

**User Stories:**
- As a [user type], I want to [action] so that [benefit]
- As a [user type], I want to [action] so that [benefit]

### Success Criteria
- [ ] [measurable outcome 1]
- [ ] [measurable outcome 2]
- [ ] [measurable outcome 3]

### Scope

**In Scope:**
- [what's included]

**Out of Scope:**
- [what's NOT included - important!]

**Future Considerations:**
- [potential extensions]

### Design Considerations
- UX implications
- API changes
- Configuration needs
- Migration path

### Technical Approach
[High-level implementation strategy]

### Risks & Unknowns
- [risk 1] - Mitigation: [approach]
- [unknown 1] - To investigate: [what to learn]

### Effort Estimate
- Size: S/M/L/XL
- Complexity: Low/Medium/High
- Dependencies: [what this needs first]

### Priority
- RICE Score: [calculated]
- Recommended priority: P0/P1/P2
- Rationale: [why this priority]
```

## Discovery Workshop Agenda

### 1. Problem Space (30 min)
- What are users struggling with?
- What questions do we get repeatedly?
- What are competitors solving that we aren't?

### 2. Ideation (30 min)
- Brainstorm solutions (no filtering)
- Capture all ideas
- Include wild ideas

### 3. Prioritization (30 min)
- Group similar ideas
- Quick impact/effort assessment
- Identify top 3-5 candidates

### 4. Specification (30 min)
- Pick top candidate
- Fill out feature spec template
- Identify unknowns to investigate

## Output: Feature Roadmap

```
## Feature Roadmap

### Now (This Sprint/Month)
| Feature | Priority | Effort | Owner |
|---------|----------|--------|-------|
| [feature] | P0 | S | [who] |

### Next (Next Month/Quarter)
| Feature | Priority | Effort | Owner |
|---------|----------|--------|-------|
| [feature] | P1 | M | TBD |

### Later (This Year)
| Feature | Priority | Effort | Notes |
|---------|----------|--------|-------|
| [feature] | P2 | L | Needs research |

### Ideas Backlog
- [idea 1] - Needs validation
- [idea 2] - Blocked on [dependency]
- [idea 3] - Long-term vision
```

## Red Flags to Watch

- **Solution looking for a problem**: Feature idea with no clear user need
- **Feature creep**: Scope growing without validation
- **Shiny object syndrome**: Building because it's cool, not useful
- **Competitor copycat**: Adding feature just because others have it
- **Over-engineering**: Building flexibility nobody asked for
