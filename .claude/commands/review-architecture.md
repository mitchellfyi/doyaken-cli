---
description: Apply review-architecture methodology
---

# Architecture Review

## Mindset

- Think about maintainability over 2-5 years
- Consider team scalability - can new developers onboard easily?
- Balance flexibility with simplicity - don't over-engineer
- Respect existing patterns unless there's a compelling reason to change

## Architecture Assessment

### 1. High-Level Structure

- [ ] Clear separation of concerns (UI, business logic, data)
- [ ] Consistent layering (controllers, services, repositories)
- [ ] Appropriate modularization (not too monolithic, not too fragmented)
- [ ] Clear module boundaries and interfaces
- [ ] Dependencies flow in one direction (no circular dependencies)

### 2. Design Patterns

- [ ] Patterns used appropriately (not forced)
- [ ] Consistent patterns throughout codebase
- [ ] Patterns documented or self-evident
- [ ] No anti-patterns (god objects, spaghetti code, golden hammer)

### 3. Coupling & Cohesion

**Low Coupling (Good):**
- [ ] Modules can be changed independently
- [ ] Interfaces are stable and minimal
- [ ] No hidden dependencies or global state
- [ ] External dependencies are abstracted

**High Cohesion (Good):**
- [ ] Related code is grouped together
- [ ] Each module has a single, clear purpose
- [ ] Functions/methods do one thing well
- [ ] No feature envy (code using other modules' data excessively)

### 4. Scalability Considerations

- [ ] Stateless where possible (horizontal scaling)
- [ ] Data access patterns support growth
- [ ] No obvious bottlenecks for 10x-100x scale
- [ ] Caching strategy exists where appropriate
- [ ] Async/background processing for heavy operations

### 5. Configuration & Environments

- [ ] Environment-specific config is externalized
- [ ] Feature flags for gradual rollouts
- [ ] Secrets management strategy
- [ ] Build/deploy configuration is maintainable

## Common Architecture Smells

### Monolith Smells
- Deployment requires redeploying everything
- One change affects unrelated features
- Test suite takes forever
- Different teams blocked by same codebase

### Over-Engineering Smells
- Abstractions with only one implementation
- Excessive interfaces/protocols
- Complex dependency injection for simple apps
- Microservices where a monolith would suffice

### Under-Engineering Smells
- Business logic in controllers/handlers
- SQL queries scattered throughout codebase
- No separation between internal and external interfaces
- Duplicated logic across modules

## Assessment Template

```
## Architecture Review Summary

### Overview
- Project type: [web app, CLI, library, API, etc.]
- Primary language: [language]
- Size: [lines of code, number of modules]
- Team size context: [solo, small team, large team]

### Structure Analysis

| Aspect | Rating | Notes |
|--------|--------|-------|
| Separation of concerns | Good/Fair/Poor | |
| Module boundaries | Good/Fair/Poor | |
| Dependency management | Good/Fair/Poor | |
| Consistency | Good/Fair/Poor | |
| Scalability readiness | Good/Fair/Poor | |

### Strengths
1. [what's working well]
2. [good patterns observed]
3. [solid design decisions]

### Concerns
1. [architectural issue] - Impact: [high/medium/low]
2. [coupling/cohesion issue] - Impact: [high/medium/low]
3. [scalability concern] - Impact: [high/medium/low]

### Recommendations

**Immediate (Technical Debt)**
- [quick wins, clear fixes]

**Short-term (Next Quarter)**
- [moderate refactoring]

**Long-term (Strategic)**
- [larger architectural changes]

### Diagram (if helpful)
[ASCII diagram of current vs recommended structure]
```

## Questions to Answer

1. **Can a new developer understand the codebase in a day?**
2. **Can features be added without touching unrelated code?**
3. **Can modules be tested in isolation?**
4. **Can the system scale to 10x current load?**
5. **Can parts of the system be replaced without rewriting everything?**

---

Apply this methodology to the current context. If given a specific file or code, analyze it according to these guidelines.
