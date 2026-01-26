# React Prompts

React 19+ patterns, hooks, and component architecture best practices.

## Prompts

| Prompt | Description |
|--------|-------------|
| [components.md](components.md) | Component patterns and composition |
| [hooks.md](hooks.md) | React 19 hooks and custom hooks |
| [state-management.md](state-management.md) | State patterns and optimization |

## When to Apply

Use these prompts when:
- Building React applications (any framework)
- Implementing component patterns
- Working with React 19 features
- Optimizing React performance

## React 19 Highlights

### New Hooks
- `useActionState` - Form state management
- `useFormStatus` - Form submission status
- `useOptimistic` - Optimistic UI updates
- `use()` - Read promises and context in render

### Compiler
React Compiler automatically memoizes components, reducing need for manual `useMemo`, `useCallback`, and `memo`.

### Server Components
Render on server, zero client-side JavaScript for non-interactive UI.

## Framework Agnostic

These prompts apply to React regardless of framework:
- Next.js
- Remix
- Vite + React
- Create React App
- Custom setups

For framework-specific patterns, see:
- [Next.js](../nextjs/)
- [Vercel](../vercel/)

## References

- [React Documentation](https://react.dev)
- [React 19 Release](https://react.dev/blog/2024/12/05/react-19)
