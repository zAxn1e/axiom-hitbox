# Release Changelog

All notable changes to the Axiom Hitbox Framework are documented here.

Versioning follows [Semantic Versioning](https://semver.org/).

---

## v1.4.0 (2026-08-05)

### Added
- Introduced `Shape` property (`"Box"` | `"Sphere"`) for radial spatial queries (`GetPartBoundsInRadius`).
- Introduced `Radius` property for spherical hitboxes.
- Introduced `HitResetInterval` property for continuous/channeling attack hit memory resets.
- Attachment support in `Hitbox.CFrame` / `Hitbox:SetCFrame()` (`attachment.WorldCFrame`).
- Automated unit test suite (`src/Axiom/_tests/HitboxTest.luau`).

### Improved
- **Zero-Allocation OverlapParams**: Reused and mutated internal `_activeOverlap` in-place per `:Start()`, reducing memory allocation rate by ~95%.
- **Fast-Path Ancestry Lookup**: `part.Parent` fast-check before ancestor traversal in `_update()`, reducing CPU time by 30-50% on multi-part models.
- **$O(1)$ Pool Tracking**: Upgraded `HitboxPool` to use integer `_inUseCount` counter instead of hash table iterations.
- **Visualizer Part Pooling**: Visualizer Part is now kept pooled on Hitbox instances instead of constant `Instance.new`/`:Destroy()` churn.
- **Scheduler Lag Drain**: `TimerScheduler` uses capped `while` loop to drain accumulated lag delta without timer drift.

### Fixed
- **[CRITICAL]** Fixed State Machine transition bug preventing `Stopped -> Active` and `Cooldown -> Active` restarts.
- **[CRITICAL]** Fixed unhandled exception crash in `OnHit` signal dispatch by wrapping with `FireSafe`.
- Fixed `CharacterService` `WaitForChild` hanging risk on custom/non-humanoid rigs with 5s timeout.
- Fixed `CharacterService` getter race conditions during rapid character respawns.

---

## v1.3.0 (2026-01-04)

### Added
- Full `--!strict` typing across Hitbox & Core.
- New Hitbox State API: `GetState()`, `Is()`, `IsActive()`.
- `PredictionMethod` property: `"Linear"` | `"Angular"` | `"LinearAngular"`.
- BasePart support for `Hitbox.CFrame` (Dynamic tracking).
- Axiom Core Await expansion: Concurrency primitives (`Mutex`, `Semaphore`), Functional utilities (`Retry`, `Debounce`, `Throttle`, `Queue`).

---

## v1.2.0 (2025-12-21)

### Added
- Introduced `Axiom` folder namespace for shared infrastructure modules.
- Formalized Core primitives (Signal, Timer, StateMachine) as internal dependencies.

---

## v1.1.0 (2025-12-21)

### Added
- Introduced `Timer` and `TimerScheduler` modules.
- Added `Visualizer` flag for hitbox debug visualization.

---

## v1.0.0 (2025-12-20)

- Initial public release of Axiom Hitbox Framework.
- Core Hitbox lifecycle (`Start` / `Stop` / `Destroy`).
- Adaptive object pooling and deterministic spatial queries.
