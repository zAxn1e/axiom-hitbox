# Axiom

A lightweight, server-authoritative framework for Roblox game development, providing high-performance hitbox detection, synchronization primitives, and infrastructure utilities.

Axiom focuses on **determinism, performance, and stability** for long-running Roblox servers.

---

## ✨ Overview

Axiom is a modular framework designed for scalable Roblox experiences. It provides:

- **Hitbox Framework** – deterministic, pooled spatial detection
- **Core Primitives** – `Signal`, `Await`, `Timer`, `State`
- **Service Layer** – character access and lifecycle utilities

Axiom does **not** include gameplay rules — it is infrastructure-first by design.

---

## 🚀 Features

- Server-authoritative hitbox system
- Explicit lifecycle (`Start / Stop / Destroy`)
- Adaptive object pooling & reuse
- Optional **velocity prediction (linear / angular)**
- Full `--!strict` typing across Hitbox & Core
- Lightweight synchronous Signal system
- Coroutine-based Await synchronization
- Token-based cancellation & timeouts
- Character helpers with typed access
- Designed for **low allocation & low GC pressure**

> Combat logic, damage systems, VFX, and gameplay orchestration are intentionally **not included**.

---

## ⚠️ Important Notice

This repository contains the **development source** of Axiom.

- Layout is designed for **Rojo workflows**
- Code here may be **unstable or ahead of releases**
- Public API may change without notice

➡️ **Do NOT use this repository directly in production**  
➡️ **Install only packaged releases**

---

## 📦 Installation

Use **only packaged builds**, not git clone.

### 1️⃣ Roblox Creator Store (recommended)

- Install as Roblox package
- Receive automatic updates

> 🔗 [Creator Store link](https://create.roblox.com/store/asset/121594941080314)

---

### 2️⃣ GitHub Releases (packaged builds)

- Download `.rbxm / .rbxmx`
- Insert into Studio

> 🔗 [GitHub Releases link](https://github.com/zAxn1e/axiom-hitbox/releases)

---

### ⛔ Not Supported — Do NOT do this

- cloning this repo for production use
- importing `/src` directly into Studio
- using Rojo output as game-runtime framework
- copying internal modules manually

Supported only for:

- framework development
- contribution
- debugging

---
<!-- 
## 📁 Recommended runtime structure

````
ReplicatedStorage
└── Axiom
    ├── Core
    ├── Service
    ├── _docs
    └── Hitbox
```` -->

### Example require

```lua
local Axiom = game.ReplicatedStorage:WaitForChild("Axiom") -- path.to.Axiom
local Hitbox = require(Axiom.Hitbox) -- Hitbox
local Await = require(Axiom.Core.Await) -- Await
local CharacterService = require(Axiom.Service.CharacterService) -- CharacterService
```

---

## ⚔️ Quick Start - Hitbox

```lua
local Axiom = game.ReplicatedStorage:WaitForChild("Axiom")
local Hitbox = require(Axiom.Hitbox)

local hb = Hitbox.new()
hb.Size = Vector3.new(6, 6, 6)

-- Supports BasePart (dynamic) or CFrame (static)
hb.CFrame = character.HumanoidRootPart -- or hb:SetCFrame(...)

hb.Offset = CFrame.new(0, 0, -3)
hb.Duration = 0.25
hb.Ignore = { character }

hb.OnHit:Connect(function(model, humanoid, part)
    humanoid:TakeDamage(25)
end)

hb:Start()

-- recycle back to pool when done
hb:Destroy()
```

---

## 🧭 Authority Model

Hitbox is designed for **server-authoritative combat**.

Client usage is allowed only for:

* preview / prediction
* local effects
* visualization

🚫 **Do not resolve damage on client**
🚫 **Do not trust client hits**

---

## 🧩 Hitbox API

### Properties

| Property           | Type                                     | Notes             |
| ------------------ | -----------------------------------------| ----------------- |
| `Size`             | `Vector3`                                | box bounds        |
| `CFrame`           | `CFrame or BasePart`                     | auto-tracking basepart supported |
| `Offset`           | `CFrame`                                 | local offset      |
| `Duration`         | `number`                                 | seconds           |
| `Ignore`           | `{ Instance }`                           | excluded          |
| `OverlapParams`    | `OverlapParams?`                         | custom filtering  |
| `Visualizer`       | `boolean`                                | debug only        |
| `UsePrediction`    | `boolean`                                | enable prediction |
| `PredictionTime`   | `number`                                 | default 0.06      |
| `PredictionMethod` | `"Linear", "Angular", "LinearAngular"`   |                   |

---

### Events

| Event                          | Description                             |
| ------------------------------ | --------------------------------------- |
| `OnStart(hitbox)`              | when activated                          |
| `OnUpdate(dt, hitbox)`         | heartbeat loop                          |
| `OnHit(model, humanoid, part)` | **fires once per model per activation** |
| `OnStop(hitbox)`               | when stopped                            |

---

### Lifecycle methods

* `Hitbox.new()`
* `:Start()`
* `:Stop()`
* `:Destroy()` - returns to internal pool

> After `Destroy()`, **do not continue using the reference**

---

## 🎯 Hitbox Usage Guidelines (important)

### ✔️ Do this

* keep durations small (0.1–0.3s typical melee)
* reuse instances via pooling
* always call `Destroy()`
* ignore attacker in `Ignore`
* enable Visualizer only in dev
* prefer server authority

### ❌ Don't do this

* leave hitboxes running forever
* large 30×30×30 spam every frame
* do combat resolution on client
* reuse object **after Destroy**
* mutate internal tables like `_hit`

---

### State Methods

* `:GetState()` - returns the current state ("Idle", "Active", "Stopped")
* `:Is(state)` - checks if the hitbox is in the specified state
* `:IsActive()` - checks if the hitbox is currently active

## 🏃 Prediction Usage

```lua
hb.UsePrediction = true
hb.PredictionTime = 0.08
hb.PredictionMethod = "LinearAngular"
```

Best for:

* dashes
* fast projectiles
* high-ping environments

---

## 🧪 Overlap & Ignore rules

* OverlapParams **copied internally**
* `Ignore` list applied when no OverlapParams provided
* OnHit triggers:

✔ once per **humanoid model** per activation
✔ ignores duplicate parts
✔ caches humanoids for performance

---

## 📊 Pooling

Hitbox uses adaptive pool:

* pre-warms ~30 objects
* idle shrink after 30s
* constant-time acquire/release

Debug:

```lua
print(Hitbox.GetPoolStats())
```

---

## 🕓 Await — Core Synchronization

Key primitives implemented:

* `Await.Signal`
* `Await.Sleep`
* `Await.All`
* `Await.Any`
* `Await.Token()` (cancellation)
* debouncing / throttling
* `Mutex` + `Semaphore`
* `Retry`, `Debounce`, `Throttle`, `Queue`

---

## 👤 CharacterService

Provides safe LocalPlayer character access:

* `GetCharacter`
* `GetHumanoid`
* `GetRoot`
* `GetAnimator`
* `Get()`

All yield until ready.

---

## 🧪 Not Included (by design)

* damage formulas
* stun / poise / combo logic
* ability logic
* VFX/SFX
* animations
* state machines

---

## 📌 Project Status

* Active development
* API surface intentionally small
* Internal structures may change

---

## 📜 License

See [LICENSE.lua](./LICENSE.md) for license information.

---

## 👤 Author

**Iv_0x**