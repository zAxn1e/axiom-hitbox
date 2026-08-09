# Contributing Guidelines

Thank you for your interest in contributing to **Axiom Hitbox Framework**!

As low-level infrastructure for Roblox games, all contributions must preserve strict determinism, low-allocation hot path design, and full `--!strict` Luau type safety.

---

## 1. Scope Boundaries

### Axiom IS Responsible For:
- Spatial detection queries (`Box` and `Sphere`).
- Dynamic `CFrame` / `BasePart` / `Attachment` tracking.
- Target velocity prediction (`Linear`, `Angular`, `LinearAngular`).
- Continuous attack interval management (`HitResetInterval`).
- Deterministic event dispatches (`OnHit`, `OnStart`, `OnStop`).
- Adaptive object pooling (`Pool.luau`).
- Infrastructure timing (`Timer`) and coroutine synchronization (`Await`).

### Axiom IS NOT Responsible For:
- Damage formulas or combat rules.
- Stun, poise, posture, or stamina systems.
- Visual FX, animations, or audio handlers.
- UI or camera controllers.

---

## 2. Code Style & `--!strict` Policy

- **Strict Mode Mandatory**: Every `.luau` module must begin with `--!strict`.
- **Explicit Type Annotations**: All functions, methods, and signal callbacks must include explicit type annotations.
- **Explicit `self` Typing**: Method signatures must annotate `self` (`local self: Hitbox = self :: any`) to avoid Luau generic solver errors.
- **Buffer Reuse Rule**: Avoid constructing `OverlapParams.new()` inside active detection loops. Mutate `_activeOverlap` in-place.
- **Fast-Path Lookups**: Check `part.Parent` fast-path before executing deeper hierarchy searches.

---

## 3. Contribution Workflow

1. Fork the repository on GitHub.
2. Create a feature branch (`git checkout -b feature/my-feature`).
3. Run the automated unit & performance test suites in Studio (`HitboxTest.luau` and `HitboxPerformanceTest.luau`).
4. Commit your changes using conventional commit messages (e.g. `feat(hitbox): add attachment tracking`).
5. Open a Pull Request targeting `main`.
