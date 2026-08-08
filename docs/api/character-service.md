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
