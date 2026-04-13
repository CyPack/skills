# Component Testing Reference

> Testing components in isolation: Vitest + happy-dom (fastest), jsdom (fallback),
> Browser Mode (real browser), and Playwright experimental CT.
> Testing Library query priority: getByRole > getByLabelText > getByText > getByTestId

---

## 1. Decision Matrix (2026)

| Approach | Speed | Accuracy | Framework | Status |
|----------|-------|----------|-----------|--------|
| **Vitest + happy-dom** | Fastest | 95% DOM fidelity | React/Vue/Svelte | Production-ready, recommended |
| **Vitest + jsdom** | Fast | 98% DOM fidelity | React/Vue/Svelte | Mature, fallback for complex APIs |
| **Vitest Browser Mode** | Medium | 100% (real browser) | React/Vue/Svelte | Stable in Vitest 4.0 |
| **@playwright/experimental-ct-react** | Slowest | 100% (real browser) | React | Still experimental |

**Recommendation:** Vitest + happy-dom for most component tests. Vitest Browser Mode when you need real browser APIs (Shadow DOM, CSS custom properties, ResizeObserver, IntersectionObserver). Playwright for E2E only.

## 2. Vitest + happy-dom (Default)

### Setup
```typescript
// test/setup.ts
import '@testing-library/jest-dom/vitest'
import { cleanup } from '@testing-library/react'
import { afterEach } from 'vitest'

afterEach(() => {
  cleanup()
})
```

### vitest.config.ts
```typescript
export default defineConfig({
  test: {
    globals: true,
    environment: 'happy-dom',
    setupFiles: ['./test/setup.ts'],
  }
})
```

### Component Test Pattern
```typescript
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, it, expect } from 'vitest'
import { Counter } from './Counter'

describe('Counter', () => {
  it('increments count on click', async () => {
    const user = userEvent.setup()         // Always use .setup()
    render(<Counter initialCount={0} />)

    const button = screen.getByRole('button', { name: /increment/i })
    await user.click(button)

    expect(screen.getByText('Count: 1')).toBeInTheDocument()
  })

  it('calls onChange when value changes', async () => {
    const user = userEvent.setup()
    const onChange = vi.fn()
    render(<Counter initialCount={0} onChange={onChange} />)

    await user.click(screen.getByRole('button', { name: /increment/i }))

    expect(onChange).toHaveBeenCalledWith(1)
  })
})
```

## 3. Vitest + jsdom (Fallback)

Use when happy-dom lacks APIs you need:
- `getComputedStyle()` (complex CSS)
- `Range` API
- `MutationObserver` edge cases
- Third-party libs with jsdom-specific assumptions

Per-file override:
```typescript
// @vitest-environment jsdom
import { test, expect } from 'vitest'
```

Or project-level:
```typescript
export default defineConfig({
  test: {
    environment: 'jsdom',
  }
})
```

## 4. Vitest Browser Mode (Real Browser)

### Configuration
```typescript
// vitest.config.ts
export default defineConfig({
  test: {
    browser: {
      enabled: true,
      provider: 'playwright',
      instances: [
        { browser: 'chromium' },
      ],
    },
  },
})
```

### Test Pattern (same syntax, real browser)
```typescript
import { render } from 'vitest-browser-react'  // NOT @testing-library/react
import { page } from '@vitest/browser/context'

test('component in real browser', async () => {
  const screen = render(<MyComponent />)

  await screen.getByRole('button').click()
  await expect.element(screen.getByText('Updated')).toBeVisible()

  // Real browser APIs available
  const styles = window.getComputedStyle(document.querySelector('.card')!)
  expect(styles.display).toBe('grid')
})
```

### When to Use Browser Mode
- Shadow DOM components
- CSS custom properties (`var(--color)`)
- `ResizeObserver`, `IntersectionObserver`
- Web Components
- Canvas / WebGL
- Real `fetch` / `WebSocket` behavior

## 5. Testing Library Query Priority

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

**Iron rule:** `getByRole` first. `getByTestId` only when no semantic query works.

### Testing Library vs Playwright Locators

| Testing Library | Playwright | Notes |
|----------------|------------|-------|
| `screen.getByRole('button', { name: /submit/i })` | `page.getByRole('button', { name: /submit/i })` | Same API |
| `screen.getByLabelText('Email')` | `page.getByLabel('Email')` | Similar |
| `screen.getByText('Hello')` | `page.getByText('Hello')` | Same |
| `screen.getByPlaceholderText('Search')` | `page.getByPlaceholder('Search')` | Similar |
| `screen.getByTestId('card')` | `page.getByTestId('card')` | Same |
| `await screen.findByText('Loaded')` | `await page.getByText('Loaded').waitFor()` | PW auto-waits |

## 6. Async Patterns

```typescript
// Prefer findBy* (uses waitFor internally)
const element = await screen.findByText('Loaded')

// For disappearance
await waitForElementToBeRemoved(() => screen.queryByText('Loading...'))

// DO NOT: waitFor + getBy (findBy does this for you)
// BAD:  await waitFor(() => screen.getByText('Loaded'))
// GOOD: await screen.findByText('Loaded')
```

## 7. Custom Hook Testing

```typescript
import { renderHook, act } from '@testing-library/react'
import { useCounter } from './useCounter'

test('useCounter hook', () => {
  const { result } = renderHook(() => useCounter(0))

  expect(result.current.count).toBe(0)

  act(() => {
    result.current.increment()
  })

  expect(result.current.count).toBe(1)
})
```

### Hook with Provider Wrapper
```typescript
test('useAuth with context', () => {
  const wrapper = ({ children }) => (
    <AuthProvider>
      {children}
    </AuthProvider>
  )

  const { result } = renderHook(() => useAuth(), { wrapper })
  expect(result.current.isAuthenticated).toBe(false)
})
```

## 8. Common Anti-Patterns

| Anti-Pattern | Correct |
|-------------|---------|
| `fireEvent.click(button)` | `await user.click(button)` (use `userEvent.setup()`) |
| `getByTestId('submit-btn')` | `getByRole('button', { name: /submit/i })` |
| Testing implementation details | Test user-visible behavior |
| `container.querySelector('.class')` | Use semantic queries |
| Snapshot of entire component tree | Small, focused snapshots |
| `waitFor(() => getBy...)` | `findBy...` (has waitFor built in) |

---

*Version: 1.0.0 -- Last updated: 2026-03-29*
