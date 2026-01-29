# Component Patterns

React component design patterns and composition techniques.

## When to Apply

Activate this guide when:
- Designing component architecture
- Building reusable component libraries
- Refactoring complex components
- Implementing design patterns

---

## 1. Component Composition

### Children Pattern

```tsx
// Flexible container component
interface CardProps {
  children: React.ReactNode;
  className?: string;
}

function Card({ children, className }: CardProps) {
  return (
    <div className={cn('rounded-lg border p-4', className)}>
      {children}
    </div>
  );
}

// Usage
<Card>
  <h2>Title</h2>
  <p>Content</p>
</Card>
```

### Compound Components

```tsx
// Components that work together
interface TabsContextValue {
  activeTab: string;
  setActiveTab: (id: string) => void;
}

const TabsContext = createContext<TabsContextValue | null>(null);

function Tabs({ children, defaultValue }: TabsProps) {
  const [activeTab, setActiveTab] = useState(defaultValue);

  return (
    <TabsContext.Provider value={{ activeTab, setActiveTab }}>
      <div className="tabs">{children}</div>
    </TabsContext.Provider>
  );
}

function TabsList({ children }: { children: React.ReactNode }) {
  return <div className="tabs-list" role="tablist">{children}</div>;
}

function Tab({ value, children }: TabProps) {
  const { activeTab, setActiveTab } = useContext(TabsContext)!;

  return (
    <button
      role="tab"
      aria-selected={activeTab === value}
      onClick={() => setActiveTab(value)}
    >
      {children}
    </button>
  );
}

function TabPanel({ value, children }: TabPanelProps) {
  const { activeTab } = useContext(TabsContext)!;
  if (activeTab !== value) return null;

  return <div role="tabpanel">{children}</div>;
}

// Attach sub-components
Tabs.List = TabsList;
Tabs.Tab = Tab;
Tabs.Panel = TabPanel;

// Usage
<Tabs defaultValue="tab1">
  <Tabs.List>
    <Tabs.Tab value="tab1">Tab 1</Tabs.Tab>
    <Tabs.Tab value="tab2">Tab 2</Tabs.Tab>
  </Tabs.List>
  <Tabs.Panel value="tab1">Content 1</Tabs.Panel>
  <Tabs.Panel value="tab2">Content 2</Tabs.Panel>
</Tabs>
```

### Render Props

```tsx
interface MouseTrackerProps {
  children: (position: { x: number; y: number }) => React.ReactNode;
}

function MouseTracker({ children }: MouseTrackerProps) {
  const [position, setPosition] = useState({ x: 0, y: 0 });

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      setPosition({ x: e.clientX, y: e.clientY });
    };
    window.addEventListener('mousemove', handler);
    return () => window.removeEventListener('mousemove', handler);
  }, []);

  return <>{children(position)}</>;
}

// Usage
<MouseTracker>
  {({ x, y }) => (
    <div>Mouse: {x}, {y}</div>
  )}
</MouseTracker>
```

---

## 2. Props Patterns

### Discriminated Unions

```tsx
// Props that vary based on a type
type ButtonProps =
  | { variant: 'link'; href: string; onClick?: never }
  | { variant: 'button'; onClick: () => void; href?: never };

function Button(props: ButtonProps) {
  if (props.variant === 'link') {
    return <a href={props.href}>Link</a>;
  }
  return <button onClick={props.onClick}>Button</button>;
}
```

### Polymorphic Components

```tsx
type PolymorphicProps<E extends React.ElementType> = {
  as?: E;
  children: React.ReactNode;
} & Omit<React.ComponentPropsWithoutRef<E>, 'as' | 'children'>;

function Text<E extends React.ElementType = 'span'>({
  as,
  children,
  ...props
}: PolymorphicProps<E>) {
  const Component = as || 'span';
  return <Component {...props}>{children}</Component>;
}

// Usage
<Text>Default span</Text>
<Text as="p">Paragraph</Text>
<Text as="h1" className="text-3xl">Heading</Text>
<Text as="a" href="/link">Link</Text>
```

### Slots Pattern

```tsx
interface DialogProps {
  children: React.ReactNode;
  trigger: React.ReactNode;
  title: React.ReactNode;
  description?: React.ReactNode;
  actions?: React.ReactNode;
}

function Dialog({ trigger, title, description, actions, children }: DialogProps) {
  const [open, setOpen] = useState(false);

  return (
    <>
      <span onClick={() => setOpen(true)}>{trigger}</span>
      {open && (
        <div className="dialog">
          <div className="dialog-header">
            <h2>{title}</h2>
            {description && <p>{description}</p>}
          </div>
          <div className="dialog-content">{children}</div>
          {actions && <div className="dialog-actions">{actions}</div>}
        </div>
      )}
    </>
  );
}

// Usage
<Dialog
  trigger={<Button>Open</Button>}
  title="Confirm Action"
  description="Are you sure?"
  actions={
    <>
      <Button variant="ghost">Cancel</Button>
      <Button variant="primary">Confirm</Button>
    </>
  }
>
  <p>Dialog content here</p>
</Dialog>
```

---

## 3. Component Organization

### Feature-Based Structure

```
src/
├── features/
│   ├── auth/
│   │   ├── components/
│   │   │   ├── LoginForm.tsx
│   │   │   └── SignupForm.tsx
│   │   ├── hooks/
│   │   │   └── useAuth.ts
│   │   ├── api/
│   │   │   └── auth.ts
│   │   └── index.ts
│   └── products/
│       ├── components/
│       ├── hooks/
│       └── index.ts
├── components/          # Shared components
│   ├── ui/
│   │   ├── Button.tsx
│   │   ├── Input.tsx
│   │   └── index.ts
│   └── layout/
│       ├── Header.tsx
│       └── Footer.tsx
├── hooks/               # Shared hooks
└── lib/                 # Utilities
```

### Component File Structure

```tsx
// ProductCard.tsx

// 1. Imports
import { useState } from 'react';
import { formatPrice } from '@/lib/utils';
import { Button } from '@/components/ui';

// 2. Types
interface ProductCardProps {
  product: Product;
  onAddToCart: (id: string) => void;
}

// 3. Component
export function ProductCard({ product, onAddToCart }: ProductCardProps) {
  // Hooks
  const [isHovered, setIsHovered] = useState(false);

  // Handlers
  const handleAddToCart = () => {
    onAddToCart(product.id);
  };

  // Render
  return (
    <div
      className="product-card"
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
    >
      <img src={product.image} alt={product.name} />
      <h3>{product.name}</h3>
      <p>{formatPrice(product.price)}</p>
      <Button onClick={handleAddToCart}>Add to Cart</Button>
    </div>
  );
}
```

---

## 4. Controlled vs Uncontrolled

### Controlled Component

```tsx
interface InputProps {
  value: string;
  onChange: (value: string) => void;
}

function ControlledInput({ value, onChange }: InputProps) {
  return (
    <input
      value={value}
      onChange={(e) => onChange(e.target.value)}
    />
  );
}

// Parent controls state
function Form() {
  const [email, setEmail] = useState('');
  return <ControlledInput value={email} onChange={setEmail} />;
}
```

### Uncontrolled Component

```tsx
interface InputProps {
  defaultValue?: string;
  name: string;
}

function UncontrolledInput({ defaultValue, name }: InputProps) {
  return <input defaultValue={defaultValue} name={name} />;
}

// Form accesses via FormData
function Form() {
  const handleSubmit = (e: FormEvent) => {
    const formData = new FormData(e.currentTarget);
    const email = formData.get('email');
  };

  return (
    <form onSubmit={handleSubmit}>
      <UncontrolledInput name="email" defaultValue="" />
    </form>
  );
}
```

### Hybrid (Supports Both)

```tsx
interface InputProps {
  value?: string;
  defaultValue?: string;
  onChange?: (value: string) => void;
}

function Input({ value, defaultValue, onChange }: InputProps) {
  const isControlled = value !== undefined;

  if (isControlled) {
    return (
      <input
        value={value}
        onChange={(e) => onChange?.(e.target.value)}
      />
    );
  }

  return <input defaultValue={defaultValue} />;
}
```

---

## 5. Error Boundaries

```tsx
'use client'; // Required for error boundaries

import { Component, ErrorInfo, ReactNode } from 'react';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error?: Error;
}

class ErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false };

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('Error caught:', error, errorInfo);
    // Report to error tracking service
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback || (
        <div className="error-boundary">
          <h2>Something went wrong</h2>
          <button onClick={() => this.setState({ hasError: false })}>
            Try again
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}

// Usage
<ErrorBoundary fallback={<ErrorFallback />}>
  <RiskyComponent />
</ErrorBoundary>
```

## References

- [React Patterns](https://react.dev/learn/passing-data-deeply-with-context)
- [Compound Components](https://www.patterns.dev/react/compound-pattern)
- [Composition vs Inheritance](https://react.dev/learn/thinking-in-react)
