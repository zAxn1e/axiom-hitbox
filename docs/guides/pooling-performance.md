# Object Pooling & Performance Best Practices

Axiom Hitbox uses an internal adaptive object pool (`_POOL`) to maintain zero allocation pressure during combat.

---

## 1. How the Adaptive Pool Works

- **Warm Allocation**: On initial require, 30 `Hitbox` instances are pre-allocated.
- **Constant Time ($O(1)$)**: `:acquire()` (`Hitbox.new()`) pops an instance from the array in $O(1)$ time. `:release()` (`hb:Destroy()`) resets state and pushes it back in $O(1)$ time.
- **Adaptive Shrinking**: If a server experiences a sudden spike (e.g. 200 hitboxes allocated), the pool temporarily expands. After 30 seconds of inactivity, an adaptive background thread shrinks excess instances back down to the baseline size of 20.

---

## 2. Best Practice Rules

### ✅ Always call `hb:Destroy()`
Never leave active or stopped hitboxes un-destroyed. Calling `:Destroy()` is mandatory to return instances to the pool and disconnect signal handlers.

### ❌ Do NOT use references after `Destroy()`
Once `hb:Destroy()` is called, the reference points to a pooled instance that may be acquired by another script. Modifying it post-destroy corrupts state.

### ✅ Reuse `Ignore` tables where possible
Assigning an existing table reference to `hb.Ignore` avoids table instantiation overhead.

### Check Pool Diagnostics
Monitor active vs available pool statistics in dev environments:
```lua
print(Hitbox.GetPoolStats()) -- Outputs { available = 28, inUse = 2 }
```
