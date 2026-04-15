# Splitting Strategies

## Table of Contents

- [Splitting Heuristics](#splitting-heuristics)
- [Concern Categories](#concern-categories)
- [Splitting Rules](#splitting-rules)
- [Good Stack Examples](#good-stack-examples)
- [Good vs Bad Stacks](#good-vs-bad-stacks)
- [Anti-patterns](#anti-patterns)
- [Reviewer Guidance](#reviewer-guidance)

## Splitting Heuristics

- Separate **mechanical refactors** from **behavior changes**.
- Put **interfaces/contracts** (types, endpoints, DB schema) before **consumers**.
- Use **"Scaffold → wire → flip → cleanup"** for anything involving migration or rollout.
- Prefer **one owner per PR** when possible (tag the right reviewers per slice).

## Concern Categories

**Infrastructure / Setup**

- New dependency additions, configuration changes, CI/CD updates, database migrations

**Interface / Contract**

- Trait/interface definitions, API schema changes, new type definitions or data models

**Implementation**

- A single function/method body, one module's internal logic, a single endpoint handler

**Wiring / Integration**

- Connecting new code to existing call sites, route registration, dependency injection

**Cleanup / Quality**

- Linter fixes, formatting, dead code removal, renaming

**Tests**

- Unit tests for new functionality, integration test updates, test fixture additions

## Splitting Rules

1. **Never mix concerns.** A linter fix PR must not also add a feature.
2. **Bottom of stack = lowest dependency.** Types/interfaces go before implementations.
3. **Each PR compiles and passes CI independently.** No "this will be fixed in the next PR."
4. **Target < 200 lines changed per PR.** If larger, find a split point.
5. **Prefer vertical slices for features.** One complete thin path > half of two paths.

## Good Stack Examples

### Example 1: Checkout flow (feature slicing)

```
PR 1: Add checkout button + route shell (no backend calls)
PR 2: Add checkout form + validation (still no payment)
PR 3: Integrate payment provider behind feature flag
PR 4: Confirmation page + analytics + remove temporary mock paths
```

**Why stack:** Sequential build-up; each PR is reviewable; reviewers can start early.

### Example 2: API + client rollout (contract first)

```
PR 1: Add new API endpoint behind flag + tests
PR 2: Add client support behind same flag
PR 3: Migrate callers from old to new (can be one PR per caller)
PR 4: Remove old endpoint + delete old client code
```

**Why stack:** Keeps backwards compatibility; reduces risk; avoids a giant "API + client + migration" PR.

### Example 3: DB migration (scaffold → flip → cleanup)

```
PR 1: Add new table/columns (no reads yet)
PR 2: Dual-write + backfill job + verification script
PR 3: Switch reads to new schema (flagged) + monitoring
PR 4: Remove old schema + remove dual-write/backfill
```

**Why stack:** Each step is safe to merge; progressive rollout.

### Example 4: Refactor before new feature (reduce review fatigue)

```
PR 1: Extract shared utility / rename / reorganize files (no behavior change)
PR 2: Add the new behavior using the utility
PR 3: Harden: tests, edge cases, metrics, docs
```

**Why stack:** Reviewers approve the refactor confidently, then focus on behavior change separately.

### Example 5: Multi-service adoption (one consumer per PR)

```
PR 1: Add new interface + default implementation (backwards compatible)
PR 2: Migrate Service A (reviewers: Service A owners)
PR 3: Migrate Service B (reviewers: Service B owners)
PR 4: Remove old interface once all consumers migrated
```

**Why stack:** Parallelizes across teams; small, owner-targeted PRs.

## Good vs Bad Stacks

### Good: minimal overlap, clean dependency

```
PR 1: Introduce types + helper
PR 2: Use helper in feature path
PR 3: Remove old path
```

Each PR has a clear purpose and is merge-safe.

### Bad: sliced by file instead of by behavior

```
PR 1: Half of UI changes
PR 2: Other half of UI changes
PR 3: Random API changes
```

Reviewers can't validate anything until all are read together.

### Bad: intermediate PRs break CI

If intermediate PRs fail tests or break runtime, the stack is not mergeable and creates churn. Every PR in the stack must pass CI independently.

## Anti-patterns

- **"While I'm here" PR**: Mixing unrelated fixes with a feature. Split them.
- **Monster PR**: > 400 lines. Always splittable.
- **"It all depends on each other"**: Usually means interfaces aren't defined first. Add an interface PR at the bottom.
- **Empty scaffold PR**: Only creates files with stub implementations. Each PR should be meaningful on its own.
- **Sliced by file**: PRs split along file boundaries rather than behavior boundaries. Slice by concern, not by file.

## Reviewer Guidance

**Tell reviewers:**

- Review each PR as if it will merge independently, but know later PRs build on it.
- Focus on the **delta in that PR**, not the entire branch state.
- If something should be fixed later in the stack, leave a comment and note the target PR number.

**Tell authors:**

- Keep PR descriptions clear: "Part 2/4: wiring client behind flag"
- Avoid massive rebases by keeping stacks short-lived and merging continuously.
- If scope changes mid-stack, **split again** rather than bloating an existing PR.
