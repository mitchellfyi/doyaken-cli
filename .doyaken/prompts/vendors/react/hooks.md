# React Hooks

React 19 hooks and custom hook patterns.

## When to Apply

Activate this guide when:
- Using React 19 new hooks
- Building custom hooks
- Optimizing hook usage
- Working with forms and async state

---

## 1. React 19 New Hooks

### useActionState

Replaces useFormState with clearer semantics:

```tsx
'use client';

import { useActionState } from 'react';

interface FormState {
  error: string | null;
  success: boolean;
}

async function submitForm(
  prevState: FormState,
  formData: FormData
): Promise<FormState> {
  const email = formData.get('email') as string;

  if (!email.includes('@')) {
    return { error: 'Invalid email', success: false };
  }

  await saveEmail(email);
  return { error: null, success: true };
}

function Newsletter() {
  const [state, formAction, isPending] = useActionState(submitForm, {
    error: null,
    success: false,
  });

  return (
    <form action={formAction}>
      <input name="email" type="email" required />
      {state.error && <p className="error">{state.error}</p>}
      {state.success && <p className="success">Subscribed!</p>}
      <button type="submit" disabled={isPending}>
        {isPending ? 'Subscribing...' : 'Subscribe'}
      </button>
    </form>
  );
}
```

### useFormStatus

Access form submission status from child components:

```tsx
'use client';

import { useFormStatus } from 'react-dom';

function SubmitButton() {
  const { pending } = useFormStatus();

  return (
    <button type="submit" disabled={pending}>
      {pending ? 'Submitting...' : 'Submit'}
    </button>
  );
}

// Must be used inside a <form>
function ContactForm() {
  return (
    <form action={submitContact}>
      <input name="message" />
      <SubmitButton /> {/* Gets form status */}
    </form>
  );
}
```

### useOptimistic

Show optimistic UI updates:

```tsx
'use client';

import { useOptimistic } from 'react';

interface Message {
  id: string;
  text: string;
  sending?: boolean;
}

function Chat({ messages }: { messages: Message[] }) {
  const [optimisticMessages, addOptimisticMessage] = useOptimistic(
    messages,
    (state, newMessage: string) => [
      ...state,
      { id: crypto.randomUUID(), text: newMessage, sending: true },
    ]
  );

  async function sendMessage(formData: FormData) {
    const text = formData.get('text') as string;
    addOptimisticMessage(text);
    await sendToServer(text);
  }

  return (
    <div>
      {optimisticMessages.map((msg) => (
        <div key={msg.id} className={msg.sending ? 'opacity-50' : ''}>
          {msg.text}
        </div>
      ))}
      <form action={sendMessage}>
        <input name="text" />
        <button type="submit">Send</button>
      </form>
    </div>
  );
}
```

### use()

Read promises and context in render:

```tsx
import { use, Suspense } from 'react';

// Read a promise
function Comments({ commentsPromise }: { commentsPromise: Promise<Comment[]> }) {
  const comments = use(commentsPromise);
  return (
    <ul>
      {comments.map((c) => (
        <li key={c.id}>{c.text}</li>
      ))}
    </ul>
  );
}

// Usage with Suspense
function Post({ postId }: { postId: string }) {
  const commentsPromise = fetchComments(postId);

  return (
    <article>
      <PostContent id={postId} />
      <Suspense fallback={<CommentsSkeleton />}>
        <Comments commentsPromise={commentsPromise} />
      </Suspense>
    </article>
  );
}

// Read context conditionally
function Theme({ isActive }: { isActive: boolean }) {
  if (isActive) {
    const theme = use(ThemeContext); // OK in React 19!
    return <div style={{ color: theme.primary }}>Active</div>;
  }
  return <div>Inactive</div>;
}
```

---

## 2. Core Hooks

### useState

```tsx
// Simple state
const [count, setCount] = useState(0);

// Lazy initialization (expensive computation)
const [data, setData] = useState(() => computeInitialData());

// Functional updates
setCount((prev) => prev + 1);

// Object state (spread required)
const [user, setUser] = useState({ name: '', email: '' });
setUser((prev) => ({ ...prev, name: 'New Name' }));
```

### useEffect

```tsx
// Run after every render
useEffect(() => {
  console.log('Rendered');
});

// Run once on mount
useEffect(() => {
  console.log('Mounted');
}, []);

// Run when dependencies change
useEffect(() => {
  document.title = `Count: ${count}`;
}, [count]);

// Cleanup
useEffect(() => {
  const handler = () => {};
  window.addEventListener('resize', handler);
  return () => window.removeEventListener('resize', handler);
}, []);
```

### useRef

```tsx
// DOM reference
const inputRef = useRef<HTMLInputElement>(null);

function focusInput() {
  inputRef.current?.focus();
}

// Mutable value (no re-render)
const renderCount = useRef(0);
renderCount.current++; // Doesn't trigger re-render

// Previous value
function usePrevious<T>(value: T): T | undefined {
  const ref = useRef<T>();
  useEffect(() => {
    ref.current = value;
  }, [value]);
  return ref.current;
}
```

### useCallback & useMemo

```tsx
// Memoize function (stable reference)
const handleClick = useCallback(() => {
  doSomething(id);
}, [id]);

// Memoize computation
const expensiveValue = useMemo(() => {
  return computeExpensiveValue(data);
}, [data]);

// Note: React 19 Compiler often handles this automatically
```

---

## 3. Custom Hooks

### Data Fetching

```tsx
function useFetch<T>(url: string) {
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<Error | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const controller = new AbortController();

    async function fetchData() {
      try {
        setIsLoading(true);
        const res = await fetch(url, { signal: controller.signal });
        if (!res.ok) throw new Error('Fetch failed');
        const json = await res.json();
        setData(json);
        setError(null);
      } catch (err) {
        if (err instanceof Error && err.name !== 'AbortError') {
          setError(err);
        }
      } finally {
        setIsLoading(false);
      }
    }

    fetchData();
    return () => controller.abort();
  }, [url]);

  return { data, error, isLoading };
}

// Usage
function UserProfile({ userId }: { userId: string }) {
  const { data: user, error, isLoading } = useFetch<User>(`/api/users/${userId}`);

  if (isLoading) return <Spinner />;
  if (error) return <Error message={error.message} />;
  return <Profile user={user!} />;
}
```

### Local Storage

```tsx
function useLocalStorage<T>(key: string, initialValue: T) {
  const [storedValue, setStoredValue] = useState<T>(() => {
    if (typeof window === 'undefined') return initialValue;

    try {
      const item = window.localStorage.getItem(key);
      return item ? JSON.parse(item) : initialValue;
    } catch {
      return initialValue;
    }
  });

  const setValue = (value: T | ((val: T) => T)) => {
    const valueToStore = value instanceof Function ? value(storedValue) : value;
    setStoredValue(valueToStore);
    window.localStorage.setItem(key, JSON.stringify(valueToStore));
  };

  return [storedValue, setValue] as const;
}

// Usage
const [theme, setTheme] = useLocalStorage('theme', 'light');
```

### Debounce

```tsx
function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState(value);

  useEffect(() => {
    const timer = setTimeout(() => setDebouncedValue(value), delay);
    return () => clearTimeout(timer);
  }, [value, delay]);

  return debouncedValue;
}

// Usage
function Search() {
  const [query, setQuery] = useState('');
  const debouncedQuery = useDebounce(query, 300);

  useEffect(() => {
    if (debouncedQuery) {
      searchAPI(debouncedQuery);
    }
  }, [debouncedQuery]);
}
```

### Media Query

```tsx
function useMediaQuery(query: string): boolean {
  const [matches, setMatches] = useState(false);

  useEffect(() => {
    const mediaQuery = window.matchMedia(query);
    setMatches(mediaQuery.matches);

    const handler = (e: MediaQueryListEvent) => setMatches(e.matches);
    mediaQuery.addEventListener('change', handler);
    return () => mediaQuery.removeEventListener('change', handler);
  }, [query]);

  return matches;
}

// Usage
const isMobile = useMediaQuery('(max-width: 768px)');
```

---

## 4. Hook Rules

### Rules of Hooks

```tsx
// ✓ Call at top level
function Component() {
  const [state, setState] = useState(0);
  useEffect(() => {}, []);
}

// ✗ Don't call conditionally
function Component({ condition }) {
  if (condition) {
    const [state, setState] = useState(0); // Error!
  }
}

// ✗ Don't call in loops
function Component({ items }) {
  items.forEach((item) => {
    const [state, setState] = useState(0); // Error!
  });
}

// ✗ Don't call in nested functions
function Component() {
  function handleClick() {
    const [state, setState] = useState(0); // Error!
  }
}
```

### Custom Hook Conventions

```tsx
// ✓ Start with "use"
function useCustomHook() {}

// ✓ Return consistent shape
function useToggle(initial = false) {
  const [value, setValue] = useState(initial);
  const toggle = useCallback(() => setValue((v) => !v), []);
  return [value, toggle] as const;
}

// ✓ Accept dependencies
function useInterval(callback: () => void, delay: number | null) {
  const savedCallback = useRef(callback);

  useEffect(() => {
    savedCallback.current = callback;
  }, [callback]);

  useEffect(() => {
    if (delay === null) return;
    const id = setInterval(() => savedCallback.current(), delay);
    return () => clearInterval(id);
  }, [delay]);
}
```

## References

- [React Hooks](https://react.dev/reference/react/hooks)
- [React 19 Hooks](https://react.dev/blog/2024/12/05/react-19)
- [Custom Hooks](https://react.dev/learn/reusing-logic-with-custom-hooks)
