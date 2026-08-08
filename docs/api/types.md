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
