---
title: Hitbox Class API
description: Complete API reference for Axiom's core Hitbox class - methods, properties, signals, and spatial query options.
---

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
