# Spatial Detection (Box & Sphere)

Axiom Hitbox v1.4.0 supports two geometry shapes for spatial queries: **Box** and **Sphere**.

Both geometries run on native Roblox engine spatial methods (`WorldRoot:GetPartBoundsInBox` and `WorldRoot:GetPartBoundsInRadius`), providing high accuracy and low execution time.

---

## 1. Geometry Comparison

| Property / Feature | Box Geometry (`hb.Shape = "Box"`) | Sphere Geometry (`hb.Shape = "Sphere"`) |
| :--- | :--- | :--- |
| **Engine Function** | `workspace:GetPartBoundsInBox` | `workspace:GetPartBoundsInRadius` |
| **Primary Dimensions** | `Size: Vector3` | `Radius: number` |
| **Orientation Awareness**| Full CFrame rotation matrix | Radius is isotropic (rotation invariant) |
| **Best Used For** | Melee swings, swords, punches, directed slashes | Radial explosions, slam attacks, persistent auras |

---

## 2. Box Geometry (`Shape = "Box"`)

Box detection tests part overlaps within an oriented 3D bounding box defined by `CFrame` and `Size`:

```lua
local hb = Hitbox.new()
hb.Shape = "Box"
hb.Size = Vector3.new(4, 6, 8) -- (Width=4, Height=6, Depth=8)
hb.CFrame = character.HumanoidRootPart
hb.Offset = CFrame.new(0, 0, -4) -- Position 4 studs in front of character
hb.Duration = 0.25
hb:Start()
```

---

## 3. Sphere Geometry (`Shape = "Sphere"`)

Sphere detection tests part overlaps within a spherical radius around a center position:

```lua
local hb = Hitbox.new()
hb.Shape = "Sphere"
hb.Radius = 12 -- 12 studs radius (24 studs diameter)
hb.CFrame = character.HumanoidRootPart
hb.Duration = 0.3
hb:Start()
```

> [!NOTE]
> If `hb.Radius` is not explicitly set, Axiom fallback calculates the radius as `hb.Size.X * 0.5`.

---

## 4. Position & Dynamic Tracking

The `hb.CFrame` property accepts 4 data types, accommodating static locations as well as dynamic moving rigs:

### A. BasePart (Dynamic Tracking)
Assigning a `BasePart` automatically tracks its position and orientation in real-time every frame:
```lua
hb.CFrame = character.HumanoidRootPart
-- or weapon instance
hb.CFrame = tool.Handle
```

### B. Attachment (Attachment Tracking - Added in v1.4.0)
Assigning an `Attachment` tracks its `WorldCFrame` dynamically:
```lua
hb.CFrame = tool.Handle.HitAttachment
```

### C. CFrame (Static Position)
Assigning a fixed `CFrame` locks spatial detection to a stationary coordinate:
```lua
hb.CFrame = CFrame.new(100, 5, -250)
```

### D. Vector3 (Position Only)
Assigning a `Vector3` constructs a default `CFrame.new(position)`:
```lua
hb.CFrame = Vector3.new(0, 10, 0)
```

---

## 5. Filtering Rules (`Ignore` & `OverlapParams`)

Axiom processes filtering rules efficiently to ignore non-combat targets:

### Basic Ignore List (`hb.Ignore`)
Pass an array of instances (typically the attacking player's character or friendly pets):
```lua
hb.Ignore = { attackerCharacter, petModel }
```

### Custom `OverlapParams` (`hb.OverlapParams`)
For advanced collision group filtering or raycast filter types, assign a custom `OverlapParams` instance:
```lua
local params = OverlapParams.new()
params.CollisionGroup = "CombatOnly"
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { attackerCharacter, workspace.Terrain }

hb.OverlapParams = params
```

> [!TIP]
> Axiom mutates an internal buffer `_activeOverlap` when starting, so changing properties on `hb.Ignore` before `:Start()` will take effect immediately.
