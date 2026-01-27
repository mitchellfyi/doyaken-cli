---
description: Apply research-competitors methodology
---

# Competitor Analysis

## Mindset

- Learn from competitors, don't copy blindly
- Features aren't everything - consider UX, docs, community
- Find gaps and differentiation opportunities
- Understand why competitors made their choices

## Research Process

### 1. Identify Competitors

**Direct Competitors:**
- Same problem, same solution approach
- Same target audience
- Would be compared in purchasing decisions

**Indirect Competitors:**
- Same problem, different approach
- Adjacent problem space
- DIY/manual alternatives

**Sources to Find Competitors:**
- GitHub searches for similar projects
- "Awesome" lists (awesome-xyz)
- Product Hunt / Hacker News
- Google searches for the problem
- Stack Overflow alternatives discussions
- Reddit communities

### 2. Feature Comparison

For each competitor, document:

```
## [Competitor Name]

**Overview:**
- URL: [link]
- GitHub: [link] / Stars: [count]
- License: [license]
- Last updated: [date]
- Maturity: [early/stable/mature/declining]

**Core Features:**
- [feature 1]
- [feature 2]
- [feature 3]

**Unique/Notable:**
- [what makes it different]

**Weaknesses:**
- [limitation 1]
- [limitation 2]

**Target Audience:**
- [who uses this]

**Pricing/Model:**
- [free/freemium/paid/open source]
```

### 3. Feature Matrix

```
| Feature | Us | Comp A | Comp B | Comp C |
|---------|-----|--------|--------|--------|
| Feature 1 | ✅ | ✅ | ❌ | ✅ |
| Feature 2 | ❌ | ✅ | ✅ | ❌ |
| Feature 3 | ✅ | ❌ | ✅ | ✅ |
| ...      | ... | ... | ... | ... |

Legend:
✅ = Has feature
❌ = Missing
🔶 = Partial/Limited
⭐ = Best-in-class
```

### 4. Qualitative Assessment

**User Experience:**
- How easy is initial setup?
- How intuitive is daily use?
- How good are error messages?
- How responsive is the team?

**Documentation:**
- Getting started guide quality
- API/reference documentation
- Examples and tutorials
- Community resources

**Community & Support:**
- GitHub issues responsiveness
- Discord/Slack activity
- Stack Overflow presence
- Blog/updates frequency

**Technical:**
- Performance
- Reliability
- Extensibility
- Code quality (if open source)

## Analysis Template

```
## Competitor Analysis Report

### Executive Summary

**Market Landscape:**
[Brief overview of the competitive space]

**Key Competitors:**
1. [Competitor A] - [one-line description]
2. [Competitor B] - [one-line description]
3. [Competitor C] - [one-line description]

**Our Position:**
[Where we fit in the landscape]

---

### Detailed Competitor Profiles

[Include profile for each competitor using template above]

---

### Feature Comparison Matrix

[Include matrix from above]

---

### Competitive Analysis

**Their Strengths We Should Learn From:**
1. [Competitor X does Y really well because...]
2. [Competitor Y's approach to Z is worth considering...]

**Gaps We Can Exploit:**
1. [Nobody does X well - opportunity]
2. [All competitors ignore Y use case]
3. [Common complaint about Z - we can solve]

**Features for Parity:**
[Features we MUST have to be considered viable]
- [feature] - [why critical]

**Features for Differentiation:**
[Features that would set us apart]
- [feature] - [competitive advantage]

---

### Recommendations

**Must Have (Competitive Parity):**
1. [feature] - All major competitors have this
2. [feature] - Users expect this

**Should Have (Catch Up):**
1. [feature] - Competitors doing better
2. [improvement] - Common complaint about us

**Nice to Have (Differentiation):**
1. [feature] - Would set us apart
2. [approach] - Novel solution to common problem

**Strategic Bets:**
1. [big idea] - High risk, high reward
```

## Questions to Answer

1. **Why would someone choose a competitor over us?**
2. **Why would someone choose us over competitors?**
3. **What's the #1 feature request competitors aren't addressing?**
4. **What's everyone doing wrong that we could do better?**
5. **Is there an underserved segment of users?**

## Research Tips

- Star/watch competitor repos to track updates
- Read their GitHub issues for pain points
- Check their changelog for direction
- Read reviews and discussions about them
- Try actually using them, not just reading about them
- Talk to users who switched away from them

---

Apply this methodology to the current context. If given a specific file or code, analyze it according to these guidelines.
