# Project

> Replace this with your project's description and goals.

## Vision

What is this project trying to achieve? What problem does it solve?

## Goals

1. **Primary Goal**: The main objective
2. **Secondary Goal**: Supporting objectives
3. **Quality Goal**: Maintain high code quality through automated checks and best practices

## Non-Goals

Things explicitly out of scope:

- Not trying to do X
- Won't support Y

## Tech Stack

- **Language**:
- **Framework**:
- **Database**:
- **Testing**:

## Getting Started

```bash
# Install dependencies
npm install

# Run tests
npm test

# Start development
npm run dev
```

## Key Decisions

Important architectural or design decisions:

1. **Decision 1**: Why we chose X over Y
2. **Decision 2**: Why we structured it this way

## Quality Standards

This project enforces quality through automated checks:

### Required Quality Gates
- **Lint**: All code passes linter checks
- **Type Check**: All code passes type checking
- **Tests**: All tests pass with adequate coverage
- **Build**: Project builds successfully
- **Security Audit**: No high/critical vulnerabilities

### Code Quality Principles
- **KISS**: Keep solutions simple and straightforward
- **YAGNI**: Don't build features until needed
- **DRY**: Avoid duplication, single source of truth
- **SOLID**: Follow SOLID principles for maintainable code

### Quality Commands
```bash
npm run lint        # Check code style
npm run typecheck   # Check types
npm run test        # Run tests
npm run build       # Build project
npm audit           # Security audit
```

## Agent Notes

Things the agent should know when working on this project:

- Follow existing code patterns and conventions
- All code must pass quality gates before commit
- Keep changes minimal and focused
- Write tests for new functionality
