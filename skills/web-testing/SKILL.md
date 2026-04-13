---
name: web-testing
description: |
  Comprehensive web testing with Vitest 3 and Playwright. Unit tests, component tests,
  E2E tests, visual regression, coverage reporting. TDD workflow, mocking patterns,
  Page Object Model, test fixtures.
  AUTOMATICALLY LOAD when test files detected: *.test.ts, *.spec.ts, vitest.config, playwright.config
maturity: opus
maturity_score: 0
lesson_count: 0
user-invocable: false
allowed-tools: Read, Grep, Glob, Bash
auto-load-context:
  - "vitest"
  - "playwright"
  - ".test."
  - ".spec."
  - "testing-library"
  - "coverage"
---

# Web Testing Skill (Vitest 3/4 + Playwright 1.58)

> Vitest unit/component/integration testing + Playwright E2E testing reference.
> Test pyramid: 70% unit / 20% integration / 10% E2E.
> Lessons: `~/.claude/skills/web-testing/lessons/`

---

## 1. Quick Reference: Vitest Config (`vitest.config.ts`)

```typescript
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    globals: true,
    environment: 'happy-dom',          // fastest DOM sim (5-10x jsdom)
    setupFiles: ['./test/setup.ts'],
    include: ['**/*.{test,spec}.{js,ts,jsx,tsx}'],
    exclude: ['**/node_modules/**', '**/dist/**', '**/e2e/**'],
    clearMocks: true,
    restoreMocks: true,
    pool: 'threads',
    testTimeout: 10000,
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html', 'json-summary'],
      include: ['src/**/*.{ts,tsx}'],
      exclude: ['src/**/*.test.ts', 'src/**/*.d.ts'],
      thresholds: { lines: 80, functions: 80, branches: 75, statements: 80 },
      reportOnFailure: true,
    },
  }
})
```

**Environment selection:** happy-dom (default, fastest) | jsdom (getComputedStyle, Range API) | node (no DOM) | Browser Mode (real browser, Shadow DOM, CSS custom props)

Per-file override: `// @vitest-environment jsdom`

## 2. Quick Reference: Playwright Config (`playwright.config.ts`)

```typescript
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: process.env.CI ? [['html'], ['github']] : [['html']],
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'on-first-retry',
    actionTimeout: 10000,
  },
  projects: [
    { name: 'setup', testMatch: /.*\.setup\.ts/ },
    { name: 'chromium', use: { ...devices['Desktop Chrome'] }, dependencies: ['setup'] },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] }, dependencies: ['setup'] },
    { name: 'mobile-chrome', use: { ...devices['Pixel 5'] }, dependencies: ['setup'] },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 120000,
  },
})
```

## 3. Test Pyramid (2026)

```
        /  E2E  \         ~10% (5-30 tests)   — Playwright
       /  (Slow)  \       Critical user journeys only
      /____________\
     / Integration  \     ~20% (50-200 tests)  — Vitest + node/MSW
    /   (Medium)     \    API routes, middleware, DB queries
   /_________________ \
  /    Unit Tests      \  ~70% (500-2000+)     — Vitest + happy-dom
 /      (Fast)          \ Pure functions, hooks, utilities, components
/_________________________\
```

**Rule of thumb:** If it tests a single function/component in isolation = unit. If it tests multiple modules collaborating = integration. If it drives a browser through a user workflow = E2E.

## 4. TDD Workflow: Red-Green-Refactor

```
1. RED:      Write a failing test          → vitest run → FAIL   → commit
2. GREEN:    Write minimal code to pass    → vitest run → PASS   → commit
3. REFACTOR: Clean up (tests still pass)   → vitest run → PASS   → commit
```

Watch mode: `npx vitest --watch`
Filter: `npx vitest --watch -t "should calculate"`
Changed only: `npx vitest --watch --changed`

## 5. Decision Matrix: Which Tool When

| What to Test | Tool | Speed | Reference |
|-------------|------|-------|-----------|
| Pure functions, utils, hooks, validators | Vitest + happy-dom | <1ms/test | `references/vitest-patterns.md` |
| Component rendering, interactions | Vitest + Testing Library | <50ms/test | `references/component-testing.md` |
| Shadow DOM, CSS custom props, ResizeObserver | Vitest Browser Mode | <500ms/test | `references/component-testing.md` |
| API routes, middleware, services | Vitest + node + MSW | <100ms/test | `references/vitest-patterns.md` |
| Visual regression (screenshots) | Playwright toHaveScreenshot() | ~2s/test | `references/coverage-visual.md` |
| Login flows, checkout, critical paths | Playwright E2E | ~5-30s/test | `references/playwright-e2e.md` |
| Accessibility (WCAG 2.2) | @axe-core/playwright or jest-axe | <1s/test | `references/playwright-e2e.md` |
| Core Web Vitals, perf | Chrome DevTools MCP lighthouse_audit | ~10s/test | `references/coverage-visual.md` |

## 6. Available Tools (Installed)

### MCP Servers
- **Playwright MCP Plugin** (`plugin_playwright_playwright`): 20+ tools -- browser_navigate, browser_click, browser_fill_form, browser_take_screenshot, browser_snapshot, browser_run_code, browser_evaluate, browser_console_messages, browser_network_requests
- **Chrome DevTools MCP** (`chrome-devtools`): 25+ tools -- lighthouse_audit, performance_start_trace/stop_trace, take_screenshot, take_snapshot, emulate, console messages, network requests

### Skills
- **webapp-testing** (document-skills): Python Playwright scripts, with_server.py

### Custom Commands
- `/custom:tdd-enforce`: Enforces TDD discipline on GSD plans
- `/custom:deep-debug`: Systematic 4-phase debugging for complex bugs
- `/gsd:add-tests`: Generates tests for completed phases

## 7. External Tools Worth Installing

| Tool | Install | Purpose |
|------|---------|---------|
| testing-frontend skill (MadAppGang) | `npx playbooks add skill madappgang/claude-code --skill testing-frontend` | Vitest + RTL + Vue patterns |
| Playwright Skill (lackeyjb) | `/plugin marketplace add lackeyjb/playwright-skill` | 70+ Playwright guides, auto-execution |
| tdd-guard | `npm i tdd-guard` | CI-level TDD enforcement |
| Playwright Agents | `npx playwright init-agents --loop=claude` | 3 AI agents: planner, generator, healer |

## 8. Recommended Project Structure

```
project/
  src/
    components/
      Button/
        Button.tsx
        Button.test.tsx          # Unit/component (Vitest + RTL)
    hooks/
      useAuth.test.ts            # Hook tests (Vitest)
    utils/
      format.test.ts             # Pure unit (Vitest)
    services/
      api.test.ts                # Integration (Vitest + MSW)
  e2e/
    fixtures.ts                  # Custom Playwright fixtures
    pages/
      LoginPage.ts               # Page Object Models
    tests/
      auth.spec.ts               # E2E tests (Playwright)
    auth.setup.ts                # Auth setup
  mocks/
    handlers.ts                  # MSW handlers (shared)
  test/
    setup.ts                     # Vitest global setup
  vitest.config.ts
  playwright.config.ts
```

## 9. CI Pipeline Order

```
1. Lint + Type Check          (fastest — syntax/type errors)
2. Unit Tests (Vitest)        (fast — logic errors)
3. Component Tests (Vitest)   (fast — rendering errors)
4. Integration Tests (Vitest) (medium — API/service errors)
5. E2E Tests (Playwright)     (slow — workflow errors)
6. Visual Regression (PW)     (slow — UI drift, PR only)
7. Performance (Lighthouse)   (slow — perf regressions, nightly)
```

## 10. Reference Files

| File | Contents |
|------|----------|
| `references/vitest-patterns.md` | Config, environments, AAA, mocking (vi.fn/mock/spyOn), timers, snapshots, coverage, monorepo, RTL |
| `references/playwright-e2e.md` | Config, POM, fixtures, auth, visual regression, network mocking, tracing, CI/CD, Agents |
| `references/component-testing.md` | happy-dom vs jsdom vs Browser Mode, Testing Library queries, hooks, decision matrix |
| `references/coverage-visual.md` | v8 vs istanbul, thresholds, toHaveScreenshot(), MSW integration, performance testing |

---

*Version: 1.0.0 -- Last updated: 2026-03-29*
