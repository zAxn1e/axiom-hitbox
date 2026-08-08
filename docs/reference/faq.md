# Frequently Asked Questions (FAQ)

### Q: Why is Axiom designed for server-only combat detection?
**A:** In online multiplayer games, client-side hit detection is vulnerable to exploiters sending fake hit packets or spoofing positions. Running spatial queries on the server guarantees security and determinism.

### Q: Can I run Axiom Hitbox on the client for prediction or visuals?
**A:** Yes! You can run a `Hitbox` on the client for visual feedback or client-side prediction previewing. However, damage application must always take place on the server.

### Q: Does Axiom replace Raycast Hitbox?
**A:** Axiom Hitbox provides high-performance volume-based spatial detection (`GetPartBoundsInBox` and `GetPartBoundsInRadius`) with dynamic CFrame tracking, prediction, zero allocations, and $O(1)$ pooling. It is designed as lightweight infrastructure for fast combat systems.

### Q: Do I need to create pools manually?
**A:** No. `Hitbox.new()` automatically manages instances through an internal adaptive pool. Simply call `hb:Destroy()` when finished.

### Q: How do I handle continuous tick damage (e.g. flamethrowers)?
**A:** Set `hb.HitResetInterval` to the desired tick interval (e.g. `0.2` seconds). Axiom will reset hit memory automatically every `0.2` seconds while active.
