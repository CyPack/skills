# Vitest Patterns Reference

> Vitest 3.x/4.0 -- unit/component/integration testing patterns.
> Environment: happy-dom (default), jsdom (fallback), Browser Mode (real browser).

---

## 1. Configuration (`vitest.config.ts`)

```typescript
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    // === Environment ===
    globals: true,                     // describe, test, expect without imports
    environment: 'happy-dom',          // 'jsdom' | 'happy-dom' | 'node'
    setupFiles: ['./test/setup.ts'],

    // === File Patterns ===
    include: ['**/*.{test,spec}.{js,ts,jsx,tsx}'],
    exclude: ['**/node_modules/**', '**/dist/**', '**/e2e/**'],

    // === Coverage ===
    coverage: {
      provider: 'v8',                 // 'v8' (faster) | 'istanbul' (more accurate)
      reporter: ['text', 'json', 'html', 'json-summary'],
      include: ['src/**/*.{ts,tsx}'],
      exclude: ['src/**/*.test.ts', 'src/**/*.d.ts', 'src/**/types.ts', 'src/**/constants.ts'],
      thresholds: {
        lines: 80, functions: 80, branches: 75, statements: 80,
        // Per-directory thresholds
        'src/core/**': { lines: 90, branches: 85 },
      },
      reportOnFailure: true,
    },

    // === Performance ===
    pool: 'threads',                   // 'threads' | 'forks' | 'vmThreads'
    poolOptions: { threads: { singleThread: false } },
    testTimeout: 10000,
    hookTimeout: 10000,

    // === Mock Behavior ===
    clearMocks: true,                  // Clear mock.calls between tests
    restoreMocks: true,                // Restore original implementations

    // === Snapshots ===
    snapshotFormat: { printBasicPrototype: false },
  }
})
```

## 2. Environment Decision Matrix

| Environment | Speed | Accuracy | Use When |
|-------------|-------|----------|----------|
| **happy-dom** | Fastest (5-10x jsdom) | 95% API coverage | Default for unit tests |
| **jsdom** | Slower | More complete APIs | Need `getComputedStyle`, complex CSS, `Range` API |
| **node** | N/A | N/A | Pure Node.js logic (no DOM) |
| **Browser Mode** | ~2-3x slower than jsdom | Real browser (100%) | Shadow DOM, CSS custom properties, ResizeObserver, IntersectionObserver |

Per-file override:
```typescript
// @vitest-environment jsdom
import { test, expect } from 'vitest'
```

## 3. Test Patterns

### AAA Pattern (Arrange-Act-Assert)
```typescript
import { describe, it, expect, beforeEach, afterEach } from 'vitest'

describe('Calculator', () => {
  let calc: Calculator

  beforeEach(() => {
    calc = new Calculator()  // Arrange
  })

  afterEach(() => {
    calc.reset()
  })

  it('should add two numbers', () => {
    const result = calc.add(2, 3)  // Act
    expect(result).toBe(5)          // Assert
  })

  it('should throw on division by zero', () => {
    expect(() => calc.divide(1, 0)).toThrow('Division by zero')
  })
})
```

### Async Testing
```typescript
it('should fetch user data', async () => {
  const user = await fetchUser(1)
  expect(user).toEqual({ id: 1, name: 'Alice' })
})

it('should reject on network error', async () => {
  await expect(fetchUser(-1)).rejects.toThrow('Not found')
})
```

### Parameterized Tests (it.each)
```typescript
it.each([
  { a: 1, b: 2, expected: 3 },
  { a: -1, b: 1, expected: 0 },
  { a: 0, b: 0, expected: 0 },
])('add($a, $b) = $expected', ({ a, b, expected }) => {
  expect(add(a, b)).toBe(expected)
})
```

## 4. Mocking

### vi.fn() -- Mock Functions
```typescript
import { vi, expect, test } from 'vitest'

test('mock function basics', () => {
  const mockFn = vi.fn()
  mockFn('hello', 123)
  mockFn('world')

  expect(mockFn).toHaveBeenCalled()
  expect(mockFn).toHaveBeenCalledTimes(2)
  expect(mockFn).toHaveBeenCalledWith('hello', 123)
  expect(mockFn).toHaveBeenLastCalledWith('world')
  expect(mockFn.mock.calls).toEqual([['hello', 123], ['world']])
})

test('mock return values', () => {
  const mockFn = vi.fn()
    .mockReturnValue('default')
    .mockReturnValueOnce('first')
    .mockReturnValueOnce('second')

  expect(mockFn()).toBe('first')
  expect(mockFn()).toBe('second')
  expect(mockFn()).toBe('default')
})

test('async mock', async () => {
  const asyncMock = vi.fn()
    .mockResolvedValue({ data: 'success' })
    .mockResolvedValueOnce({ data: 'first' })

  await expect(asyncMock()).resolves.toEqual({ data: 'first' })
  await expect(asyncMock()).resolves.toEqual({ data: 'success' })
})
```

### vi.spyOn() -- Spy on Existing Methods
```typescript
test('spy preserves original implementation', () => {
  const obj = { add: (a: number, b: number) => a + b }
  const spy = vi.spyOn(obj, 'add')

  expect(obj.add(2, 3)).toBe(5)       // Original runs
  expect(spy).toHaveBeenCalledWith(2, 3)

  spy.mockRestore()                    // Always restore
})

test('spy with override', () => {
  const consoleSpy = vi.spyOn(console, 'log').mockImplementation(() => {})
  console.log('test')
  expect(consoleSpy).toHaveBeenCalledWith('test')
  consoleSpy.mockRestore()
})
```

### vi.mock() -- Module Mocking
```typescript
// IMPORTANT: vi.mock() is HOISTED to top of file, runs before all imports

// Basic module mock
vi.mock('./api', () => ({
  fetchUser: vi.fn(() => Promise.resolve({ id: 1, name: 'Mock User' })),
  fetchPosts: vi.fn(() => Promise.resolve([])),
}))
import { fetchUser, fetchPosts } from './api'

// Partial mock (keep some real exports)
vi.mock('./utils', async (importOriginal) => {
  const actual = await importOriginal()
  return {
    ...actual,
    formatDate: vi.fn(() => '2024-01-01'),
  }
})

// Spy mode (Vitest 3+) -- real implementation but tracked
vi.mock('./calculator', { spy: true })
import { add } from './calculator'

test('spy mode', () => {
  expect(add(1, 2)).toBe(3)           // Real implementation
  expect(add).toHaveBeenCalledWith(1, 2)  // But tracked
})

// Using vi.hoisted for factory scope
const mocks = vi.hoisted(() => ({
  myFn: vi.fn(),
}))
vi.mock('./module', () => ({ myFn: mocks.myFn }))
```

### Automocking with `__mocks__/` Directory
```
src/
  __mocks__/
    api.ts          <- Auto-used when vi.mock('./api') called without factory
  api.ts
__mocks__/
  axios.ts          <- Auto-used when vi.mock('axios') called without factory
```

### Timer Mocking
```typescript
import { vi, beforeEach, afterEach, it, expect } from 'vitest'

beforeEach(() => { vi.useFakeTimers() })
afterEach(() => { vi.useRealTimers() })

it('debounced function', () => {
  const callback = vi.fn()
  const debounced = debounce(callback, 300)

  debounced()
  expect(callback).not.toHaveBeenCalled()

  vi.advanceTimersByTime(300)
  expect(callback).toHaveBeenCalledOnce()
})
```

## 5. Snapshot Testing

### File Snapshots
```typescript
test('renders user card', () => {
  const html = renderToString(<UserCard user={mockUser} />)
  expect(html).toMatchSnapshot()       // Stored in __snapshots__/*.snap
})
```

### Inline Snapshots (preferred for small outputs)
```typescript
test('formats currency', () => {
  expect(formatCurrency(1234.5)).toMatchInlineSnapshot('"$1,234.50"')
})
```

### Custom File Snapshots
```typescript
test('API response schema', async () => {
  const response = await getUsers()
  expect(response).toMatchFileSnapshot('./snapshots/users-response.json')
})
```

### Snapshot Best Practices
- Commit snapshots to git, review in PRs
- Prefer inline snapshots for small outputs (<10 lines)
- Strip dynamic values (IDs, timestamps) with custom serializers
- Keep snapshots small and focused
- Never bulk-update (`vitest -u`) without reviewing each diff

## 6. Coverage

### v8 vs istanbul

| Provider | Speed | Accuracy | Best For |
|----------|-------|----------|----------|
| **v8** | Faster | Good (native V8) | Default choice, most projects |
| **istanbul** | Slower | More accurate branch counting | When v8 reports incorrect branch coverage |

### CI Integration (GitHub Actions)
```yaml
- name: Test with coverage
  run: npx vitest run --coverage

- name: Report coverage
  uses: davelosert/vitest-coverage-report-action@v2
  with:
    json-summary-path: ./coverage/coverage-summary.json
```

## 7. Multi-Project / Monorepo (Vitest 3.2+)

```typescript
// vitest.config.ts (replaces deprecated workspace config)
export default defineConfig({
  test: {
    projects: [
      {
        name: 'unit',
        include: ['src/**/*.test.ts'],
        environment: 'happy-dom',
      },
      {
        name: 'browser',
        include: ['src/**/*.browser.test.ts'],
        browser: {
          enabled: true,
          provider: 'playwright',
          instances: [{ browser: 'chromium' }],
        },
      },
      {
        name: 'api',
        include: ['tests/api/**/*.test.ts'],
        environment: 'node',
      },
    ],
  },
})
```

## 8. React Testing Library Patterns

### Setup
```typescript
// test/setup.ts
import '@testing-library/jest-dom/vitest'
import { cleanup } from '@testing-library/react'
import { afterEach } from 'vitest'

afterEach(() => { cleanup() })
```

### Component Test Pattern
```typescript
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, it, expect } from 'vitest'

describe('Counter', () => {
  it('increments count on click', async () => {
    const user = userEvent.setup()         // Always use .setup()
    render(<Counter initialCount={0} />)

    const button = screen.getByRole('button', { name: /increment/i })
    await user.click(button)

    expect(screen.getByText('Count: 1')).toBeInTheDocument()
  })
})
```

### Query Priority

| Priority | Query | Use When |
|----------|-------|----------|
| 1 (best) | `getByRole` | Interactive elements (buttons, links, inputs) |
| 2 | `getByLabelText` | Form elements |
| 3 | `getByPlaceholderText` | Inputs without visible labels |
| 4 | `getByText` | Non-interactive content |
| 5 | `getByDisplayValue` | Filled form elements |
| 6 | `getByAltText` | Images |
| 7 | `getByTitle` | Title attributes |
| 8 (last) | `getByTestId` | Last resort only |

**Rule:** `getByRole` > `getByLabelText` > `getByText` > `getByTestId`. Always use `userEvent.setup()` over `fireEvent`.

### Async Patterns
```typescript
// Prefer findBy* (uses waitFor internally) over waitFor + getBy
const element = await screen.findByText('Loaded')

// For disappearance
await waitForElementToBeRemoved(() => screen.queryByText('Loading...'))
```

---

*Version: 1.0.0 -- Last updated: 2026-03-29*
