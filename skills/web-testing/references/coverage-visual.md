# Coverage & Visual Testing Reference

> Code coverage (v8/istanbul), visual regression (toHaveScreenshot),
> MSW integration, and performance testing.

---

## 1. Coverage: v8 vs istanbul

| Provider | Speed | Accuracy | Best For |
|----------|-------|----------|----------|
| **v8** | Faster | Good (native V8 instrumentation) | Default choice, most projects |
| **istanbul** | Slower | More accurate branch counting | When v8 reports incorrect branch coverage |

### Configuration
```typescript
// vitest.config.ts
coverage: {
  provider: 'v8',
  reporter: ['text', 'json', 'html', 'json-summary'],
  include: ['src/**/*.{ts,tsx}'],
  exclude: [
    'src/**/*.test.ts',
    'src/**/*.d.ts',
    'src/**/types.ts',
    'src/**/constants.ts',
  ],
  thresholds: {
    // Global thresholds
    lines: 80,
    functions: 80,
    branches: 75,
    statements: 80,
    // Per-directory thresholds (stricter for critical paths)
    'src/core/**': {
      lines: 90,
      branches: 85,
    },
  },
  reportOnFailure: true,           // Still report when thresholds fail
}
```

### CI Integration (GitHub Actions)
```yaml
- name: Test with coverage
  run: npx vitest run --coverage

- name: Report coverage
  uses: davelosert/vitest-coverage-report-action@v2
  with:
    json-summary-path: ./coverage/coverage-summary.json
```

### Threshold Strategy
- **Global:** 80% lines/functions/statements, 75% branches (industry baseline)
- **Core modules:** 90%+ (payment, auth, data validation)
- **UI components:** 70-80% (visual logic less testable)
- **Generated code:** Exclude from coverage

## 2. Visual Regression (Playwright `toHaveScreenshot()`)

### Basic Pattern
```typescript
import { test, expect } from '@playwright/test'

test('homepage visual', async ({ page }) => {
  await page.goto('/')
  await expect(page).toHaveScreenshot()       // First run = baseline
})

test('component screenshot', async ({ page }) => {
  await page.goto('/components')
  const card = page.getByTestId('user-card')
  await expect(card).toHaveScreenshot('user-card.png')
})
```

### Advanced Options
```typescript
await expect(page).toHaveScreenshot('dashboard.png', {
  // Tolerance
  maxDiffPixelRatio: 0.01,           // Allow 1% pixel difference
  maxDiffPixels: 100,                // Or max 100 pixels different
  threshold: 0.2,                    // Color difference (0=strict, 1=lax)

  // Stability
  animations: 'disabled',            // Freeze CSS animations
  mask: [                            // Mask dynamic content
    page.locator('.timestamp'),
    page.locator('.avatar'),
    page.locator('.ad-banner'),
  ],

  // Capture
  fullPage: true,
  omitBackground: true,              // Transparent background
})
```

### Baseline Management
- First run creates baselines in `__snapshots__/` or `test-results/`
- Store baselines in Git -- review diffs in PRs
- Generate baselines in CI (Docker) for cross-machine consistency
- Update: `npx playwright test --update-snapshots`

### Disabling Animations Helper
```typescript
export async function prepareForScreenshot(page: Page) {
  await page.addStyleTag({
    content: `
      *, *::before, *::after {
        animation-duration: 0s !important;
        animation-delay: 0s !important;
        transition-duration: 0s !important;
        transition-delay: 0s !important;
      }
    `,
  })
  await page.waitForTimeout(100)
}
```

### Docker for Consistent Baselines
```dockerfile
FROM mcr.microsoft.com/playwright:v1.58.0-noble
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npx playwright test
```

### Best Practices
1. Generate baselines in CI (Docker) for consistent rendering
2. Mask dynamic content (timestamps, avatars, ads, counters)
3. Disable CSS animations before capture
4. Prefer component-level screenshots over full-page (smaller, more precise)
5. Tag visual tests and run on PRs, not every commit
6. Set per-component thresholds (hero = tight, data table = loose)

## 3. MSW (Mock Service Worker) Integration

### Shared Handlers
```typescript
// mocks/handlers.ts (shared between unit tests and browser tests)
import { http, HttpResponse } from 'msw'

export const handlers = [
  http.get('/api/users', () => {
    return HttpResponse.json([
      { id: 1, name: 'Alice' },
      { id: 2, name: 'Bob' },
    ])
  }),

  http.post('/api/users', async ({ request }) => {
    const body = await request.json()
    return HttpResponse.json({ id: 3, ...body }, { status: 201 })
  }),
]
```

### Vitest Integration (Node)
```typescript
// test/setup.ts
import { beforeAll, afterAll, afterEach } from 'vitest'
import { setupServer } from 'msw/node'
import { handlers } from '../mocks/handlers'

const server = setupServer(...handlers)

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }))
afterEach(() => server.resetHandlers())
afterAll(() => server.close())
```

### Vitest Browser Mode Integration
```typescript
// test-extend.ts
import { test as testBase } from 'vitest'
import { worker } from './mocks/browser'

export const test = testBase.extend({
  worker: [
    async ({}, use) => {
      await worker.start({ onUnhandledRequest: 'bypass' })
      await use(worker)
      worker.resetHandlers()
      worker.stop()
    },
    { auto: true },
  ],
})
```

### Playwright Integration (@msw/playwright)
```typescript
import { test } from '@playwright/test'
import { defineNetworkFixture } from '@msw/playwright'

const { use: useNetwork } = defineNetworkFixture(handlers)

test('with MSW', async ({ page }) => {
  await useNetwork(page)
  await page.goto('/users')
  await expect(page.getByText('Alice')).toBeVisible()
})
```

### MSW vs page.route() Decision

| Feature | MSW | page.route() |
|---------|-----|-------------|
| Reusable across unit/E2E | Yes | No (Playwright only) |
| Service Worker interception | Yes (browser) | No |
| Node.js interception | Yes (node) | No |
| GraphQL first-class | Yes | No |
| Zero config | Yes | Yes |
| Playwright-native | No | Yes |
| Performance | Slight overhead | Native, fastest |

**Recommendation:** MSW for shared mocks across test tiers. `page.route()` for Playwright-specific scenarios.

## 4. Performance Testing

### Tools

| What to Measure | Tool | How |
|-----------------|------|-----|
| Core Web Vitals (LCP, CLS, FID) | Chrome DevTools MCP | `lighthouse_audit` tool |
| Bundle size | Vite build analysis | `npx vite-bundle-visualizer` |
| Runtime performance | Chrome DevTools MCP | `performance_start_trace` / `performance_stop_trace` |
| Component render time | Vitest + `performance.now()` | Custom benchmark tests |
| Network waterfall | Playwright | `page.route()` + timing assertions |

### Lighthouse via Chrome DevTools MCP
```
Tool: lighthouse_audit
Input: { "url": "http://localhost:3000", "categories": ["performance"] }
Output: Core Web Vitals scores, suggestions, metrics
```

### Custom Performance Assertion
```typescript
test('component renders under 16ms', async () => {
  const start = performance.now()
  render(<HeavyComponent data={largeDataset} />)
  const duration = performance.now() - start

  expect(duration).toBeLessThan(16)  // 60fps budget
})
```

### Network Timing in Playwright
```typescript
test('API response under 500ms', async ({ page }) => {
  const responsePromise = page.waitForResponse('**/api/data')
  await page.goto('/dashboard')
  const response = await responsePromise

  const timing = response.request().timing()
  expect(timing.responseEnd).toBeLessThan(500)
})
```

---

*Version: 1.0.0 -- Last updated: 2026-03-29*
