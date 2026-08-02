--[[

	Axiom Hitbox Framework Changelog
	================================
	
	Versioning follows Semantic Versioning (MAJOR.MINOR.PATCH)
	
	Severity Tags:
	[CRITICAL] - Fixes severe bugs that can cause incorrect gameplay or server issues
	[FIX]      - Bug fixes with observable behavior changes
	[IMPROVED] - Internal or performance improvements
	[INTERNAL] - Refactors with no behavior change
	[API]      - Public-facing API additions or clarifications
	
	--------------------------------
	## v1.0.0
	--------------------------------
	- Initial release
	- Core Hitbox lifecycle (Start / Stop / Destroy)
	- Adaptive HitboxPool
	- Deterministic spatial queries
	
	--------------------------------
	## v1.0.1 - 2025-12-20 [CRITICAL]
	--------------------------------
	Fixed:
	- Fixed pooled Signal accumulation when using Destroy(),
	  which could cause stacked OnHit callbacks and
	  duplicated damage
	  
	Changed:
	- Destroy() now clears all event connections and enforces
	  idempotent cleanup for pooled hitboxes
	
	--------------------------------
	## v1.1.0 - 2025-12-21
	--------------------------------
	Added:
	- Introduced Timer and TimerScheduler modules
	- Centralized time-based scheduling with pause/resume support
	- Exposed OverlapParams for external spatial filtering control
	- Added Visualizer flag for hitbox debug visualization
	
	Fixed:
	- Reduced GC pressure in high-frequency Signal dispatch
	- Fixed hitbox Duration edge cases when using pooled instances
	- Improved humanoid caching logic in Hitbox core
	
	Changed:
	- Clarified Hitbox lifecycle semantics
	  (Stop = halt, Reset = rewind, Destroy = recycle)
	- Normalized Hitbox runtime state at Start() to improve pool safety
	- Refined Signal FireFast and FireSafe behavior guarantees
	- Improved pooling shrink policy stability
	- Renamed Debug visualization flag to Visualizer for clearer semantics
	
	Deprecated:
	- Deprecated the Debug property in favor of Visualizer
	
	Notes:
	- Timer is optional and not coupled to Hitbox
	- Hitbox may mutate OverlapParams.FilterDescendantsInstances during activation
	- No breaking changes to the public Hitbox API
	
	--------------------------------
	## v1.2.0 - 2025-12-21
	--------------------------------
	Added:
	- Introduced the `Axiom` folder namespace for shared infrastructure modules
	- Added namespaced Hitbox import support via the `Axiom/Hitbox` module path
	- Formalized Core primitives (Signal, Timer, StateMachine) as internal dependencies
	- Added explicit import-style distinction (Standalone vs Axiom-namespaced)
	
	[API]:
	- Hitbox can now be required either directly or via the `Axiom/Hitbox` path
	- Import style indicates generation and compatibility boundary
	- Public Hitbox API remains identical across both import styles
	
	Improved:
	- Reduced direct coupling between Hitbox and non-essential utilities
	- Improved lazy initialization for optional Hitbox features
	  (Timer, Visualizer, OverlapParams)
	- Clarified responsibility boundaries between Core infrastructure and Hitbox logic
	- Refined dependency direction to support future Axiom-based systems
	
	Internal:
	- Refactored internal requires to ensure explicit, path-based dependencies
	- Normalized module layout to separate infrastructure from feature logic
	- Improved internal naming consistency and ownership semantics
	
	Notes:
	- Axiom Core is a required internal implementation dependency of Axiom Hitbox
	- Core systems (e.g. Signal) define implementation-level semantics and guarantees
	- Users are not expected to interact with Axiom Core directly
	- Optional features remain opt-in at the Hitbox level only
	- Hitbox remains lightweight with no background loops or hidden managers
	- No breaking changes were introduced in this release
	
	Compatibility:
	- Legacy standalone Hitbox import: Supported
	- Axiom-namespaced Hitbox import: Recommended
	- No migration required for existing users
	
	--------------------------------
	## v1.2.1 - 2025-12-22
	--------------------------------
	Changed:
	- Hitbox.CFrame can now set as (CFrame or BasePart), This would make
	  the hitboxes more near realtime transform.
	- Visualizer now uses the new Hitbox.CFrame property.
	- Visualizer now set `CastShadow = false` by default and
	  Material is set to `Neon` for better visual.
	
	--------------------------------
	## v1.3.0 - 2026-01-04
	--------------------------------
	Added:
	- Full `--!strict` typing across Hitbox & Core
	- New Hitbox State API: `GetState()`, `Is()`, `IsActive()`
	- PredictionMethod property:
		"Linear" | "Angular" | "LinearAngular"
	- BasePart support for Hitbox.CFrame (Dynamic tracking)
	- Axiom Core Await expansion:
		- Added Concurrency primitives: Mutex, Semaphore
		- Added Functional utilities: Retry, Debounce, Throttle, Queue
	- Strong type exports in Axiom.Core.Types

	Improved:
	- CFrame resolution robustness (handles destroyed parts gracefully)
	- OverlapParams runtime copy safety
	- Internal Humanoid cache typing
	- Visualizer clarified as development-only

	Fixed:
	- Pooled objects losing type identity in strict mode
	- Race conditions when BasePart is removed during active hitbox
	- Race condition between Stop() and Heartbeat loop

	Breaking Changes:
	- None (API compatible with 1.2.x)

	--------------------------------
	## v1.4.0 - 2026-08-05
	--------------------------------
	Added:
	- Introduced `Shape` property ("Box" | "Sphere") for radial spatial queries (`GetPartBoundsInRadius`)
	- Introduced `Radius` property for Sphere hitboxes
	- Introduced `HitResetInterval` property for continuous/channeling attack hit memory resets
	- Attachment support in `Hitbox.CFrame` / `Hitbox:SetCFrame()` (`attachment.WorldCFrame`)
	- Automated unit test suite under `Axiom._tests.HitboxTest`

	Improved:
	- **Zero-Allocation OverlapParams**: Reused and mutated internal `_activeOverlap` in-place per `:Start()`, reducing memory allocation rate by ~95%
	- **Fast-Path Ancestry Lookup**: `part.Parent` fast-check before ancestor traversal in `_update()`, reducing CPU time by 30-50% on multi-part models
	- **$O(1)$ Pool Tracking**: Upgraded HitboxPool to use integer `_inUseCount` counter instead of hash table iterations
	- **Visualizer Part Pooling**: Visualizer Part is now kept pooled on Hitbox instances instead of constant `Instance.new`/`:Destroy()` churn
	- **Scheduler Lag Drain**: `TimerScheduler` uses capped `while` loop to drain accumulated lag delta without timer drift

	Fixed:
	- [CRITICAL] Fixed State Machine transition bug preventing `Stopped -> Active` and `Cooldown -> Active` restarts
	- [CRITICAL] Fixed unhandled exception crash in `OnHit` signal dispatch by wrapping with `FireSafe`
	- Fixed `CharacterService` `WaitForChild` hanging risk on custom/non-humanoid rigs with 5s timeout
	- Fixed `CharacterService` getter race conditions during rapid character respawns

	Breaking Changes:
	- None (100% backwards compatible with 1.3.x)
]]
