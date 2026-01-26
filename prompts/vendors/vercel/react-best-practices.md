# React & Next.js Best Practices

Performance optimization guide with 40+ rules across 8 categories, prioritized by impact.

Based on [Vercel Agent Skills: react-best-practices](https://github.com/vercel-labs/agent-skills).

## When to Apply

Activate this guide when:
- Reviewing React or Next.js code
- Writing new components
- Implementing data fetching
- Optimizing bundle size
- Troubleshooting performance

## Priority Levels

- **CRITICAL**: Address immediately - major performance impact
- **HIGH**: Address soon - significant impact
- **MEDIUM**: Address when convenient - moderate impact
- **LOW**: Nice to have - minor optimization

---

## 1. Data Fetching (CRITICAL)

### Eliminate Waterfalls

```typescript
// BAD: Sequential fetches (waterfall)
const user = await getUser(id);
const posts = await getPosts(user.id);
const comments = await getComments(posts);

// GOOD: Parallel fetches
const [user, posts, comments] = await Promise.all([
  getUser(id),
  getPosts(id),
  getComments(id)
]);
```

### Server Components for Data

```typescript
// GOOD: Fetch in Server Components (Next.js 13+)
// app/users/[id]/page.tsx
export default async function UserPage({ params }) {
  const user = await getUser(params.id); // No client JS
  return <UserProfile user={user} />;
}

// BAD: Fetching in client component with useEffect
'use client'
export default function UserPage({ params }) {
  const [user, setUser] = useState(null);
  useEffect(() => {
    getUser(params.id).then(setUser); // Extra roundtrip
  }, []);
}
```

### Suspense for Streaming

```typescript
// GOOD: Stream UI progressively
export default async function Page() {
  return (
    <>
      <Header /> {/* Renders immediately */}
      <Suspense fallback={<UserSkeleton />}>
        <UserProfile /> {/* Streams when ready */}
      </Suspense>
      <Suspense fallback={<PostsSkeleton />}>
        <UserPosts /> {/* Streams independently */}
      </Suspense>
    </>
  );
}
```

### Cache and Dedupe

```typescript
// GOOD: Use React cache for deduplication
import { cache } from 'react';

export const getUser = cache(async (id: string) => {
  return db.user.findUnique({ where: { id } });
});

// Multiple components can call getUser(id) - only one DB query
```

---

## 2. Bundle Size (CRITICAL)

### Dynamic Imports for Heavy Components

```typescript
// BAD: Static import loads immediately
import HeavyChart from '@/components/HeavyChart';

// GOOD: Load only when needed
import dynamic from 'next/dynamic';

const HeavyChart = dynamic(() => import('@/components/HeavyChart'), {
  loading: () => <ChartSkeleton />,
  ssr: false // Skip SSR if not needed
});
```

### Analyze and Tree-Shake

```bash
# Analyze bundle
ANALYZE=true npm run build

# Check for large dependencies
npx @next/bundle-analyzer
```

### Import What You Need

```typescript
// BAD: Import entire library
import _ from 'lodash';
_.debounce(fn, 300);

// GOOD: Import specific function
import debounce from 'lodash/debounce';
debounce(fn, 300);

// BETTER: Use native or smaller alternatives
import { debounce } from '@/utils/debounce'; // Custom 10-line implementation
```

### Code Splitting by Route

```typescript
// Next.js App Router automatically code-splits by route
// Each page.tsx is a separate chunk

// For shared heavy components, use dynamic import
const AdminDashboard = dynamic(() => import('@/components/AdminDashboard'));
```

---

## 3. Server-Side Performance (HIGH)

### Prefer Server Components

```typescript
// Server Component (default in App Router) - Zero client JS
export default async function ProductList() {
  const products = await db.products.findMany();
  return (
    <ul>
      {products.map(p => <ProductCard key={p.id} product={p} />)}
    </ul>
  );
}

// Only add 'use client' when you need:
// - useState, useEffect, useReducer
// - Event handlers (onClick, onChange, etc.)
// - Browser APIs (window, localStorage)
// - Custom hooks that use any of the above
```

### Server Actions for Mutations

```typescript
// app/actions.ts
'use server'

export async function createPost(formData: FormData) {
  const title = formData.get('title');
  await db.posts.create({ data: { title } });
  revalidatePath('/posts');
}

// app/posts/new/page.tsx
export default function NewPost() {
  return (
    <form action={createPost}>
      <input name="title" />
      <button type="submit">Create</button>
    </form>
  );
}
```

### Edge Runtime for Global Performance

```typescript
// app/api/geo/route.ts
export const runtime = 'edge'; // Run at edge, close to users

export async function GET(request: Request) {
  const country = request.headers.get('x-vercel-ip-country');
  return Response.json({ country });
}
```

---

## 4. Rendering Optimization (HIGH)

### Avoid Unnecessary Re-renders

```typescript
// BAD: New object/function on every render
<Child config={{ theme: 'dark' }} onClick={() => handleClick(id)} />

// GOOD: Memoize objects and callbacks
const config = useMemo(() => ({ theme: 'dark' }), []);
const handleChildClick = useCallback(() => handleClick(id), [id]);
<Child config={config} onClick={handleChildClick} />

// BETTER: Just pass primitives
<Child theme="dark" itemId={id} onClick={handleClick} />
```

### Use React.memo Strategically

```typescript
// Memoize expensive child components
const ExpensiveList = memo(function ExpensiveList({ items }) {
  return items.map(item => <ExpensiveItem key={item.id} item={item} />);
});

// Don't memo everything - only when:
// 1. Component renders often with same props
// 2. Component is expensive to render
// 3. You've measured and confirmed it helps
```

### Keys for Lists

```typescript
// BAD: Index as key (causes issues with reordering)
items.map((item, index) => <Item key={index} item={item} />)

// GOOD: Stable unique ID
items.map(item => <Item key={item.id} item={item} />)
```

---

## 5. State Management (MEDIUM)

### Colocate State

```typescript
// BAD: Global state for local concerns
const [isOpen, setIsOpen] = useGlobalStore(s => s.modalOpen);

// GOOD: Local state for local UI
const [isOpen, setIsOpen] = useState(false);
```

### URL State for Shareable UI

```typescript
// GOOD: Filter state in URL (shareable, back-button works)
// app/products/page.tsx
export default function Products({ searchParams }) {
  const { category, sort } = searchParams;
  return <ProductGrid category={category} sort={sort} />;
}

// Client component updates URL
'use client'
function FilterSelect() {
  const router = useRouter();
  const searchParams = useSearchParams();

  const setCategory = (cat: string) => {
    const params = new URLSearchParams(searchParams);
    params.set('category', cat);
    router.push(`?${params.toString()}`);
  };
}
```

### Server State with React Query/SWR

```typescript
// For client components that need server data
'use client'
import useSWR from 'swr';

export function UserProfile({ userId }) {
  const { data, error, isLoading } = useSWR(
    `/api/users/${userId}`,
    fetcher,
    { revalidateOnFocus: false }
  );

  if (isLoading) return <Skeleton />;
  if (error) return <Error />;
  return <Profile user={data} />;
}
```

---

## 6. Images and Assets (MEDIUM)

### Use next/image

```typescript
import Image from 'next/image';

// GOOD: Automatic optimization
<Image
  src="/hero.jpg"
  alt="Hero image"
  width={1200}
  height={630}
  priority // For LCP images
  placeholder="blur"
  blurDataURL={blurDataUrl}
/>

// For responsive images
<Image
  src="/hero.jpg"
  alt="Hero"
  fill
  sizes="(max-width: 768px) 100vw, 50vw"
  className="object-cover"
/>
```

### Lazy Load Below-the-Fold

```typescript
// Images below the fold lazy load by default
<Image src="/footer-logo.png" alt="Logo" width={100} height={50} />
// loading="lazy" is the default

// Only use priority for above-the-fold LCP images
<Image src="/hero.jpg" alt="Hero" priority />
```

### Preload Critical Assets

```typescript
// app/layout.tsx
export const metadata = {
  // Preload critical fonts
};

// For critical images, use priority prop
// For critical scripts, use next/script with strategy="beforeInteractive"
```

---

## 7. JavaScript Performance (LOW)

### Avoid Expensive Operations in Render

```typescript
// BAD: Filter on every render
function ProductList({ products, category }) {
  const filtered = products.filter(p => p.category === category);
  return filtered.map(p => <Product key={p.id} product={p} />);
}

// GOOD: Memoize expensive computations
function ProductList({ products, category }) {
  const filtered = useMemo(
    () => products.filter(p => p.category === category),
    [products, category]
  );
  return filtered.map(p => <Product key={p.id} product={p} />);
}

// BETTER: Filter on server before sending to client
```

### Debounce Expensive Handlers

```typescript
'use client'
import { useDebouncedCallback } from 'use-debounce';

function SearchInput() {
  const handleSearch = useDebouncedCallback((query: string) => {
    router.push(`/search?q=${query}`);
  }, 300);

  return <input onChange={e => handleSearch(e.target.value)} />;
}
```

### Virtualize Long Lists

```typescript
import { useVirtualizer } from '@tanstack/react-virtual';

function VirtualList({ items }) {
  const parentRef = useRef<HTMLDivElement>(null);

  const virtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 50,
  });

  return (
    <div ref={parentRef} style={{ height: 400, overflow: 'auto' }}>
      <div style={{ height: virtualizer.getTotalSize() }}>
        {virtualizer.getVirtualItems().map(virtualItem => (
          <div
            key={virtualItem.key}
            style={{
              position: 'absolute',
              top: virtualItem.start,
              height: virtualItem.size,
            }}
          >
            {items[virtualItem.index].name}
          </div>
        ))}
      </div>
    </div>
  );
}
```

---

## 8. Build and Deploy (LOW)

### Environment-Specific Configs

```typescript
// next.config.js
module.exports = {
  images: {
    domains: process.env.NODE_ENV === 'production'
      ? ['cdn.example.com']
      : ['localhost'],
  },
};
```

### ISR for Semi-Static Content

```typescript
// app/products/[id]/page.tsx
export const revalidate = 3600; // Revalidate every hour

export default async function ProductPage({ params }) {
  const product = await getProduct(params.id);
  return <ProductDetails product={product} />;
}

// Or on-demand revalidation
// app/api/revalidate/route.ts
export async function POST(request: Request) {
  const { path, secret } = await request.json();
  if (secret !== process.env.REVALIDATE_SECRET) {
    return Response.json({ error: 'Invalid secret' }, { status: 401 });
  }
  revalidatePath(path);
  return Response.json({ revalidated: true });
}
```

---

## Quick Reference Checklist

### Before Code Review

- [ ] No fetch waterfalls (use Promise.all or parallel Server Components)
- [ ] Heavy components use dynamic import
- [ ] Server Components used where possible (no unnecessary 'use client')
- [ ] Images use next/image with proper sizing
- [ ] Long lists are virtualized
- [ ] State is colocated (not over-globalized)
- [ ] Keys are stable unique IDs (not array indices)

### Performance Audit

```bash
# Lighthouse
npx lighthouse https://your-site.vercel.app

# Bundle analysis
ANALYZE=true npm run build

# Check for large dependencies
npx depcheck
```

## References

- [Next.js Performance](https://nextjs.org/docs/pages/building-your-application/optimizing)
- [React Performance](https://react.dev/learn/render-and-commit)
- [Vercel Analytics](https://vercel.com/analytics)
- [Web Vitals](https://web.dev/vitals/)
