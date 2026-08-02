--[[

	Axiom Hitbox
	============
	
	Name: Axiom Hitbox
	Author: Iv_0x
	
	Version: 1.4.0
	Stability: Stable
	
	Description:
	A lightweight, server-authoritative hitbox system focused on
	deterministic spatial detection, explicit lifecycle control,
	and long-running server stability.
	
	Architecture:
	- Hitbox is the public-facing product
	- Axiom Core provides internal infrastructure primitives
	
	Modules:
	- Hitbox        (spatial detection and lifecycle)
	- Pool          (object reuse and memory stability)        [internal]
	- State         (lifecycle state machine)                  [internal]
	- Signal        (synchronous event primitive)              [internal, required]
	- Timer         (temporal primitive)                       [optional utility]
	- TimerScheduler (shared timer update loop)                [optional utility]
	- Types         (public type definitions)
	
	Documentation:
	- README.lua
	- PERFORMANCE.md
	- CONTRIBUTING.md
	- CHANGELOG.lua
	
	License:
	- LICENSE.lua
	
	API Stability:
	Public Hitbox APIs are considered stable within the 1.x series.
	Internal implementation details (Core modules) may change
	between minor versions without notice.
	
	Notes:
	This file is metadata only.
	It is not required by any runtime module and has
	no impact on performance or behavior.
    
--]]
