# Automated Testing Suite

Axiom Hitbox includes built-in unit and performance test suites under `src/Axiom/_tests/`.

All PR submissions must pass these automated tests without regressions.

---

## 1. Unit Tests (`HitboxTest.luau`)

Validates correctness across all core framework features:

- **State Machine Transitions**: Validates `Idle -> Active -> Stopped` transitions and fixes for `Stopped -> Active` / `Cooldown -> Active` restarts.
- **Sphere Spatial Queries**: Tests `GetPartBoundsInRadius` query resolution.
- **HitResetInterval Mechanics**: Verifies continuous attack hit memory clearing.
- **Attachment & CFrame Tracking**: Verifies dynamic matrix resolution.
- **Vector3 Position Resolution**: Verifies raw coordinate handling.
- **Pool Recycling**: Verifies instance cleanup and re-acquisition sanity.

### Execution
Run `HitboxTest.luau` in Roblox Studio (Server Command Bar or TestService).

---

## 2. Performance & Benchmark Suite (`HitboxPerformanceTest.luau`)

Validates framework throughput under high load:

- **Hot-Path Memory Allocation**: Measures heap allocation rate per `:Start()` cycle (verifying zero GC pressure).
- **Spatial Query Latency**: Measures CPU execution duration for 50+ concurrent active hitboxes.
- **$O(1)$ Pool Throughput**: Verifies constant-time acquire/release throughput across thousands of cycles.

### Execution
Run `HitboxPerformanceTest.luau` in Roblox Studio. Results will print benchmark latency metrics to the Output window.
