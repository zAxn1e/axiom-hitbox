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
