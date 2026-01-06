--[[

	CONTRIBUTING.md
	===============

	Axiom Hitbox Framework – Contribution Guidelines

	Author: Iv_0x

	Core Version: 1.3.0
	Docs Version: 1.3.0
	Last Updated: 2025-01-04

	----------------------------------------------------
	Purpose
	----------------------------------------------------
	
	Axiom Hitbox is built on top of Axiom Core.

	Axiom Core provides required infrastructure primitives
	(such as Signal) used internally by Hitbox.

	Contributors should treat Core modules as
	implementation details unless explicitly documented
	as public API.
	
	This document defines the rules, boundaries, and design
	principles for contributing to the Axiom Hitbox Framework.

	This framework is designed as low-level infrastructure.
	Contributions must preserve its performance, determinism,
	and strict separation of responsibilities.

	This is NOT a gameplay system.

	----------------------------------------------------
	1. Scope of the Framework
	----------------------------------------------------

	The Axiom Hitbox Framework is responsible for:

	- Spatial detection (geometry + time)
	- Lifecycle management (Start / Stop / Destroy)
	- Deterministic hit reporting
	- Memory-stable pooling for long-running servers
	- Infrastructure-level timing primitives (Timer)

	The framework is NOT responsible for:

	- Damage calculation
	- Combat rules or logic
	- Status effects or buffs
	- Visual or audio effects (beyond simple visualization)
	- Camera or UI behavior
	- Ability or skill logic

	Any contribution that blurs this boundary will be rejected.

	----------------------------------------------------
	2. Design Principles
	----------------------------------------------------

	All contributions must adhere to the following principles:

	- Infrastructure over gameplay
	- Determinism over convenience
	- Explicit orchestration over implicit behavior
	- Performance over flexibility
	- Clear ownership of responsibility

	If execution order, timing coordination, or game rules
	are required, they must live outside the Hitbox framework.

	----------------------------------------------------
	3. Module Boundaries
	----------------------------------------------------

	The framework is divided into conceptual layers:

	- Infrastructure
	  - Signal
	  - Pooling
	  - State management
	  - Timer and scheduling primitives

	- Mechanism
	  - Hitbox core logic
	  - Spatial queries
	  - Detection lifecycle

	Modules in these layers must not depend on:

	- Gameplay systems
	- Combat resolvers
	- Effect handlers
	- External orchestration logic

	Internal modules are implementation details and must
	not be exposed as public API.

	----------------------------------------------------
	4. Performance Rules
	----------------------------------------------------

	The Hitbox framework is designed for hot paths.

	Contributors MUST follow these rules:

	- No yielding in hot paths
	- No task.wait(), wait(), or :Wait()
	- No Roblox Instance creation inside active loops
	- No per-frame table allocation
	- No dynamic memory churn during detection

	All allocations should happen during setup or pooling.

	----------------------------------------------------
	5. Signal Usage Rules
	----------------------------------------------------

	Signals are infrastructure primitives.

	Rules:

	- Signals must not enforce execution order
	- No priority-based dispatch
	- Callbacks must be synchronous
	- Callbacks must not yield

	If ordered execution is required, implement a
	dedicated orchestration layer outside the framework.

	----------------------------------------------------
	6. Pooling & Lifecycle Rules
	----------------------------------------------------

	Pooling behavior must remain:

	- Automatic
	- Transparent
	- Deterministic

	Rules:

	- Destroy() returns objects to the pool
	- Objects must not be used after Destroy()
	- Pool internals must remain private
	- Users must not be required to manage pools manually

	Any change to pooling behavior must be justified
	with measurable performance impact.

	----------------------------------------------------
	7. Type & Strictness Policy
	----------------------------------------------------

	Type checking is used selectively.

	Rules:

	- Core modules MUST use --!strict
	- Hitbox core now uses --!strict
	- Runtime performance must not degrade
	- any-casts allowed only during construction

	----------------------------------------------------
	8. What Not To Add
	----------------------------------------------------

	The following will NOT be accepted:

	- Damage calculation logic
	- Combat rule enforcement
	- Status or effect systems
	- Priority-based signal dispatch
	- Debug logic that alters runtime behavior
	- Visualization systems beyond simple hitbox geometry
	- Engine-specific shortcuts that reduce portability

	Feature requests that belong to higher layers
	should be implemented outside this framework.

	----------------------------------------------------
	9. Deprecation Policy
	----------------------------------------------------

	Public APIs may be deprecated when necessary.

	Rules:

	- Deprecations must be explicitly documented
	- Deprecated APIs must continue to function for at least
	  one minor version when possible
	- Silent behavior changes are not allowed

	Deprecation notes must be added to:
	- CHANGELOG
	- README (if public-facing)

	----------------------------------------------------
	10. Testing Expectations
	----------------------------------------------------

	Contributions should be tested under:

	- Multiple simultaneous hitboxes
	- Long-running server conditions
	- High-frequency activation
	- Reuse after pooling

	Any change that affects performance or lifecycle
	must include a rationale and testing notes.

	----------------------------------------------------
	11. Documentation Changes
	----------------------------------------------------

	Public-facing changes must be reflected in:

	- README.lua
	- Type definitions (Types.lua)
	- CHANGELOG

	Internal refactors do not require documentation
	unless they affect observable behavior.

	----------------------------------------------------
	12. Final Notes
	----------------------------------------------------

	The Hitbox Framework is intentionally minimal.

	If a feature feels useful but does not strictly
	belong in infrastructure, it likely belongs in
	a higher-level system.

	When in doubt, keep the core simple.

	----------------------------------------------------
	End of Document
	----------------------------------------------------

]]
