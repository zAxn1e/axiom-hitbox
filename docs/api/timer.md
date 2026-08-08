# Timer & Scheduler API Reference

`Timer` is a temporal infrastructure primitive backed by a centralized update loop (`Scheduler.luau`).

```lua
local Timer = require(Axiom.Core.Timer)
```

---

## Constructor

### `Timer.new(duration)`
```lua
function Timer.new(duration: number): Timer
```
Creates a new `Timer` instance configured for `duration` seconds.
- **Parameters**: `duration: number` (must be > 0).

---

## Properties

- `Duration: number` — Total duration limit (seconds).
- `Remaining: number` — Remaining time (seconds).
- `Running: boolean` — Whether timer is currently active.

---

## Signals

- `OnFinished: Signal<()>` — Emitted when remaining time reaches 0.
- `OnUpdated: Signal<number>` — Emitted on scheduler ticks if updates are enabled via `:SetEmitUpdates(true)`.

---

## Control Methods

- `:Start()` — Starts timer and registers with `Scheduler`.
- `:Stop()` — Halts timer and removes from `Scheduler`.
- `:Pause()` — Pauses remaining countdown.
- `:Resume()` — Resumes countdown from paused state.
- `:Reset(duration?)` — Resets remaining time to duration.
- `:Destroy()` — Stops timer and disconnects signals.

---

## Query Methods

- `:GetRemaining() -> number` — Returns remaining seconds.
- `:GetElapsed() -> number` — Returns elapsed seconds.
- `:GetProgress() -> number` — Returns progress ratio between `0.0` and `1.0`.
- `:IsRunning() -> boolean` — Returns `true` if active.
- `:IsPaused() -> boolean` — Returns `true` if paused.
- `:IsFinished() -> boolean` — Returns `true` if remaining <= 0.
