# Debug Visualizer Workflows

Axiom Hitbox includes a built-in visualizer for debugging hitbox positions, sizes, orientations, and durations inside Roblox Studio.

---

## 1. Enabling the Visualizer

Set `Visualizer = true` on any `Hitbox` instance before calling `:Start()`:

```lua
local hb = Hitbox.new()
hb.Size = Vector3.new(4, 5, 6)
hb.CFrame = character.HumanoidRootPart
hb.Offset = CFrame.new(0, 0, -3)

-- Enable visualizer for testing
hb.Visualizer = true

hb:Start()
```

---

## 2. Visualizer Behavior & Rendering

- **Box Hitboxes**: Renders a translucent neon red `Part` (`Color3.fromRGB(255, 60, 60)`, `Transparency = 0.7`, `CastShadow = false`) matching `hb.Size` and `hb.CFrame * hb.Offset`.
- **Sphere Hitboxes**: Renders a translucent neon red spherical `Part` (`Shape = Enum.PartType.Ball`) with diameter `Radius * 2`.
- **Part Pooling**: In v1.4.0, visualizer parts are pooled directly on the `Hitbox` instance. They are set to `Parent = workspace` during `:Start()` and hidden (`Parent = nil`) during `:Stop()` / `:Destroy()`, avoiding constant `Instance.new` / `:Destroy()` churn.

> [!WARNING]
> Visualizer rendering introduces mild DOM overhead in Roblox Studio. Disable `Visualizer = false` before publishing production game builds.
