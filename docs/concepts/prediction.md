# Target Velocity Prediction

In fast-paced action games or high-latency network conditions, target characters moving at high velocity can travel outside the current frame's spatial query box before the server registers the hit.

Axiom Hitbox provides built-in **Linear and Angular Target Velocity Prediction** to eliminate latency discrepancies.

---

## 1. How Prediction Works

When `hb.UsePrediction = true` and `hb.CFrame` is bound to a `BasePart`, Axiom extrapolates the part's CFrame forward in time based on its physical assembly velocities before performing spatial queries:

$$\text{Extrapolated Position} = \text{CFrame} + (\text{AssemblyLinearVelocity} \times \Delta t)$$

$$\text{Extrapolated Rotation} = \text{CFrame} \times \text{fromAxisAngle}(\text{AssemblyAngularVelocity.Unit}, \|\text{AssemblyAngularVelocity}\| \times \Delta t)$$

---

## 2. Enabling Prediction

Prediction is configured using three properties on the `Hitbox` instance:

```lua
local hb = Hitbox.new()
hb.CFrame = character.HumanoidRootPart
hb.Size = Vector3.new(4, 5, 4)
hb.Duration = 0.2

-- Enable prediction
hb.UsePrediction = true

-- Set prediction look-ahead time (seconds)
hb.PredictionTime = 0.08 -- 80ms look-ahead

-- Choose prediction algorithm ("Linear", "Angular", or "LinearAngular")
hb.PredictionMethod = "LinearAngular"

hb:Start()
```

---

## 3. Prediction Methods

### `"Linear"`
Extrapolates position based solely on `AssemblyLinearVelocity`. Ideal for straight dashes, sprinting targets, and fast-moving projectiles.

### `"Angular"`
Extrapolates orientation based solely on `AssemblyAngularVelocity`. Ideal for spinning characters, rotating melee swings, or spinning vehicles.

### `"LinearAngular"`
Combines both linear position and angular rotation extrapolation. Recommended for complex acrobatics, air combos, and fast physical movement.

---

## 4. Best Practices & Recommended Tuning

- **Default Look-Ahead (`PredictionTime`)**: `0.06` to `0.08` seconds (60ms - 80ms) matches average player round-trip network ping.
- **When to Use**:
  - Fast dashing attacks (e.g. flash steps, high-speed lunges).
  - High-velocity projectiles or spell effects.
  - Air combo launchers and knockbacks.
- **When NOT to Use**:
  - Stationary boss fights or slow-moving ambient NPCs.
  - Large spherical area-of-effect (AoE) explosions where position extrapolation could cause hits through walls.
