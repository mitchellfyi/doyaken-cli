# App Router Patterns

Next.js App Router conventions and best practices.

## When to Apply

Activate this guide when:
- Creating new Next.js routes and pages
- Organizing App Router file structure
- Implementing layouts and templates
- Working with route groups and parallel routes

---

## 1. File Conventions

### Core Files

| File | Purpose |
|------|---------|
| `page.tsx` | Route UI (required for route to be accessible) |
| `layout.tsx` | Shared UI, preserves state |
| `template.tsx` | Shared UI, re-renders on navigation |
| `loading.tsx` | Loading UI with Suspense |
| `error.tsx` | Error boundary |
| `not-found.tsx` | 404 UI |
| `route.ts` | API endpoint |

### Directory Structure

```
app/
├── layout.tsx           # Root layout
├── page.tsx             # Home page (/)
├── loading.tsx          # Global loading
├── error.tsx            # Global error
├── not-found.tsx        # Global 404
│
├── (marketing)/         # Route group (no URL segment)
│   ├── layout.tsx       # Marketing layout
│   ├── about/
│   │   └── page.tsx     # /about
│   └── pricing/
│       └── page.tsx     # /pricing
│
├── (app)/               # Route group
│   ├── layout.tsx       # App layout (with auth)
│   ├── dashboard/
│   │   ├── page.tsx     # /dashboard
│   │   └── loading.tsx  # Dashboard loading
│   └── settings/
│       └── page.tsx     # /settings
│
├── blog/
│   ├── page.tsx         # /blog (list)
│   └── [slug]/
│       └── page.tsx     # /blog/:slug
│
└── api/
    └── route.ts         # /api
```

---

## 2. Layouts

### Root Layout (Required)

```tsx
// app/layout.tsx
import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: {
    template: '%s | My App',
    default: 'My App',
  },
  description: 'App description',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        {children}
      </body>
    </html>
  );
}
```

### Nested Layouts

```tsx
// app/(app)/layout.tsx
import { Sidebar } from '@/components/sidebar';
import { Header } from '@/components/header';

export default function AppLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="flex h-screen">
      <Sidebar />
      <div className="flex-1 flex flex-col">
        <Header />
        <main className="flex-1 overflow-auto p-6">
          {children}
        </main>
      </div>
    </div>
  );
}
```

---

## 3. Server vs Client Components

### Server Components (Default)

```tsx
// No directive needed - this is a Server Component
import { db } from '@/lib/db';

async function ProductList() {
  const products = await db.products.findMany();

  return (
    <ul>
      {products.map((product) => (
        <li key={product.id}>{product.name}</li>
      ))}
    </ul>
  );
}
```

### Client Components

```tsx
'use client';

import { useState } from 'react';

export function Counter() {
  const [count, setCount] = useState(0);

  return (
    <button onClick={() => setCount(count + 1)}>
      Count: {count}
    </button>
  );
}
```

### Composition Pattern

```tsx
// Server Component (parent)
import { db } from '@/lib/db';
import { ProductFilter } from './product-filter'; // Client

async function ProductPage() {
  const products = await db.products.findMany();

  return (
    <div>
      {/* Client component for interactivity */}
      <ProductFilter />

      {/* Server component for data display */}
      <ProductList products={products} />
    </div>
  );
}
```

---

## 4. Dynamic Routes

### Basic Dynamic Route

```tsx
// app/blog/[slug]/page.tsx
interface Props {
  params: Promise<{ slug: string }>;
}

export default async function BlogPost({ params }: Props) {
  const { slug } = await params;
  const post = await getPost(slug);

  return <article>{post.content}</article>;
}

// Generate static paths
export async function generateStaticParams() {
  const posts = await getPosts();
  return posts.map((post) => ({ slug: post.slug }));
}
```

### Catch-All Routes

```tsx
// app/docs/[...slug]/page.tsx
interface Props {
  params: Promise<{ slug: string[] }>;
}

export default async function DocsPage({ params }: Props) {
  const { slug } = await params;
  // slug = ['getting-started', 'installation']
  // URL: /docs/getting-started/installation
}
```

---

## 5. Route Groups

### Organizing by Feature

```
app/
├── (auth)/
│   ├── layout.tsx      # Auth pages layout
│   ├── login/
│   └── register/
├── (dashboard)/
│   ├── layout.tsx      # Dashboard layout
│   ├── overview/
│   └── analytics/
└── (marketing)/
    ├── layout.tsx      # Marketing layout
    ├── page.tsx        # Home
    └── pricing/
```

### Multiple Root Layouts

```tsx
// app/(marketing)/layout.tsx
export default function MarketingLayout({ children }) {
  return (
    <html lang="en">
      <body>
        <MarketingNav />
        {children}
        <MarketingFooter />
      </body>
    </html>
  );
}

// app/(app)/layout.tsx
export default function AppLayout({ children }) {
  return (
    <html lang="en">
      <body>
        <AppSidebar />
        {children}
      </body>
    </html>
  );
}
```

---

## 6. Parallel Routes

### Dashboard with Modals

```
app/
├── @modal/
│   ├── default.tsx
│   └── (.)photo/[id]/
│       └── page.tsx    # Intercepted photo modal
├── layout.tsx
└── page.tsx
```

```tsx
// app/layout.tsx
export default function Layout({
  children,
  modal,
}: {
  children: React.ReactNode;
  modal: React.ReactNode;
}) {
  return (
    <>
      {children}
      {modal}
    </>
  );
}
```

---

## 7. Metadata

### Static Metadata

```tsx
export const metadata: Metadata = {
  title: 'Page Title',
  description: 'Page description',
  openGraph: {
    title: 'Page Title',
    description: 'Page description',
    images: ['/og-image.png'],
  },
};
```

### Dynamic Metadata

```tsx
export async function generateMetadata({
  params,
}: Props): Promise<Metadata> {
  const { slug } = await params;
  const post = await getPost(slug);

  return {
    title: post.title,
    description: post.excerpt,
    openGraph: {
      images: [post.coverImage],
    },
  };
}
```

## References

- [App Router](https://nextjs.org/docs/app)
- [Routing Fundamentals](https://nextjs.org/docs/app/building-your-application/routing)
- [Server Components](https://nextjs.org/docs/app/building-your-application/rendering/server-components)
