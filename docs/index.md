---
layout: home

hero:
  name: Axiom Hitbox
  text: Server-Authoritative Roblox Hitbox & Infrastructure Framework
  tagline: High-performance spatial detection, explicit lifecycle control, adaptive pooling, and zero-allocation hot paths for scalable Roblox experiences.
  image:
    src: /axiom-big.svg
    alt: Axiom Hitbox Logo
  actions:
    - theme: brand
      text: Quick Start
      link: /getting-started/quick-start
    - theme: alt
      text: API Reference
      link: /api/hitbox
    - theme: alt
      text: View on GitHub
      link: https://github.com/zAxn1e/axiom-hitbox

features:
  - icon: ⚔️
    title: Server-Authoritative Combat
    details: Built specifically for secure, server-validated spatial detection. Client prediction support with zero client authority over damage.
  - icon: ⚡
    title: Zero-Allocation Hot Paths
    details: Pre-allocated spatial parameters, reused OverlapParams buffers, pooled visualizers, and fast-path model lookups for sub-millisecond execution.
  - icon: 🎯
    title: Dual Geometries (Box & Sphere)
    details: Native support for Box (GetPartBoundsInBox) and Sphere (GetPartBoundsInRadius) spatial queries with dynamic CFrame, BasePart, and Attachment tracking.
  - icon: 🔄
    title: Continuous Attack Channels
    details: Built-in HitResetInterval support for channeling skills, laser beams, spin attacks, and persistent damage-over-time auras.
  - icon: 📈
    title: Target Velocity Prediction
    details: Linear, Angular, and combined LinearAngular velocity prediction to eliminate latency discrepancies on high-ping targets.
  - icon: 🛡️
    title: Strict Luau Type Safety
    details: Complete --!strict type coverage across Hitbox, Signal, Timer, Await, and CharacterService for robust Studio Intellisense.
---

## ⚡ Quick Code Sample

```lua
local Axiom = game.ReplicatedStorage:WaitForChild("Axiom")
local Hitbox = require(Axiom.Hitbox)

-- Acquire pooled instance (O(1) allocation)
local hb = Hitbox.new()
hb.Shape = "Box"
hb.Size = Vector3.new(6, 6, 6)
hb.CFrame = character.HumanoidRootPart
hb.Offset = CFrame.new(0, 0, -3)
hb.Duration = 0.25
hb.Ignore = { character }

-- Synchronous exception-safe event connection
hb.OnHit:Connect(function(model, humanoid, part)
    humanoid:TakeDamage(25)
end)

-- Activate detection
hb:Start()

-- Recycle back to adaptive pool when finished
hb:Destroy()
```

---

## 🧭 Architecture Overview

Axiom separates **infrastructure primitives** from **gameplay logic**.

```mermaid
graph TD
    subgraph Gameplay ["Gameplay Layer (Game Code)"]
        CombatLogic["Combat Manager / Skill Handlers"]
        DamageRules["Damage Formulas & Status Effects"]
        VFX["Visual & Audio FX (Client)"]
    end

    subgraph AxiomFramework ["Axiom Hitbox Framework"]
        HitboxCore["Hitbox Core Engine"]
        PoolManager["Adaptive Pool O(1)"]
        FSM["Finite State Machine"]
    end

    subgraph AxiomCore ["Axiom Core Infrastructure"]
        Signal["Signal (FireSafe)"]
        Timer["Timer & Scheduler"]
        Await["Await Coroutine Sync"]
        CharService["CharacterService"]
    end

    subgraph RobloxEngine ["Roblox Engine Runtime"]
        RunService["RunService Heartbeat"]
        SpatialQuery["WorldRoot Spatial Queries"]
    end

    CombatLogic --> HitboxCore
    DamageRules --> Signal
    HitboxCore --> PoolManager
    HitboxCore --> FSM
    HitboxCore --> Signal
    HitboxCore --> SpatialQuery
    HitboxCore --> RunService
    CharService --> Await
```

- **Infrastructure First**: Combat rules, damage multipliers, combos, and animations live in your game code. Axiom handles spatial queries, timing, pooling, and synchronization.
- **Server Authority**: Combat detection executes on the server. Clients may run local hitboxes for visual feedback or prediction only.
- **Deterministic Cleanup**: Explicit lifecycle methods (`Start`, `Stop`, `Destroy`) ensure no hanging connections or memory leaks.

---

## 📦 Ready to Install?

Check out our [Installation Guide](/getting-started/installation) to set up Axiom in your Roblox Studio project using the Roblox Creator Store package or packaged GitHub Releases.
