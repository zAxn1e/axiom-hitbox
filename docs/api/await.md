# Await Synchronization API Reference

`Await` is a coroutine-based synchronization library providing safe cancellation, timeouts, barriers, and concurrency primitives for Roblox.

```lua
local Await = require(Axiom.Core.Await)
```

---

## Cancellation Tokens (`CancelToken`)

### `Await.Token()`
```lua
function Await.Token(): CancelToken
```
Creates a new cooperative cancellation token.

#### Token Methods
- `token:Cancel(reason?)` — Triggers cancellation and notifies callbacks/children.
- `token:ThrowIfCancelled()` — Throws error if token is cancelled.
- `token:OnCancelled(fn)` — Binds callback executed upon cancellation.
- `token:Child()` — Creates a child token that automatically cancels when parent cancels.
- `token:LinkToInstance(inst)` — Automatically cancels token when Roblox `Instance` is destroyed.

---

## Core Primitives

### `Await.Signal(signal, timeout?, token?)`
Yields the thread until an `RBXScriptSignal` or Axiom `Signal` fires. Returns fired arguments. Throws error on timeout or token cancellation.

### `Await.Sleep(seconds, token?)`
Wrapper around `task.delay` supporting cooperative cancellation and token validation.

### `Await.Any(tasks, timeout?, token?)` / `Await.Race`
Runs multiple async functions in parallel. Resumes when the **first** task completes successfully.

### `Await.All(tasks, timeout?, opts?, token?)`
Synchronization barrier. Yields until **all** tasks complete.

### `Await.Condition(predicate, timeout?, interval?)`
Polls a predicate function until it returns `true`.

---

## Functional Utilities

- `Await.Try(fn)` — Executes function safely, returning `{ success = true, values = {...} }` or `{ success = false, error = ... }`.
- `Await.Retry(fn, maxAttempts, opts?)` — Retries function upon failure with configurable backoff.
- `Await.Debounce(fn, delay, opts?)` — Coalesces rapid calls into a single execution after delay.
- `Await.Throttle(fn, window, opts?)` — Ensures function executes at most once per time window.
- `Await.Queue()` — Returns function wrapper serializing calls in FIFO order.

---

## Concurrency Primitives

### `Await.Mutex()`
Mutual exclusion lock for critical sections:
```lua
local mutex = Await.Mutex()
mutex:Scoped(function()
    -- Critical section (only 1 thread at a time)
end)
```

### `Await.Semaphore(maxCount)`
Limits concurrent thread access up to `maxCount` capacity.
