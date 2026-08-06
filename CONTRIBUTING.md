# Contributing to Axiom Hitbox Framework

**Axiom Hitbox Framework – Contribution Guidelines**

- **Author:** Iv_0x  
- **Core Version:** 1.4.0  
- **Docs Version:** 1.4.0  
- **Last Updated:** 2026-08-06  

---

## Purpose

Axiom Hitbox is built on top of **Axiom Core**.

Axiom Core provides required infrastructure primitives (such as `Signal`, `Timer`, `Await`, and `Concurrency` managers) that are used internally by the Hitbox framework.

Contributors should treat Core modules as **implementation details** unless they are explicitly documented as part of the public API.

This document defines the **rules, boundaries, and design principles** for contributing to the Axiom Hitbox Framework.

This framework is designed as **low-level infrastructure**.  
All contributions must preserve:

- High-frequency performance & zero-allocation hot paths
- Determinism
- Strict Luau type safety (`--!strict`)
- Strict separation of responsibilities

> **This is NOT a gameplay system.**

---

## Scope of the Framework

### The framework **is responsible for**:
- Spatial detection (Box and Sphere geometries, CFrame / Part / Attachment / Vector3 position tracking)
- Hitbox lifecycle management (`Start` / `Stop` / `Destroy`)
- Continuous attack interval management (`HitResetInterval` for channeling, spin, and laser attacks)
- Target velocity prediction (`Linear`, `Angular`, `LinearAngular`)
- Deterministic, exception-safe hit reporting (`OnHit`, `OnStart`, `OnStop`, `OnUpdate`)
- Memory-stable, zero-allocation pooling for long-running servers
- Infrastructure-level timing (`Timer`) and coroutine synchronization (`Await`) primitives

### The framework **is NOT responsible for**:
- Damage calculation or damage formulas
- Combat rules, stun logic, or game state enforcement
- Status effects, buffs, or debuffs
- Visual or audio effects (beyond basic debug visualization geometry)
- Camera or UI behavior
- Ability or skill execution logic

Any contribution that blurs this boundary will be rejected.

---

## Design Principles

All contributions **must** adhere to the following principles:

- Infrastructure over gameplay
- Determinism over convenience
- Explicit orchestration over implicit behavior
- Performance over flexibility
- Zero-allocation hot paths over dynamic table creation
- Clear ownership of responsibility

If execution order, timing coordination, or game rules are required, they must live **outside** the Hitbox framework.

---

## Module Boundaries

The framework is divided into conceptual layers:

### Infrastructure
- Signal & Timer primitives
- Memory-stable object pooling (`Pool`)
- Finite state management (`State`)
- Coroutine synchronization & concurrency (`Await`, `LockService`, `Transaction`, `Actor`, `Atomic`, `Trade`)
- Character lifecycle coordination (`CharacterService`)

### Mechanism
- Hitbox core logic (`Hitbox`)
- Spatial queries (`GetPartBoundsInBox`, `GetPartBoundsInRadius`)
- Detection lifecycle & velocity prediction

Modules in these layers **must not depend on**:
- Gameplay systems
- Combat resolvers
- Effect handlers
- External orchestration logic

Internal modules are implementation details and must **not** be exposed as public API.

---

## Performance Rules

The Hitbox framework is designed for **hot paths**.

Contributors **MUST** follow these rules:

- **No yielding in hot paths:** No `task.wait()`, `wait()`, or `:Wait()` inside detection loops.
- **Zero-Allocation Hot Paths:** No `OverlapParams.new()` allocation on `:Start()`; mutate pre-allocated `_activeOverlap` buffers in-place.
- **Fast-Path Lookups:** Utilize `part.Parent` fast-path checks before calling `FindFirstAncestorOfClass("Model")`.
- **No per-frame table allocation:** Table clear and reuse existing arrays/maps.
- **No Roblox `Instance` creation inside active detection loops:** Keep debug visualizer parts pooled on the Hitbox instance.
- **$O(1)$ Pool Operations:** Keep pool size and stats tracking $O(1)$ without table iterations.

---

## Signal Usage Rules

Signals are infrastructure primitives.

Rules:
- Signals must not enforce execution order
- No priority-based dispatch
- Callbacks must be synchronous
- Callbacks must not yield
- Event dispatches in hot paths must use `FireSafe` to prevent user script errors from breaking `RunService` loops

If ordered execution is required, implement a **dedicated orchestration layer** outside the framework.

---

## Pooling & Lifecycle Rules

Pooling behavior must remain:

- Automatic
- Transparent
- Deterministic
- Memory-stable

Rules:
- `Destroy()` must return objects to the pool
- Objects must not be used after `Destroy()`
- Re-starting a stopped hitbox (`Stopped -> Active`) must be supported safely without re-allocation
- Pool internals must remain private
- Users must not be required to manage pools manually

Any change to pooling behavior must be justified with **measurable performance benchmarks**.

---

## Type & Strictness Policy

All codebase modules enforce strict Luau type checking.

Rules:
- **ALL** modules **MUST** use `--!strict` mode.
- Functions, methods, and signal parameters **MUST** have explicit type annotations.
- `self` parameters in methods **MUST** be explicitly typed (`local self: Hitbox = self :: any` or signature annotations) to prevent Luau generic solver errors.
- `any` casts are strictly discouraged and allowed only during metatable construction or interface assertions where Luau solver limitations apply.
- Use explicit type narrowing (`Instance`, `RBXScriptConnection`, `DisconnectableTable`) over generic `any`.

---

## Testing Expectations

Contributions **MUST** pass automated testing before PR submission:

1. **Automated Unit Test Suite:** Run `src/Axiom/_tests/HitboxTest.luau` to validate state machine transitions, sphere shapes, reset intervals, attachment tracking, vector positions, and pool recycling.
2. **Automated Performance & Benchmark Suite:** Run `src/Axiom/_tests/HitboxPerformanceTest.luau` to verify zero-allocation pressure, spatial query latency, and pool $O(1)$ throughput.

---

## Documentation Changes

Public-facing changes must be reflected in:
- `README.md`
- `src/Axiom/_docs/README.luau`
- Type definitions (`src/Axiom/Core/Types.luau`)
- `src/Axiom/_docs/CHANGELOG.luau`
- `src/Axiom/_docs/MANIFEST.luau`

Internal refactors do not require documentation unless they affect observable behavior.

---

## Contribution Workflow

### 1. Fork & Branch
- Fork the repository
- Create a new branch from `main`
- Do not commit directly to `main`

Suggested branch names:
- `fix/<description>`
- `feature/<description>`
- `perf/<description>`
- `refactor/<description>`
- `docs/<description>`

---

### 2. Testing Before Submission

All changes must be verified using the automated test suite before submitting a pull request:

- Run `HitboxTest.luau` (all unit assertions must pass)
- Run `HitboxPerformanceTest.luau` (no performance regressions)
- Verify zero type errors under Luau `--!strict` mode

Include test results in the pull request description.

---

### 3. Commit Messages

Use clear and descriptive commit messages following conventional commits.

Format:
`type(scope): short summary`

Common types:
- `fix`, `feat`, `perf`, `refactor`, `test`, `docs`, `chore`

Avoid vague messages such as `update` or `misc`.

---

### 4. Pull Request Notes

Each pull request should include:
- What changed
- Why the change is needed
- Benchmark and test results from `HitboxTest` and `HitboxPerformanceTest`

Changes that affect public behavior or performance must be explicitly highlighted.

---

## Final Notes

The Hitbox Framework is intentionally minimal and performance-focused.

If a feature feels useful but does not strictly belong in infrastructure, it likely belongs in a higher-level system.

**When in doubt, keep the core simple.**

---

## License

See [`LICENSE.md`](./LICENSE.md) or [`src/Axiom/_docs/LICENSE.luau`](./src/Axiom/_docs/LICENSE.luau) for license information.