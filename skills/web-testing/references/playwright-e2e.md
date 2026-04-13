# Playwright E2E Reference

> Playwright 1.58 -- end-to-end testing, visual regression, network mocking, CI/CD.
> Use for critical user journeys (login, checkout, multi-page workflows).

---

## 1. Configuration (`playwright.config.ts`)

```typescript
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,        // Fail CI if test.only left in
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: process.env.CI
    ? [['html'], ['github']]
    : [['html']],

  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',           // Captures trace on retry
    screenshot: 'only-on-failure',
    video: 'on-first-retry',
    actionTimeout: 10000,
  },

  projects: [
    // Auth Setup (runs first)
    { name: 'setup', testMatch: /.*\.setup\.ts/ },

    // Browsers
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
      dependencies: ['setup'],
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
      dependencies: ['setup'],
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
      dependencies: ['setup'],
    },

    // Mobile
    {
      name: 'mobile-chrome',
      use: { ...devices['Pixel 5'] },
      dependencies: ['setup'],
    },
  ],

  // Dev Server (auto-start)
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 120000,
  },
})
```

## 2. Page Object Model (POM)

### Base Page Class
```typescript
// e2e/pages/BasePage.ts
import { type Page, type Locator } from '@playwright/test'

export abstract class BasePage {
  readonly page: Page

  constructor(page: Page) {
    this.page = page
  }

  async navigate(path: string) {
    await this.page.goto(path)
  }

  async getTitle() {
    return this.page.title()
  }
}
```

### Page Object
```typescript
// e2e/pages/LoginPage.ts
import { type Page, type Locator } from '@playwright/test'
import { BasePage } from './BasePage'

export class LoginPage extends BasePage {
  readonly emailInput: Locator
  readonly passwordInput: Locator
  readonly submitButton: Locator
  readonly errorMessage: Locator

  constructor(page: Page) {
    super(page)
    this.emailInput = page.getByLabel('Email')
    this.passwordInput = page.getByLabel('Password')
    this.submitButton = page.getByRole('button', { name: 'Sign in' })
    this.errorMessage = page.getByRole('alert')
  }

  async goto() {
    await this.navigate('/login')
  }

  async login(email: string, password: string) {
    await this.emailInput.fill(email)
    await this.passwordInput.fill(password)
    await this.submitButton.click()
  }
}
```

### Using POM in Tests
```typescript
// e2e/tests/auth.spec.ts
import { test, expect } from '@playwright/test'
import { LoginPage } from '../pages/LoginPage'

test('successful login', async ({ page }) => {
  const loginPage = new LoginPage(page)
  await loginPage.goto()
  await loginPage.login('user@test.com', 'password123')
  await expect(page).toHaveURL('/dashboard')
})

test('invalid credentials show error', async ({ page }) => {
  const loginPage = new LoginPage(page)
  await loginPage.goto()
  await loginPage.login('wrong@test.com', 'bad')
  await expect(loginPage.errorMessage).toBeVisible()
  await expect(loginPage.errorMessage).toHaveText('Invalid credentials')
})
```

## 3. Custom Fixtures

### POM as Fixtures (Recommended)
```typescript
// e2e/fixtures.ts
import { test as base } from '@playwright/test'
import { LoginPage } from './pages/LoginPage'
import { DashboardPage } from './pages/DashboardPage'

type MyFixtures = {
  loginPage: LoginPage
  dashboardPage: DashboardPage
}

export const test = base.extend<MyFixtures>({
  loginPage: async ({ page }, use) => {
    await use(new LoginPage(page))
  },
  dashboardPage: async ({ page }, use) => {
    await use(new DashboardPage(page))
  },
})

export { expect } from '@playwright/test'
```

### Multi-Role Authentication Fixtures
```typescript
import { test as base, type Page } from '@playwright/test'

type AuthFixtures = {
  adminPage: Page
  userPage: Page
}

export const test = base.extend<AuthFixtures>({
  adminPage: async ({ browser }, use) => {
    const ctx = await browser.newContext({
      storageState: 'playwright/.auth/admin.json',
    })
    const page = await ctx.newPage()
    await use(page)
    await ctx.close()
  },
  userPage: async ({ browser }, use) => {
    const ctx = await browser.newContext({
      storageState: 'playwright/.auth/user.json',
    })
    const page = await ctx.newPage()
    await use(page)
    await ctx.close()
  },
})
```

## 4. Authentication (storageState)

### Global Setup Script
```typescript
// e2e/auth.setup.ts
import { test as setup, expect } from '@playwright/test'

setup('authenticate as admin', async ({ page }) => {
  await page.goto('/login')
  await page.getByLabel('Email').fill('admin@test.com')
  await page.getByLabel('Password').fill('admin123')
  await page.getByRole('button', { name: 'Sign in' }).click()
  await page.waitForURL('/dashboard')

  await page.context().storageState({
    path: 'playwright/.auth/admin.json',
  })
})

setup('authenticate as user', async ({ page }) => {
  await page.goto('/login')
  await page.getByLabel('Email').fill('user@test.com')
  await page.getByLabel('Password').fill('user123')
  await page.getByRole('button', { name: 'Sign in' }).click()
  await page.waitForURL('/dashboard')

  await page.context().storageState({
    path: 'playwright/.auth/user.json',
  })
})
```

### Using Auth in Config
```typescript
{
  name: 'chromium',
  use: {
    ...devices['Desktop Chrome'],
    storageState: 'playwright/.auth/user.json',
  },
  dependencies: ['setup'],
}
```

### Resetting Auth for Specific Tests
```typescript
// This test runs WITHOUT authentication
test.use({ storageState: { cookies: [], origins: [] } })

test('landing page shows login button', async ({ page }) => {
  await page.goto('/')
  await expect(page.getByRole('link', { name: 'Sign in' })).toBeVisible()
})
```

## 5. Visual Regression Testing

### Basic Screenshot Comparison
```typescript
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
test('visual with options', async ({ page }) => {
  await page.goto('/dashboard')

  await expect(page).toHaveScreenshot('dashboard.png', {
    maxDiffPixelRatio: 0.01,           // Allow 1% pixel difference
    maxDiffPixels: 100,
    threshold: 0.2,                    // Color tolerance (0=strict, 1=lax)
    animations: 'disabled',            // Freeze CSS animations
    mask: [
      page.locator('.timestamp'),
      page.locator('.avatar'),
      page.locator('.ad-banner'),
    ],
    fullPage: true,
  })
})
```

### Disabling Animations Helper
```typescript
// e2e/helpers/visual.ts
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

### Visual Testing Best Practices
1. Generate baselines in CI (Docker) for consistent rendering
2. Mask dynamic content (timestamps, avatars, ads, counters)
3. Disable CSS animations before capture
4. Set per-component thresholds (hero image = tight, data table = loose)
5. Store baselines in Git (review in PRs like code)
6. Prefer component-level screenshots over full-page
7. Tag visual tests and run on PRs, not every commit

## 6. Network Mocking (`page.route()`)

### Basic API Mocking
```typescript
test('displays mocked data', async ({ page }) => {
  await page.route('**/api/users', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify([{ id: 1, name: 'Mock User' }]),
    })
  })

  await page.goto('/users')
  await expect(page.getByText('Mock User')).toBeVisible()
})
```

### Modify Requests
```typescript
await page.route('**/api/**', async (route) => {
  const headers = {
    ...route.request().headers(),
    'X-Custom-Header': 'test-value',
  }
  await route.continue({ headers })
})
```

### Block Resources (Performance Testing)
```typescript
await page.route('**/*.{png,jpg,gif,svg}', (route) => route.abort())
await page.route('**/analytics/**', (route) => route.abort())
```

### Error Simulation
```typescript
test('handles API error gracefully', async ({ page }) => {
  await page.route('**/api/users', (route) =>
    route.fulfill({ status: 500, body: 'Internal Server Error' })
  )

  await page.goto('/users')
  await expect(page.getByText('Something went wrong')).toBeVisible()
})
```

### HAR Recording & Playback
```typescript
// Record real traffic
test('record API traffic', async ({ page }) => {
  await page.routeFromHAR('tests/fixtures/api.har', {
    url: '**/api/**',
    update: true,                     // Record mode
  })
  await page.goto('/dashboard')
})

// Playback recorded traffic
test('replay from HAR', async ({ page }) => {
  await page.routeFromHAR('tests/fixtures/api.har', {
    url: '**/api/**',
  })
  await page.goto('/dashboard')
  await expect(page.getByText('Dashboard')).toBeVisible()
})
```

### Cleanup
```typescript
afterEach(async ({ page }) => {
  await page.unrouteAll({ behavior: 'wait' })
})
```

### Context-Level vs Page-Level

| Scope | Use Case |
|-------|----------|
| `page.route()` | Test-specific mocks, override for single page |
| `context.route()` | Shared mocks across pages (auth tokens, shared APIs) |

## 7. Trace Viewer & Debugging

### Recording Traces
```typescript
// playwright.config.ts
use: {
  trace: 'on-first-retry',        // Only on retry (saves resources)
  // trace: 'on',                  // Always (heavy)
  // trace: 'retain-on-failure',   // Keep only on failure
}
```

### Viewing Traces
```bash
npx playwright show-trace trace.zip
```

Trace contents: step-by-step timeline, DOM snapshots at each action, network requests/responses, console logs, source code mapping, before/after screenshots.

### Debug Mode
```bash
PWDEBUG=1 npx playwright test       # Browser UI + step-by-step
npx playwright test --debug          # Playwright Inspector
npx playwright test auth.spec.ts --headed  # Headed browser
```

## 8. CI/CD Integration

### GitHub Actions
```yaml
name: E2E Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22

      - run: npm ci
      - run: npx playwright install --with-deps

      - run: npx playwright test

      - uses: actions/upload-artifact@v4
        if: ${{ !cancelled() }}
        with:
          name: playwright-report
          path: playwright-report/
          retention-days: 30
```

### Docker for Consistent Visual Tests
```dockerfile
FROM mcr.microsoft.com/playwright:v1.58.0-noble
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npx playwright test
```

## 9. Playwright Agents (v1.56+)

Three specialized AI agents for test automation:

| Agent | Role |
|-------|------|
| **Planner** | Analyzes app structure, creates test plan |
| **Generator** | Writes test code from plan |
| **Healer** | Auto-fixes failing tests (selector changes, flow updates) |

### Setup
```bash
npx playwright init-agents --loop=claude
```

### Pipeline
```
App change → Planner scans → Generator writes tests → Run → Fail? → Healer fixes → Re-run
```

Best for: keeping E2E tests green after UI refactors, generating initial test suites.

---

*Version: 1.0.0 -- Last updated: 2026-03-29*
