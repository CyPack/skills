# Testing MCP & CLI Tools Matrix

## Installed MCP Servers for Testing

| MCP Server | Type | Tools | Use For |
|-----------|------|-------|---------|
| **Playwright Plugin** | Plugin | 21 | E2E functional tests, cross-browser, form fill, screenshots |
| **Chrome DevTools** | MCP | 26 | Lighthouse audits, performance traces, memory, network debug |
| **@eslint/mcp** | MCP | ~5 | Code quality lint, auto-fix |
| **Semgrep** | HTTP | ~10 | Security scanning, 5000+ rules, SAST |
| **a11y-mcp** | MCP | ~3 | Accessibility audits, axe-core, WCAG 2.0/2.1/2.2 |
| **image-compare** | MCP | ~3 | Pixel-perfect visual regression via Pixelmatch |
| **pkg-registry** | MCP | ~5 | NPM/Cargo/PyPI/NuGet package info lookup |

## Combined Workflow: Full Quality Gate

```
Code Change
    |
[1] Vitest unit/component tests         (< 30s)
    |
[2] @eslint/mcp lint check              (< 10s)
    |
[3] Semgrep security scan               (< 30s)
    |
[4] Playwright E2E critical paths       (< 2min)
    |
[5] image-compare visual diff           (< 30s)
    |
[6] a11y-mcp accessibility audit        (< 30s)
    |
[7] Chrome DevTools Lighthouse           (< 30s)
    |
ALL PASS --> Commit / Deploy
```

## Playwright + Chrome DevTools Combined Patterns

**They do NOT conflict — each runs its own browser.**

| Task | Use Playwright | Use Chrome DevTools |
|------|---------------|---------------------|
| E2E user flow | Primary | - |
| Cross-browser | Primary (Chrome+FF+Safari) | - |
| Performance profiling | - | Primary (Lighthouse, traces) |
| Memory leaks | - | Primary (heap snapshots) |
| Network debugging | Basic (list requests) | Primary (request/response bodies) |
| Console errors | Basic | Primary (deep filtering) |
| Accessibility | snapshot (a11y tree) | Lighthouse (accessibility score) |
| Visual regression | toHaveScreenshot() | - |
| CPU/Network throttle | - | emulate tool |
| Form testing | fill_form, click | fill, click |

### Pattern A: Functional + Performance
```
1. Playwright → navigate, fill forms, complete journey
2. Playwright → screenshot, verify elements
3. DevTools → lighthouse_audit on same URL
4. Compare: PASS + Lighthouse > 90
```

### Pattern B: Debug Failing Test
```
1. Playwright → run test, find failure point
2. DevTools → list_console_messages (JS errors?)
3. DevTools → list_network_requests (failed API?)
4. DevTools → evaluate_script (DOM state?)
5. Fix and re-run
```

## CLI Tools

| Tool | Install | What It Does |
|------|---------|-------------|
| **tdd-guard** | `npm i -g tdd-guard` | Hook: blocks Write/Edit without failing test first |
| **Playwright Agents** | `npx playwright init-agents --loop=claude` | 3 AI agents: planner → generator → healer |
| **Playwright CLI** | `npx @playwright/cli` | 4x fewer tokens than MCP (27k vs 114k) |
| **Semgrep CLI** | `pip install semgrep` | Local security scanning |

## Token Budget Strategy

**Never load all testing MCPs at once (~51k tokens).**

| Session Type | Load These | Skip These |
|-------------|-----------|------------|
| Unit testing | Vitest CLI only | All MCPs |
| E2E testing | Playwright | DevTools, a11y |
| Debugging | DevTools | Playwright, image-compare |
| Accessibility | a11y-mcp | image-compare, Semgrep |
| Security review | Semgrep | Playwright, DevTools |
| Full audit | Playwright + DevTools | a11y (use Lighthouse instead) |
| Visual regression | image-compare | DevTools, a11y |
