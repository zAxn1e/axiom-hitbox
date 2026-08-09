---
title: Quick Start Guide
description: Build your first server-authoritative melee hitbox in Roblox Studio with adaptive object pooling and dynamic tracking.
---

# Quick Start Guide

This guide will walk you through creating your first server-authoritative melee hitbox using Axiom Hitbox Framework v1.4.0.

---

## 1. Requiring the Framework

Import the `Hitbox` class from the `Axiom` package in `ReplicatedStorage`:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Axiom = ReplicatedStorage:WaitForChild("Axiom")
local Hitbox = require(Axiom.Hitbox)
```

---

## 2. Basic Melee Hitbox Example

Here is a complete, production-ready server script that executes a melee attack on player activation:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Axiom = ReplicatedStorage:WaitForChild("Axiom")
local Hitbox = require(Axiom.Hitbox)

local function executeMeleeSwing(player: Player)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end

    -- Acquire a pooled hitbox instance
    local hb = Hitbox.new()

    -- Configure spatial query bounds
    hb.Shape = "Box"
    hb.Size = Vector3.new(5, 6, 4)

    -- Attach to character's HumanoidRootPart with an offset (3 studs forward)
    hb.CFrame = character.HumanoidRootPart
    hb.Offset = CFrame.new(0, 0, -3)

    -- Set active duration (0.2 seconds for a fast melee swing)
    hb.Duration = 0.2

    -- Exclude attacker's character from hit detection
    hb.Ignore = { character }

    -- Connect OnHit event (fires once per target model per activation)
    local connection
    connection = hb.OnHit:Connect(function(targetModel: Model, targetHumanoid: Humanoid, hitPart: BasePart)
        print(`[Combat] Hit target: {targetModel.Name} on part: {hitPart.Name}`)
        
        -- Apply damage on server
        targetHumanoid:TakeDamage(15)
    end)

    -- Start spatial detection heartbeat loop
    hb:Start()

    -- Recycle hitbox back to adaptive pool when destroyed
    -- Note: hb:Destroy() automatically cleans up connections and returns instance to pool
    task.delay(hb.Duration + 0.05, function()
        hb:Destroy()
    end)
end
```

---

## 3. Step-by-Step Breakdown

### Step A: Instantiation via Pooling
```lua
local hb = Hitbox.new()
```
`Hitbox.new()` retrieves a retained instance from an internal object pool (`_POOL`). The pool pre-warms 30 instances on initial require, avoiding repeated framework-side table construction during active gameplay.

### Step B: Tracking Target CFrame
```lua
hb.CFrame = character.HumanoidRootPart
hb.Offset = CFrame.new(0, 0, -3)
```
Assigning a `BasePart` directly to `hb.CFrame` enables **dynamic real-time transformation tracking**. Every frame during `Heartbeat`, Axiom automatically queries the current position of the root part and applies `hb.Offset`.

### Step C: Event Connection
```lua
hb.OnHit:Connect(function(model, humanoid, part) ... end)
```
`hb.OnHit` is fired using exception-safe `FireSafe` dispatch. If a callback throws an error, other callbacks and the server `Heartbeat` thread continue executing without breaking.

### Step D: Execution & Cleanup
```lua
hb:Start()
-- ... later
hb:Destroy()
```
`:Start()` changes the state from `Idle` to `Active` and binds to `RunService.Heartbeat`. Calling `:Destroy()` stops detection, disconnects listeners, resets properties, and returns the instance to the pool for reuse.

---

## 4. Next Steps

- Explore [Box vs Sphere Spatial Detection](/concepts/spatial-detection)
- Learn how [Velocity Prediction](/concepts/prediction) prevents lag whiffs
- Implement [Continuous & Channeling Attacks](/concepts/continuous-attacks)
