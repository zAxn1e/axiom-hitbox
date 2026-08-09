# Axiom Hitbox Framework -- AI Reference & Context Guide

Version: 1.4.0

This document provides concise, explicit, and accurate context for AI coding assistants (e.g. Claude Code, Cursor, Gemini CLI, Codex) writing Luau code with Axiom Hitbox Framework v1.4.0.

---

## 1. Project Overview

Axiom Hitbox is a server-authoritative, zero-allocation spatial query framework for Roblox Luau.
It decouples infrastructure primitives (spatial detection, timing, cancellation, object pooling) from gameplay rules (damage, combos, VFX, cooldowns).

### Key Architecture Rules
- **Server Authority**: Spatial detection and damage calculation MUST run on the server. Clients must never calculate or transmit hit target arrays over `RemoteEvent`s.
- **Strict Type Safety**: All scripts using Axiom should enforce `--!strict` Luau mode.
- **Memory Stability**: Uses an internal O(1) adaptive object pool (`Hitbox.new()`) with pre-allocated `OverlapParams` to achieve zero GC pressure during combat.

---

## 2. Core API Reference & Signatures

### Hitbox Class API

# Hitbox Class API Reference

The `Hitbox` class is the primary public API surface of the Axiom Hitbox Framework.

```lua
local Hitbox = require(Axiom.Hitbox)
```

---

## Constructor

### `Hitbox.new()`
```lua
function Hitbox.new(): Hitbox
```
Acquires a `Hitbox` instance from the internal $O(1)$ adaptive object pool (`_POOL`). The returned object is in the `Idle` state with clean default configuration.

- **Returns**: `Hitbox`
- **Performance**: $O(1)$ constant time lookup. Pre-warms 30 instances on require.

---

## Class Functions

### `Hitbox.GetPoolStats()`
```lua
function Hitbox.GetPoolStats(): { available: number, inUse: number }
```
Returns diagnostics about the internal adaptive object pool.

- **Returns**: A table `{ available = number, inUse = number }`.

---

## Properties

| Property | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `Size` | `Vector3` | `Vector3.new(4, 4, 4)` | Bounding box dimensions for spatial queries. |
| `Shape` | `"Box" \| "Sphere"` | `"Box"` | Geometry query method (`"Box"` uses `GetPartBoundsInBox`, `"Sphere"` uses `GetPartBoundsInRadius`). |
| `Radius` | `number` | `4` | Spherical radius used when `Shape = "Sphere"`. |
| `HitResetInterval` | `number?` | `nil` | Optional interval (seconds) to reset hit memory for continuous attacks. |
| `CFrame` | `CFrame \| BasePart \| Attachment \| Vector3` | `CFrame.identity` | Position or dynamic target instance to track. |
| `Offset` | `CFrame` | `CFrame.identity` | Local offset matrix applied to `CFrame`. |
| `Duration` | `number` | `math.huge` | Active lifetime limit (seconds). |
| `Ignore` | `{ Instance }` | `{}` | Array of instances excluded from hit detection. |
| `OverlapParams` | `OverlapParams?` | `nil` | Custom engine overlap params filter. |
| `Visualizer` | `boolean` | `false` | Enables debug Part rendering in `workspace`. |
| `UsePrediction` | `boolean` | `false` | Enables target velocity prediction. |
| `PredictionTime` | `number` | `0.06` | Prediction look-ahead time (seconds). |
| `PredictionMethod` | `"Linear" \| "Angular" \| "LinearAngular"` | `"Linear"` | Extrapolation algorithm for velocity prediction. |

---

## Signals

### `OnStart`
```lua
OnStart: Signal<Hitbox>
```
Emitted synchronously via `FireSafe` when `:Start()` is called.

### `OnStop`
```lua
OnStop: Signal<Hitbox>
```
Emitted synchronously via `FireSafe` when `:Stop()` is called or duration expires.

### `OnUpdate`
```lua
OnUpdate: Signal<number, Hitbox>
```
Emitted every `Heartbeat` frame while active. Passes delta time (`dt`) and the hitbox instance.

### `OnHit`
```lua
OnHit: Signal<Model, Humanoid, BasePart>
```
Emitted synchronously via `FireSafe` when a new target `Model` containing a `Humanoid` is detected inside spatial query bounds.
- **Arguments**: `(targetModel: Model, targetHumanoid: Humanoid, hitPart: BasePart)`

---

## Lifecycle Methods

### `:Start()`
```lua
function Hitbox:Start(): ()
```
Activates spatial detection. Transitions state to `Active`, prepares `_activeOverlap`, emits `OnStart`, and connects to `RunService.Heartbeat`.

### `:Stop()`
```lua
function Hitbox:Stop(): ()
```
Halts spatial detection. Transitions state to `Stopped`, disconnects `Heartbeat`, hides visualizer, and emits `OnStop`.

### `:Destroy()`
```lua
function Hitbox:Destroy(): ()
```
Cleans up event connections, hides visualizer, sets `_destroyed = true`, and returns the instance to the pool for recycling.

---

## Transformation & Utility Methods

### `:SetCFrame(cf)`
```lua
function Hitbox:SetCFrame(cf: CFrame | BasePart | Attachment | Vector3): ()
```
Helper method to update `hb.CFrame`.

---

## State Query Methods

### `:GetState()`
```lua
function Hitbox:GetState(): string
```
Returns current state string (`"Idle"`, `"Active"`, `"Stopped"`, `"Cooldown"`).

### `:Is(state)`
```lua
function Hitbox:Is(state: string): boolean
```
Returns `true` if current state matches parameter.

### `:IsActive()`
```lua
function Hitbox:IsActive(): boolean
```
Returns `true` if current state is `"Active"`.

### Signal API

# Signal API Reference

`Signal` is a lightweight, synchronous, zero-allocation event primitive used throughout Axiom Core and Hitbox.

```lua
local Signal = require(Axiom.Core.Signal)
```

---

## Constructor

### `Signal.new()`
```lua
function Signal.new<T...>(): Signal<T...>
```
Creates a new `Signal` instance.

---

## Methods

### `:Connect(fn)`
```lua
function Signal:Connect(fn: (...any) -> ()): Connection
```
Connects a callback handler to the signal.
- **Returns**: `Connection` table `{ Disconnect: () -> () }`.

---

### `:Once(fn)`
```lua
function Signal:Once(fn: (...any) -> ()): Connection
```
Connects a callback handler that automatically disconnects itself after the first execution.

---

### `:FireFast(...args)`
```lua
function Signal:FireFast(...: any): ()
```
Fires all connected handlers sequentially without error handling wrappers. Maximum speed for hot paths.

---

### `:FireSafe(...args)`
```lua
function Signal:FireSafe(...: any): ()
```
Fires all connected handlers wrapped in `pcall`. If a handler throws an error, a warning is logged (`[Signal] Handler error: ...`) and remaining handlers continue executing. Used by `OnHit`.

---

### `:HasConnections()`
```lua
function Signal:HasConnections(): boolean
```
Returns `true` if any active callbacks are currently connected.

---

### `:DisconnectAllFast()`
```lua
function Signal:DisconnectAllFast(): ()
```
Clears all connected handlers instantly in $O(1)$ time.

---

### `:Freeze()` / `:Unfreeze()`
```lua
function Signal:Freeze(): ()
function Signal:Unfreeze(): ()
```
Temporarily pauses or resumes event dispatching. When frozen, calls to `FireFast` and `FireSafe` are ignored.

---

### `:Destroy()`
```lua
function Signal:Destroy(): ()
```
Permanently destroys the signal, disconnects handlers, and freezes further connections.

### Timer API

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

### Await Synchronization API

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

### CharacterService API

# CharacterService API Reference

`CharacterService` provides managed, type-safe, race-condition-proof access to the `LocalPlayer` character and its core components (`HumanoidRootPart`, `Humanoid`, `Animator`).

```lua
local CharacterService = require(Axiom.Service.CharacterService)
```

---

## State Properties (Read-Only Inspection)

Nullable properties for non-blocking checks:

- `CharacterService.Character: Model?`
- `CharacterService.Root: BasePart?`
- `CharacterService.Humanoid: Humanoid?`
- `CharacterService.Animator: Animator?`

---

## Yielding Getters (Guaranteed Non-Nil)

Getters block execution via `Axiom.Await` until character components exist and are attached to `game`:

### `GetCharacter()`
```lua
function CharacterService:GetCharacter(): Model
```

### `GetRoot()`
```lua
function CharacterService:GetRoot(): BasePart
```

### `GetHumanoid()`
```lua
function CharacterService:GetHumanoid(): Humanoid
```

### `GetAnimator()`
```lua
function CharacterService:GetAnimator(): Animator
```

### `Get()`
```lua
function CharacterService:Get(): (Model, BasePart, Humanoid, Animator)
```
Returns all 4 core components in a single tuple once fully loaded.

---

## Signals

- `CharacterService.CharacterAdded: Signal<Model>` — Emitted after all internal components (Root, Humanoid, Animator) are bound and verified.
- `CharacterService.CharacterRemoving: Signal<Model>` — Emitted right before unbinding cleanup during player respawn.

### Exported Luau Types

# Shared Types API Reference

Axiom exports Luau type definitions in `src/Axiom/Core/Types.luau` for complete `--!strict` type checking.

```lua
local Types = require(Axiom.Core.Types)
```

---

## Type Enums & Aliases

### `HitboxState`
```lua
export type HitboxState = "Idle" | "Active" | "Stopped" | "Cooldown"
```

### `HitboxPredictionMethod`
```lua
export type HitboxPredictionMethod = "Linear" | "Angular" | "LinearAngular"
```

### `HitboxShape`
```lua
export type HitboxShape = "Box" | "Sphere"
```

---

## Interface Definitions

### `Hitbox` Type
Defines all public properties, signals, and methods on a `Hitbox` instance.

### `Timer` Type
Defines properties, signals, and methods on a `Timer` instance.

### `StateMachine` Type
Defines state transition interface:
```lua
export type StateMachine = {
    current: State,
    canTransition: (self: StateMachine, to: State) -> boolean,
    set: (self: StateMachine, to: State) -> boolean,
    is: (self: StateMachine, state: State) -> boolean,
}
```

---

## 3. Mandatory Rules & Constraints

> [!IMPORTANT]
> 1. **Do Not Instantiate Internal Pool Directly**: Always use `Hitbox.new()`. Never instantiate or mutate internal `_POOL` primitives.
> 2. **Always Cleanup via `:Destroy()`**: Call `hb:Destroy()` when a hitbox completes its duration to return it to the adaptive pool and disconnect signals.
> 3. **Post-Destroy Invariant**: Do NOT dereference or modify a `Hitbox` instance after calling `:Destroy()`. Accessing a destroyed instance logs warnings and blocks execution.
> 4. **Exception-Safe Handlers**: `hb.OnHit` uses `FireSafe`. Callbacks that throw errors will log warnings without crashing the RunService loop.
> 5. **Dynamic Frame Tracking**: When assigning `hb.CFrame = character.HumanoidRootPart`, pass the `BasePart` directly rather than pre-evaluating `BasePart.CFrame` if real-time tracking is desired.
> 6. **Continuous Attack Reset**: For DoT skills, auras, or beam attacks, set `hb.HitResetInterval = number` to automatically reset hit memory periodically.

---

## 4. Common Anti-Patterns & API Mistakes

### [X] Incorrect: Accepting target hit lists from client over RemoteEvents
```lua
-- DO NOT DO THIS (Vulnerable to exploiters)
DamageRemote.OnServerEvent:Connect(function(player, hitTargets)
    for _, target in hitTargets do target.Humanoid:TakeDamage(50) end
end)
```

### [OK] Correct: Server-authoritative Hitbox activation
```lua
-- DO THIS (Server calculates hit detection)
SkillRemote.OnServerEvent:Connect(function(player)
    local char = player.Character or return
    local hb = Hitbox.new()
    hb.Shape = "Box"
    hb.Size = Vector3.new(5, 6, 4)
    hb.CFrame = char:FindFirstChild("HumanoidRootPart")
    hb.Offset = CFrame.new(0, 0, -3)
    hb.Duration = 0.3
    hb.Ignore = { char }
    hb.OnHit:Connect(function(model, humanoid)
        humanoid:TakeDamage(25)
    end)
    hb:Start()
    task.delay(hb.Duration + 0.05, function()
        hb:Destroy()
    end)
end)
```

### [X] Incorrect: Forgetting to destroy hitbox after duration
```lua
-- DO NOT DO THIS (Memory leak and pool exhaustion)
local hb = Hitbox.new()
hb:Start()
-- missing hb:Destroy()
```

### [OK] Correct: Immediate or delayed recycling to object pool
```lua
-- DO THIS
local hb = Hitbox.new()
hb.Duration = 0.5
hb:Start()
task.delay(hb.Duration + 0.05, function()
    hb:Destroy()
end)
```
