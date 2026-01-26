# State Management

React state patterns and optimization techniques.

## When to Apply

Activate this guide when:
- Choosing state management approach
- Optimizing re-renders
- Managing complex application state
- Sharing state between components

---

## 1. State Placement

### Decision Tree

```
Does state need to be shared?
├── No → useState in component
└── Yes → How many components need it?
    ├── 2-3 nearby → Lift state up
    └── Many/distant → Context or external store
```

### Local State (useState)

```tsx
// Isolated component state
function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(c => c + 1)}>{count}</button>;
}
```

### Lifted State

```tsx
// Parent owns shared state
function Parent() {
  const [selected, setSelected] = useState<string | null>(null);

  return (
    <div>
      <ItemList selected={selected} onSelect={setSelected} />
      <ItemDetails itemId={selected} />
    </div>
  );
}
```

### Context

```tsx
// Distant components need same data
const UserContext = createContext<User | null>(null);

function App() {
  const [user, setUser] = useState<User | null>(null);

  return (
    <UserContext.Provider value={user}>
      <Header />    {/* Uses user */}
      <Main />
      <Sidebar />   {/* Uses user */}
    </UserContext.Provider>
  );
}
```

---

## 2. useReducer for Complex State

### Basic Reducer

```tsx
interface State {
  count: number;
  step: number;
}

type Action =
  | { type: 'increment' }
  | { type: 'decrement' }
  | { type: 'setStep'; payload: number }
  | { type: 'reset' };

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'increment':
      return { ...state, count: state.count + state.step };
    case 'decrement':
      return { ...state, count: state.count - state.step };
    case 'setStep':
      return { ...state, step: action.payload };
    case 'reset':
      return { count: 0, step: 1 };
    default:
      return state;
  }
}

function Counter() {
  const [state, dispatch] = useReducer(reducer, { count: 0, step: 1 });

  return (
    <div>
      <p>Count: {state.count}</p>
      <button onClick={() => dispatch({ type: 'increment' })}>+</button>
      <button onClick={() => dispatch({ type: 'decrement' })}>-</button>
      <input
        type="number"
        value={state.step}
        onChange={(e) =>
          dispatch({ type: 'setStep', payload: Number(e.target.value) })
        }
      />
    </div>
  );
}
```

### With Context

```tsx
interface AppState {
  user: User | null;
  theme: 'light' | 'dark';
  notifications: Notification[];
}

type AppAction =
  | { type: 'setUser'; payload: User | null }
  | { type: 'toggleTheme' }
  | { type: 'addNotification'; payload: Notification }
  | { type: 'removeNotification'; payload: string };

const AppContext = createContext<{
  state: AppState;
  dispatch: React.Dispatch<AppAction>;
} | null>(null);

function AppProvider({ children }: { children: React.ReactNode }) {
  const [state, dispatch] = useReducer(appReducer, initialState);

  return (
    <AppContext.Provider value={{ state, dispatch }}>
      {children}
    </AppContext.Provider>
  );
}

function useApp() {
  const context = useContext(AppContext);
  if (!context) throw new Error('useApp must be used within AppProvider');
  return context;
}
```

---

## 3. Context Optimization

### Split Contexts

```tsx
// ❌ One big context - all consumers re-render
const AppContext = createContext({ user, theme, cart, notifications });

// ✓ Split by update frequency
const UserContext = createContext<User | null>(null);
const ThemeContext = createContext<Theme>('light');
const CartContext = createContext<Cart>({ items: [] });

// Components only subscribe to what they need
function Header() {
  const user = useContext(UserContext); // Only re-renders on user change
  return <nav>{user?.name}</nav>;
}
```

### Memoize Context Value

```tsx
function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [theme, setTheme] = useState<'light' | 'dark'>('light');

  // ✓ Memoize to prevent unnecessary re-renders
  const value = useMemo(
    () => ({ theme, setTheme }),
    [theme]
  );

  return (
    <ThemeContext.Provider value={value}>
      {children}
    </ThemeContext.Provider>
  );
}
```

### Separate State and Actions

```tsx
const StateContext = createContext<State | null>(null);
const DispatchContext = createContext<Dispatch | null>(null);

function Provider({ children }) {
  const [state, dispatch] = useReducer(reducer, initialState);

  return (
    <StateContext.Provider value={state}>
      <DispatchContext.Provider value={dispatch}>
        {children}
      </DispatchContext.Provider>
    </StateContext.Provider>
  );
}

// Components that only dispatch don't re-render on state changes
function AddButton() {
  const dispatch = useContext(DispatchContext)!;
  return <button onClick={() => dispatch({ type: 'add' })}>Add</button>;
}
```

---

## 4. Render Optimization

### React.memo

```tsx
// Prevent re-render if props unchanged
const ExpensiveList = memo(function ExpensiveList({
  items,
}: {
  items: Item[];
}) {
  return (
    <ul>
      {items.map((item) => (
        <ExpensiveItem key={item.id} item={item} />
      ))}
    </ul>
  );
});

// Custom comparison
const MemoizedComponent = memo(Component, (prevProps, nextProps) => {
  return prevProps.id === nextProps.id;
});
```

### Stable References

```tsx
function Parent() {
  const [count, setCount] = useState(0);

  // ✗ New function every render
  const handleClick = () => console.log(count);

  // ✓ Stable reference
  const handleClickStable = useCallback(() => {
    console.log(count);
  }, [count]);

  return <MemoizedChild onClick={handleClickStable} />;
}
```

### Children Pattern

```tsx
// ✓ Children don't re-render when Parent state changes
function SlowComponent() {
  // Expensive render...
}

function Parent({ children }: { children: React.ReactNode }) {
  const [count, setCount] = useState(0);

  return (
    <div>
      <button onClick={() => setCount(c => c + 1)}>{count}</button>
      {children} {/* SlowComponent doesn't re-render! */}
    </div>
  );
}

// Usage
<Parent>
  <SlowComponent />
</Parent>
```

---

## 5. Server State vs Client State

### Separation

```tsx
// Server State: Data from API (use React Query, SWR, etc.)
// - Cached
// - Can be stale
// - Needs revalidation

// Client State: UI state (use useState, useReducer)
// - Never stale
// - Synchronous
// - Local to session

function ProductPage({ productId }: { productId: string }) {
  // Server state
  const { data: product, isLoading } = useQuery({
    queryKey: ['product', productId],
    queryFn: () => fetchProduct(productId),
  });

  // Client state
  const [selectedSize, setSelectedSize] = useState<string | null>(null);
  const [quantity, setQuantity] = useState(1);

  if (isLoading) return <Skeleton />;

  return (
    <div>
      <h1>{product.name}</h1>
      <SizeSelector
        sizes={product.sizes}
        selected={selectedSize}
        onSelect={setSelectedSize}
      />
      <QuantityInput value={quantity} onChange={setQuantity} />
    </div>
  );
}
```

---

## 6. Form State

### React 19 Forms

```tsx
'use client';

import { useActionState, useFormStatus } from 'react-dom';

async function submitForm(prevState: FormState, formData: FormData) {
  // Validate and submit
  const name = formData.get('name');
  if (!name) return { error: 'Name required' };

  await saveData({ name });
  return { success: true };
}

function Form() {
  const [state, action, isPending] = useActionState(submitForm, {});

  return (
    <form action={action}>
      <input name="name" />
      {state.error && <p className="error">{state.error}</p>}
      <SubmitButton />
    </form>
  );
}

function SubmitButton() {
  const { pending } = useFormStatus();
  return (
    <button disabled={pending}>
      {pending ? 'Saving...' : 'Save'}
    </button>
  );
}
```

### Complex Form State

```tsx
interface FormData {
  personal: { name: string; email: string };
  address: { street: string; city: string };
  preferences: { newsletter: boolean };
}

type FormAction =
  | { type: 'updatePersonal'; field: keyof FormData['personal']; value: string }
  | { type: 'updateAddress'; field: keyof FormData['address']; value: string }
  | { type: 'toggleNewsletter' };

function formReducer(state: FormData, action: FormAction): FormData {
  switch (action.type) {
    case 'updatePersonal':
      return {
        ...state,
        personal: { ...state.personal, [action.field]: action.value },
      };
    case 'updateAddress':
      return {
        ...state,
        address: { ...state.address, [action.field]: action.value },
      };
    case 'toggleNewsletter':
      return {
        ...state,
        preferences: { newsletter: !state.preferences.newsletter },
      };
    default:
      return state;
  }
}
```

## References

- [Managing State](https://react.dev/learn/managing-state)
- [useReducer](https://react.dev/reference/react/useReducer)
- [Context](https://react.dev/reference/react/useContext)
