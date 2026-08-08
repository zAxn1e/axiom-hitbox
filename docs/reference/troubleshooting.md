# Troubleshooting & Error Resolution

This guide addresses common error messages, edge cases, and runtime resolution steps.

---

## Common Issues & Fixes

### 1. `Attempt to use Hitbox after Destroy()`
- **Cause**: Code attempted to call `:Start()` or configure properties on a `Hitbox` instance after calling `:Destroy()`.
- **Fix**: Once `hb:Destroy()` is called, discard the reference. Acquire a new instance via `Hitbox.new()`.

---

### 2. `OnHit` callback is not firing
- **Checklist**:
  1. Is the target `Model` equipped with a valid `Humanoid`? (`OnHit` filters for models containing humanoids).
  2. Is the attacker's character listed in `hb.Ignore`? (If `Ignore` contains all target models, no hits will register).
  3. Is `hb.Duration` set too short (e.g. `0.001` seconds)?
  4. Is `hb.CFrame` positioned correctly? Enable `hb.Visualizer = true` in Studio to verify physical alignment.

---

### 3. Target is hit multiple times unexpectedly
- **Cause**: Multiple hitboxes active simultaneously or `HitResetInterval` set too low.
- **Fix**: Check `hb.HitResetInterval`. If you only want a single hit per activation, leave `HitResetInterval = nil`.

---

### 4. `CharacterService` getter yields indefinitely
- **Cause**: Player character is taking longer than 5s to load, or custom rig lacks `HumanoidRootPart` or `Humanoid`.
- **Fix**: Ensure player rig contains standard `HumanoidRootPart` and `Humanoid` instances.
