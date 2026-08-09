---
title: Installation Guide
description: Step-by-step guide to installing Axiom Hitbox Framework via Roblox Creator Store or GitHub packaged releases.
---

# Installation Guide

Axiom Hitbox Framework is distributed exclusively via **packaged builds** to guarantee stability and prevent incomplete runtime imports.

> [!WARNING]
> **Do NOT clone this repository for production game development.**
> 
> The development source code in this repository relies on **Rojo** project structures. Importing `/src` directly into Roblox Studio without proper bundling will result in unresolved module dependencies.

---

## 1. Roblox Creator Store (Recommended)

Installing via the Roblox Creator Store provides seamless studio integration and single-click asset updates:

1. Visit the official [Roblox Creator Store Link](https://create.roblox.com/store/asset/121594941080314).
2. Click **Get Asset** to add Axiom to your Roblox inventory.
3. In Roblox Studio, open **Toolbox** -> **Inventory** -> **Packages**.
4. Drag `Axiom` into `ReplicatedStorage`.

---

## 2. GitHub Releases (Packaged Binaries)

If you prefer offline models or custom Studio setup workflows:

1. Go to [Axiom GitHub Releases](https://github.com/zAxn1e/axiom-hitbox/releases).
2. Download the latest `.rbxm` or `.rbxmx` package file (e.g., `Axiom-v1.4.0.rbxm`).
3. In Roblox Studio Explorer, right-click `ReplicatedStorage` -> **Insert from File...**
4. Select the downloaded `.rbxm` file.

---

## 📁 Recommended Runtime Structure

Once installed, your `ReplicatedStorage` hierarchy will reflect the following structure:

```text
ReplicatedStorage
+-- Axiom
    +-- Hitbox.luau             <-- Main public API
    +-- Core/
    |   +-- Signal.luau         <-- Event dispatch
    |   +-- Timer.luau          <-- Temporal primitive
    |   +-- Scheduler.luau      <-- Shared timer loop
    |   +-- Types.luau          <-- Type definitions
    |   +-- Await/              <-- Coroutine synchronization
    |   +-- Concurrency/        <-- Mutex / Semaphore
    +-- Service/
    |   +-- CharacterService.luau <-- LocalPlayer character helper
    +-- _docs/                  <-- Embedded metadata & license
```

---

## Unsupported Usage Patterns

To ensure server stability and performance, avoid the following anti-patterns:

- [X] Importing `/src` files directly into Studio without Rojo setup.
- [X] Manually copying individual files out of `Axiom.Core`.
- [X] Running Rojo live-syncing output as a production game framework.
- [X] Modifying internal tables (such as `hb._hit` or `hb._humCache`).
