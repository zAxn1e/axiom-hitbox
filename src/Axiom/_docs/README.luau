--[[

	Axiom Hitbox Framework Documentation
	====================================
	
	Author: Iv_0x
	
	Core Version: 1.4.0
	Docs Version: 1.4.0
	Docs Status: Up-to-date
	
	Compatibility:
	- Axiom Hitbox >= 1.4.0
	- Axiom Core >= 1.4.0
	- Roblox Luau runtime (!strict mode supported)
	
	Last Updated: 2026-08-05
	
	====================================
	
	This document explains how to use the Hitbox system,
	its lifecycle, and best practices.
	
	This file is documentation-only.
	It is NOT required by any runtime module.
	
	----------------------------------------------------
	1. Overview
	----------------------------------------------------
	
	Hitbox is a high-performance, server-authoritative
	spatial query system designed for scalable combat
	and long-running Roblox servers.
	
	The framework focuses on:
	- Spatial detection (Box & Sphere geometry + time)
	- Continuous / Channeling hit intervals
	- Velocity Prediction (Linear & Angular)
	- A clear lifecycle (Start / Stop / Destroy)
	- Automatic pooling with O(1) tracking & adaptive shrinking
	- Zero coupling with combat logic
	
	----------------------------------------------------
	Authority Model
	----------------------------------------------------
	
	Hitbox is designed to be used in a server-authoritative
	environment.
	
	While the system can technically run on the client,
	it must not be used to determine gameplay outcomes.
	
	Client-side usage is intended only for:
	- Visualization and debug rendering
	- Prediction or preview systems
	- Cosmetic and non-authoritative effects
	
	----------------------------------------------------
	2. Basic Usage
	----------------------------------------------------
	
	Example: Simple melee hitbox
	
		local Hitbox = require(path.to.Axiom.Hitbox)
		
		local hb = Hitbox.new()
		hb.Size = Vector3.new(6,6,6)
		-- Supports BasePart, Attachment (dynamic), or CFrame (static)
		hb:SetCFrame(character.HumanoidRootPart) 
		hb.Duration = 0.2
		hb.Ignore = { character }
		
		hb.OnHit:Connect(function(model, humanoid, part)
			humanoid:TakeDamage(25)
		end)
		
		hb:Start()
		
	----------------------------------------------------
	3. Lifecycle
	----------------------------------------------------
	
	Hitbox has a clear lifecycle:
	
		Hitbox.new()     -- acquire from pool
		Hitbox:Start()   -- begin detection
		Hitbox:Stop()    -- stop detection
		Hitbox:Destroy() -- recycle back to pool
		
	Important:
	- Destroy() does NOT delete the object.
	- It returns the hitbox back to the internal pool.
	- Reuse is automatic and transparent.
	- When a Hitbox is destroyed, all event connections
	  are cleared automatically.
	
	Always call Destroy() when finished.
	
	----------------------------------------------------
	4. Events
	----------------------------------------------------
	
	OnStart(hitbox)
		Fires when the hitbox starts.
		
	OnUpdate(deltaTime, hitbox)
		Fires every Heartbeat while active.
		
	OnHit(model, humanoid, part)
		Fires once per humanoid per activation (or per HitResetInterval).
		
	OnStop(hitbox)
		Fires when the hitbox stops.
		
	----------------------------------------------------
	5. Properties
	----------------------------------------------------

	Size : Vector3
		Size of the hitbox volume (default Vector3.new(4,4,4)).
		
	Shape : "Box" | "Sphere" (New in v1.4.0)
		Spatial query type. Default is "Box" (GetPartBoundsInBox).
		"Sphere" uses GetPartBoundsInRadius.
		
	Radius : number (New in v1.4.0)
		Radius used when Shape = "Sphere" (default 4).
		
	HitResetInterval : number? (New in v1.4.0)
		Interval in seconds to clear hit memory for continuous/channeling attacks.
		
	CFrame : CFrame | BasePart | Attachment
		World-space position/origin of the hitbox.
		BasePart and Attachment automatically track transform in real-time.
		
	Offset : CFrame (optional)
		Local offset applied after the base CFrame.
		
	Duration : number
		How long the hitbox stays active (seconds).
		If not set, defaults to infinite duration.
		
	Ignore : {Instance}
		List of instances excluded from detection.
		
	OverlapParams : OverlapParams (optional)
		Custom spatial filtering configuration.
		
	Visualizer : boolean
		Enables hitbox visualization for development.
		
	----------------------------------------------------
	6. Prediction (New in v1.3.0)
	----------------------------------------------------
	
	Hitbox now supports velocity-based prediction to compensate
	for network latency or fast-moving anchors.
	
	UsePrediction : boolean
		Enables CFrame extrapolation.
		
	PredictionTime : number
		Time in seconds to look ahead (e.g., 0.06 for ~4 frames).
		
	PredictionMethod : string
		- "Linear" : Uses AssemblyLinearVelocity only.
		- "Angular" : Uses AssemblyAngularVelocity only.
		- "LinearAngular" : Uses both (expensive but accurate).
		
	Example:
		hb.UsePrediction = true
		hb.PredictionTime = 0.1
		hb.PredictionMethod = "Linear"
		
	----------------------------------------------------
	7. Signal System & Await
	----------------------------------------------------
	
	Hitbox uses Axiom Core's 'Signal' and 'Await' modules.
	
	Signal:
	- Immediate execution (FireFast)
	- Exception safety (FireSafe)
	- No yielding
	
	Await (v1.3.0):
	- A coroutine-based synchronization library.
	- Replaces Promise for internal task management.
	- Supports Cancellation Tokens.
	
	----------------------------------------------------
	8. Pooling Behavior
	----------------------------------------------------
	
	Hitbox instances are pooled automatically via 'Axiom Core Pool'.
	
	- Adaptive Shrinking: The pool automatically removes 
	  unused objects if idle for >30 seconds.
	- Pre-warming: The pool initializes with ~30 objects.
	
	Users do NOT need to manage the pool manually.
	
	----------------------------------------------------
	9. Advanced Usage: State Checking
	----------------------------------------------------
	
	You can query the current state of a Hitbox:
	
		if hb:Is("Active") then
			print("Hitbox is running")
		end
		
		-- Available states: "Idle", "Active", "Stopped"
		print(hb:GetState()) 

	----------------------------------------------------
	10. Integration with Await (Core v1.3.0)
	----------------------------------------------------
	
	Axiom Core provides advanced synchronization tools useful
	for complex combat logic.
	
	-- Cancellation Token Example --
	local token = Await.Token()
	
	-- Cancel logic if the caster gets stunned
	Caster.OnStunned:Connect(function()
		token:Cancel("Stunned")
	end)
	
	-- Safe sleep with cancellation
	Await.Try(function()
		Await.Sleep(1.5, token) -- Throws if cancelled
		hb:Start()
	end)
	
	-- Concurrency Primitives --
	Await.Mutex()      -- Exclusive access locks
	Await.Semaphore(n) -- Bounded concurrency
	Await.Retry(fn, 3) -- Auto-retry logic
	
	----------------------------------------------------
	11. Best Practices
	----------------------------------------------------
	
	+ Keep hitbox durations short.
	+ Always call Destroy() when done.
	+ Use 'Prediction' for projectiles or fast dashes.
	+ Reuse Hitbox for melee, magic, and AOE.
	+ Use Visualizer only during development.
	+ Leverage Await.All for syncing multi-stage skills.
	
	----------------------------------------------------
	12. License
	----------------------------------------------------
	
	See LICENSE.lua for license information.
	
]]

return {}