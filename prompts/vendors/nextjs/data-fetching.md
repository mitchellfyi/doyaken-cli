# Data Fetching Patterns

Server-side data fetching in Next.js App Router.

## When to Apply

Activate this guide when:
- Fetching data in Server Components
- Implementing caching strategies
- Handling loading and error states
- Optimizing data fetching patterns

---

## 1. Server Component Fetching

### Direct Database Access

```tsx
// app/products/page.tsx
import { db } from '@/lib/db';

export default async function ProductsPage() {
  const products = await db.products.findMany({
    orderBy: { createdAt: 'desc' },
  });

  return (
    <ul>
      {products.map((product) => (
        <li key={product.id}>{product.name}</li>
      ))}
    </ul>
  );
}
```

### API Fetching

```tsx
async function getProducts() {
  const res = await fetch('https://api.example.com/products', {
    next: { revalidate: 3600 }, // Cache for 1 hour
  });

  if (!res.ok) throw new Error('Failed to fetch');

  return res.json();
}

export default async function ProductsPage() {
  const products = await getProducts();
  return <ProductList products={products} />;
}
```

---

## 2. Caching Strategies

### Static (Default)

```tsx
// Cached at build time, revalidated on deploy
async function getData() {
  const res = await fetch('https://api.example.com/data');
  return res.json();
}
```

### Time-Based Revalidation

```tsx
// Revalidate every hour
async function getData() {
  const res = await fetch('https://api.example.com/data', {
    next: { revalidate: 3600 },
  });
  return res.json();
}
```

### On-Demand Revalidation

```tsx
// app/api/revalidate/route.ts
import { revalidatePath, revalidateTag } from 'next/cache';

export async function POST(request: Request) {
  const { path, tag } = await request.json();

  if (path) {
    revalidatePath(path);
  }

  if (tag) {
    revalidateTag(tag);
  }

  return Response.json({ revalidated: true });
}
```

### No Cache (Dynamic)

```tsx
// Always fetch fresh data
async function getData() {
  const res = await fetch('https://api.example.com/data', {
    cache: 'no-store',
  });
  return res.json();
}
```

---

## 3. Parallel Data Fetching

### Concurrent Requests

```tsx
export default async function Dashboard() {
  // Start all requests in parallel
  const [user, posts, analytics] = await Promise.all([
    getUser(),
    getPosts(),
    getAnalytics(),
  ]);

  return (
    <div>
      <UserProfile user={user} />
      <PostsList posts={posts} />
      <AnalyticsChart data={analytics} />
    </div>
  );
}
```

### With Suspense Boundaries

```tsx
import { Suspense } from 'react';

export default function Dashboard() {
  return (
    <div>
      <Suspense fallback={<UserSkeleton />}>
        <UserProfile />
      </Suspense>

      <Suspense fallback={<PostsSkeleton />}>
        <PostsList />
      </Suspense>

      <Suspense fallback={<AnalyticsSkeleton />}>
        <AnalyticsChart />
      </Suspense>
    </div>
  );
}
```

---

## 4. Loading States

### Route-Level Loading

```tsx
// app/products/loading.tsx
export default function Loading() {
  return (
    <div className="grid grid-cols-3 gap-4">
      {[...Array(6)].map((_, i) => (
        <div key={i} className="animate-pulse">
          <div className="bg-gray-200 h-48 rounded-lg" />
          <div className="bg-gray-200 h-4 mt-4 rounded" />
        </div>
      ))}
    </div>
  );
}
```

### Component-Level Loading

```tsx
import { Suspense } from 'react';

export default function ProductPage() {
  return (
    <div>
      <h1>Product Details</h1>

      <Suspense fallback={<ProductDetailsSkeleton />}>
        <ProductDetails />
      </Suspense>

      <Suspense fallback={<ReviewsSkeleton />}>
        <ProductReviews />
      </Suspense>
    </div>
  );
}
```

---

## 5. Error Handling

### Route-Level Error Boundary

```tsx
'use client';

// app/products/error.tsx
export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div className="text-center py-12">
      <h2>Something went wrong!</h2>
      <p className="text-gray-500">{error.message}</p>
      <button
        onClick={reset}
        className="mt-4 px-4 py-2 bg-blue-500 text-white rounded"
      >
        Try again
      </button>
    </div>
  );
}
```

### Graceful Degradation

```tsx
async function getOptionalData() {
  try {
    const res = await fetch('https://api.example.com/optional');
    if (!res.ok) return null;
    return res.json();
  } catch {
    return null;
  }
}

export default async function Page() {
  const optionalData = await getOptionalData();

  return (
    <div>
      {optionalData ? (
        <OptionalSection data={optionalData} />
      ) : (
        <FallbackSection />
      )}
    </div>
  );
}
```

---

## 6. Server Actions

### Form Handling

```tsx
// app/actions.ts
'use server';

import { revalidatePath } from 'next/cache';

export async function createPost(formData: FormData) {
  const title = formData.get('title') as string;
  const content = formData.get('content') as string;

  await db.posts.create({
    data: { title, content },
  });

  revalidatePath('/posts');
}
```

```tsx
// app/posts/new/page.tsx
import { createPost } from '@/app/actions';

export default function NewPost() {
  return (
    <form action={createPost}>
      <input name="title" required />
      <textarea name="content" required />
      <button type="submit">Create Post</button>
    </form>
  );
}
```

### With Client State

```tsx
'use client';

import { useActionState } from 'react';
import { createPost } from '@/app/actions';

export function PostForm() {
  const [state, formAction, isPending] = useActionState(
    createPost,
    { error: null }
  );

  return (
    <form action={formAction}>
      <input name="title" required />
      {state.error && <p className="error">{state.error}</p>}
      <button disabled={isPending}>
        {isPending ? 'Creating...' : 'Create Post'}
      </button>
    </form>
  );
}
```

---

## 7. Patterns to Avoid

### Waterfall Fetching

```tsx
// ❌ Bad: Sequential fetches
export default async function Page() {
  const user = await getUser();         // Wait
  const posts = await getPosts(user.id); // Then wait
  const comments = await getComments();  // Then wait
}

// ✓ Good: Parallel fetches
export default async function Page() {
  const userPromise = getUser();
  const postsPromise = getPosts();
  const commentsPromise = getComments();

  const [user, posts, comments] = await Promise.all([
    userPromise, postsPromise, commentsPromise
  ]);
}
```

### Client-Side Fetching (When Server Works)

```tsx
// ❌ Avoid: Client-side fetch for static data
'use client';
function Products() {
  const [products, setProducts] = useState([]);
  useEffect(() => {
    fetch('/api/products').then(r => r.json()).then(setProducts);
  }, []);
}

// ✓ Better: Server Component
async function Products() {
  const products = await db.products.findMany();
  return <ProductList products={products} />;
}
```

## References

- [Data Fetching](https://nextjs.org/docs/app/building-your-application/data-fetching)
- [Caching](https://nextjs.org/docs/app/building-your-application/caching)
- [Server Actions](https://nextjs.org/docs/app/building-your-application/data-fetching/server-actions-and-mutations)
