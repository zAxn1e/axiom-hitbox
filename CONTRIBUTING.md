# Contributing to Axiom Hitbox Framework

**Axiom Hitbox Framework – Contribution Guidelines**

- **Author:** Iv_0x  
- **Core Version:** 1.3.0  
- **Docs Version:** 1.3.0  
- **Last Updated:** 2026-01-04  

---

## Purpose

Axiom Hitbox is built on top of **Axiom Core**.

Axiom Core provides required infrastructure primitives (such as `Signal`) that
are used internally by the Hitbox framework.

Contributors should treat Core modules as **implementation details** unless
they are explicitly documented as part of the public API.

This document defines the **rules, boundaries, and design principles** for
contributing to the Axiom Hitbox Framework.

This framework is designed as **low-level infrastructure**.  
All contributions must preserve:

- Performance
- Determinism
- Strict separation of responsibilities

> **This is NOT a gameplay system.**

---

## Scope of the Framework

### The framework **is responsible for**:
- Spatial detection (geometry + time)
- Lifecycle management (`Start` / `Stop` / `Destroy`)
- Deterministic hit reporting
- Memory-stable pooling for long-running servers
- Infrastructure-level timing primitives (Timer)

### The framework **is NOT responsible for**:
- Damage calculation
- Combat rules or logic
- Status effects or buffs
- Visual or audio effects (beyond simple visualization)
- Camera or UI behavior
- Ability or skill logic

Any contribution that blurs this boundary will be rejected.

---

## Design Principles

All contributions **must** adhere to the following principles:

- Infrastructure over gameplay
- Determinism over convenience
- Explicit orchestration over implicit behavior
- Performance over flexibility
- Clear ownership of responsibility

If execution order, timing coordination, or game rules are required,  
they must live **outside** the Hitbox framework.

---

## Module Boundaries

The framework is divided into conceptual layers:

### Infrastructure
- Signal
- Pooling
- State management
- Timer and scheduling primitives

### Mechanism
- Hitbox core logic
- Spatial queries
- Detection lifecycle

Modules in these layers **must not depend on**:
- Gameplay systems
- Combat resolvers
- Effect handlers
- External orchestration logic

Internal modules are implementation details and must **not** be exposed
as public API.

---

## Performance Rules

The Hitbox framework is designed for **hot paths**.

Contributors **MUST** follow these rules:

- No yielding in hot paths
- No `task.wait()`, `wait()`, or `:Wait()`
- No Roblox `Instance` creation inside active loops
- No per-frame table allocation
- No dynamic memory churn during detection

All allocations must happen during setup or pooling.

---

## Signal Usage Rules

Signals are infrastructure primitives.

Rules:
- Signals must not enforce execution order
- No priority-based dispatch
- Callbacks must be synchronous
- Callbacks must not yield

If ordered execution is required, implement a **dedicated orchestration layer**
outside the framework.

---

## Pooling & Lifecycle Rules

Pooling behavior must remain:

- Automatic
- Transparent
- Deterministic

Rules:
- `Destroy()` must return objects to the pool
- Objects must not be used after `Destroy()`
- Pool internals must remain private
- Users must not be required to manage pools manually

Any change to pooling behavior must be justified with
**measurable performance impact**.

---

## Type & Strictness Policy

Type checking is used selectively.

Rules:
- Core modules **MUST** use `--!strict`
- Hitbox core uses `--!strict`
- Runtime performance must not degrade
- `any` casts are allowed only during construction

---

## What Not to Add

The following will **NOT** be accepted:

- Damage calculation logic
- Combat rule enforcement
- Status or effect systems
- Priority-based signal dispatch
- Debug logic that alters runtime behavior
- Visualization systems beyond simple hitbox geometry
- Engine-specific shortcuts that reduce portability

Feature requests that belong to higher layers should be implemented
**outside** this framework.

---

## Deprecation Policy

Public APIs may be deprecated when necessary.

Rules:
- Deprecations must be explicitly documented
- Deprecated APIs must continue to function for at least
  one minor version when possible
- Silent behavior changes are not allowed

Deprecation notes must be added to:
- `CHANGELOG`
- `README` (if public-facing)

---

## Testing Expectations

Contributions should be tested under:

- Multiple simultaneous hitboxes
- Long-running server conditions
- High-frequency activation
- Reuse after pooling

Any change that affects performance or lifecycle must include
a rationale and testing notes.

---

## Documentation Changes

Public-facing changes must be reflected in:
- `README.lua`
- Type definitions (`Types.lua`)
- `CHANGELOG`

Internal refactors do not require documentation unless they affect
observable behavior.

---

## Final Notes

The Hitbox Framework is intentionally minimal.

If a feature feels useful but does not strictly belong in infrastructure,
it likely belongs in a higher-level system.

**When in doubt, keep the core simple.**

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

All changes must be tested before submitting a pull request.

At minimum, verify:
- Multiple hitboxes running simultaneously
- Correct lifecycle behavior (`Start` / `Stop` / `Destroy`)
- Pool reuse after destruction

Formal unit tests are not required.  
However, **testing notes are required** in the pull request description.

---

### 3. Commit Messages

Use clear and descriptive commit messages.

Format:
`type: short summary`

Common types:
- `fix`, `feature`, `perf`, `refactor`, `docs`, `chore`

Avoid vague messages such as `update` or `misc`.

---

### 4. Pull Request Notes

Each pull request should include:
- What changed
- Why the change is needed
- How it was tested

Changes that affect public behavior or performance
must be explicitly mentioned.