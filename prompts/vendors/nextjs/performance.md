# Performance Optimization

Next.js performance best practices and optimization techniques.

## When to Apply

Activate this guide when:
- Optimizing Core Web Vitals
- Reducing bundle size
- Improving initial load time
- Implementing image and font optimization

---

## 1. Bundle Size

### Minimize Client Components

```tsx
// ❌ Entire page becomes client
'use client';

export default function ProductPage() {
  const [selected, setSelected] = useState(null);
  // Everything here ships to client
}

// ✓ Only interactive part is client
export default function ProductPage() {
  return (
    <div>
      <ProductDetails /> {/* Server Component */}
      <ProductSelector /> {/* Client Component */}
    </div>
  );
}
```

### Dynamic Imports

```tsx
import dynamic from 'next/dynamic';

// Load heavy component only when needed
const HeavyChart = dynamic(() => import('@/components/heavy-chart'), {
  loading: () => <ChartSkeleton />,
  ssr: false, // Client-only if needed
});

// Load below the fold
const Comments = dynamic(() => import('@/components/comments'), {
  loading: () => <CommentsSkeleton />,
});
```

### Analyze Bundle

```bash
# Enable bundle analyzer
ANALYZE=true npm run build
```

```js
// next.config.js
const withBundleAnalyzer = require('@next/bundle-analyzer')({
  enabled: process.env.ANALYZE === 'true',
});

module.exports = withBundleAnalyzer({
  // config
});
```

---

## 2. Image Optimization

### Next.js Image Component

```tsx
import Image from 'next/image';

// Automatic optimization
<Image
  src="/hero.jpg"
  alt="Hero image"
  width={1200}
  height={600}
  priority // LCP image
/>

// Fill container
<div className="relative aspect-video">
  <Image
    src="/photo.jpg"
    alt="Photo"
    fill
    className="object-cover"
    sizes="(max-width: 768px) 100vw, 50vw"
  />
</div>

// Remote images
<Image
  src="https://example.com/photo.jpg"
  alt="Remote"
  width={400}
  height={300}
  placeholder="blur"
  blurDataURL="data:image/..." // Base64 placeholder
/>
```

### Image Configuration

```js
// next.config.js
module.exports = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'images.example.com',
      },
    ],
    formats: ['image/avif', 'image/webp'],
    deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048],
    imageSizes: [16, 32, 48, 64, 96, 128, 256],
  },
};
```

---

## 3. Font Optimization

### next/font

```tsx
// app/layout.tsx
import { Inter, JetBrains_Mono } from 'next/font/google';

const inter = Inter({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-inter',
});

const jetbrains = JetBrains_Mono({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-mono',
});

export default function RootLayout({ children }) {
  return (
    <html className={`${inter.variable} ${jetbrains.variable}`}>
      <body className="font-sans">{children}</body>
    </html>
  );
}
```

```css
/* Use with Tailwind */
@tailwind base;

@layer base {
  :root {
    --font-sans: var(--font-inter);
    --font-mono: var(--font-mono);
  }
}
```

### Local Fonts

```tsx
import localFont from 'next/font/local';

const customFont = localFont({
  src: [
    { path: './fonts/Custom-Regular.woff2', weight: '400' },
    { path: './fonts/Custom-Bold.woff2', weight: '700' },
  ],
  variable: '--font-custom',
});
```

---

## 4. Core Web Vitals

### LCP (Largest Contentful Paint)

```tsx
// Prioritize hero image
<Image src="/hero.jpg" priority alt="Hero" />

// Preload critical resources
<link rel="preload" href="/hero.jpg" as="image" />

// Avoid layout shift
<div style={{ aspectRatio: '16/9' }}>
  <Image fill src="/hero.jpg" alt="Hero" />
</div>
```

### CLS (Cumulative Layout Shift)

```tsx
// Reserve space for images
<Image width={800} height={600} src="..." alt="..." />

// Reserve space for dynamic content
<div className="min-h-[200px]">
  <Suspense fallback={<Skeleton height={200} />}>
    <DynamicContent />
  </Suspense>
</div>

// Font display swap
const font = Inter({ display: 'swap' });
```

### INP (Interaction to Next Paint)

```tsx
// Defer non-critical updates
import { useTransition } from 'react';

function FilterList() {
  const [isPending, startTransition] = useTransition();

  function handleFilter(value) {
    startTransition(() => {
      setFilter(value);
    });
  }
}

// Web workers for heavy computation
const worker = new Worker('/heavy-computation.js');
```

---

## 5. Rendering Optimization

### Static Generation

```tsx
// Force static generation
export const dynamic = 'force-static';
export const revalidate = 3600; // ISR: revalidate every hour

export default async function Page() {
  const data = await getData();
  return <Content data={data} />;
}
```

### Streaming

```tsx
import { Suspense } from 'react';

export default function Page() {
  return (
    <div>
      {/* Streams immediately */}
      <Header />

      {/* Streams when ready */}
      <Suspense fallback={<MainSkeleton />}>
        <MainContent />
      </Suspense>

      {/* Streams when ready */}
      <Suspense fallback={<SidebarSkeleton />}>
        <Sidebar />
      </Suspense>
    </div>
  );
}
```

### Partial Prerendering (PPR)

```tsx
// next.config.js
module.exports = {
  experimental: {
    ppr: true,
  },
};

// app/page.tsx
import { Suspense } from 'react';

export default function Page() {
  return (
    <div>
      {/* Static shell */}
      <StaticHeader />

      {/* Dynamic content streams in */}
      <Suspense fallback={<Loading />}>
        <DynamicContent />
      </Suspense>
    </div>
  );
}
```

---

## 6. Caching

### Route Segment Config

```tsx
// Static page
export const dynamic = 'force-static';

// Dynamic page
export const dynamic = 'force-dynamic';

// Revalidation
export const revalidate = 60; // seconds

// Runtime
export const runtime = 'edge'; // or 'nodejs'
```

### Request Memoization

```tsx
// These dedupe automatically in the same render
async function Layout({ children }) {
  const user = await getUser(); // Request 1
  return <div><Nav user={user} />{children}</div>;
}

async function Page() {
  const user = await getUser(); // Memoized, no extra request
  return <Profile user={user} />;
}
```

### Cache Tags

```tsx
async function getPosts() {
  const res = await fetch('https://api.example.com/posts', {
    next: { tags: ['posts'] },
  });
  return res.json();
}

// Revalidate by tag
import { revalidateTag } from 'next/cache';
revalidateTag('posts');
```

---

## 7. Production Checklist

### Build Configuration

```js
// next.config.js
module.exports = {
  output: 'standalone', // Optimized production build

  // Compression
  compress: true,

  // Image optimization
  images: {
    formats: ['image/avif', 'image/webp'],
  },

  // Headers
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
        ],
      },
    ];
  },
};
```

### Performance Budget

```js
// next.config.js
module.exports = {
  experimental: {
    // Warn if page bundle exceeds limits
    largePageDataBytes: 128 * 1024, // 128KB
  },
};
```

## References

- [Optimizing](https://nextjs.org/docs/app/building-your-application/optimizing)
- [Production Checklist](https://nextjs.org/docs/app/guides/production-checklist)
- [Analytics](https://nextjs.org/analytics)
