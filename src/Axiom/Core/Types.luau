-- Axiom Core
-- Module: Types
-- Purpose: Shared type definitions
-- Version: 1.3.0

local Core = script.Parent
local Signal = require(Core:WaitForChild("Signal"))

local Types = {}

--// ENUMS & HELPERS
export type HitboxState = "Idle" | "Active" | "Stopped" | "Cooldown"
export type HitboxPredictionMethod = "Linear" | "Angular" | "LinearAngular"

--// STATE MACHINE
export type State = "Idle" | "Active" | "Stopped" | "Cooldown"

export type StateMachine = {
	current: State,
	canTransition: (self: StateMachine, to: State) -> boolean,
	set: (self: StateMachine, to: State) -> boolean,
	is: (self: StateMachine, state: State) -> boolean,
}

--// HITBOX

export type Hitbox = {
	-- Properties
	Size: Vector3,
	CFrame: BasePart | CFrame,
	Offset: CFrame,
	Duration: number,
	Ignore: {Instance},
	OverlapParams: OverlapParams?,
	Visualizer: boolean,

	-- Prediction
	UsePrediction: boolean,
	PredictionTime: number,
	PredictionMethod: HitboxPredictionMethod,

	-- State
	StateMachine: StateMachine,
	GetState: (self: Hitbox) -> string,
	Is: (self: Hitbox, state: string) -> boolean,
	IsActive: (self: Hitbox) -> boolean,

	-- Signals
	OnStart: Signal.Signal<Hitbox>,
	OnStop: Signal.Signal<Hitbox>,
	OnUpdate: Signal.Signal<number, Hitbox>,
	OnHit: Signal.Signal<Model, Humanoid, BasePart>,

	-- Methods
	Start: (self: Hitbox) -> (),
	Stop: (self: Hitbox) -> (),
	Destroy: (self: Hitbox) -> (),
	SetCFrame: (self: Hitbox, cf: CFrame | BasePart) -> (),
	GetPoolStats: () -> {available: number, inUse: number},

	-- Internal / Private
	_humCache: {[Model]: Humanoid},
	_defaultOverlap: OverlapParams,
	_activeOverlap: OverlapParams?,
	_hit: {[Instance]: boolean},
	_conn: RBXScriptConnection?,
	_visualizerPart: Part?,
	_elapsed: number,
	_destroyed: boolean,

	-- Private Methods
	_cleanup: (self: Hitbox) -> (),
	_update: (self: Hitbox, baseCFrame: CFrame) -> (),
	_resolveBaseCFrame: (self: Hitbox) -> CFrame?,
	_ensureVisualizer: (self: Hitbox) -> (),
	_updateVisualizer: (self: Hitbox, baseCFrame: CFrame) -> (),
	_hideVisualizer: (self: Hitbox) -> (),
}

--// TIMER
export type Timer = {
	-- Properties
	Duration: number,
	Remaining: number,
	Running: boolean,

	-- Signals
	OnFinished: {FireSafe: (any) -> (), DisconnectAllFast: (any) -> (), new: () -> any},
	OnUpdated: {FireFast: (any, number) -> (), DisconnectAllFast: (any) -> (), new: () -> any},

	-- Methods
	Start: (self: Timer) -> (),
	Stop: (self: Timer) -> (),
	Pause: (self: Timer) -> (),
	Resume: (self: Timer) -> (),
	Reset: (self: Timer, duration: number?) -> (),
	Destroy: (self: Timer) -> (),

	SetEmitUpdates: (self: Timer, enabled: boolean) -> (),
	GetRemaining: (self: Timer) -> number,
	GetElapsed: (self: Timer) -> number,
	GetProgress: (self: Timer) -> number,

	IsRunning: (self: Timer) -> boolean,
	IsPaused: (self: Timer) -> boolean,
	IsFinished: (self: Timer) -> boolean,

	-- Internal
	_emitUpdate: boolean,
	_startTime: number,
	_paused: boolean,
	_pauseTime: number,
	_Tick: (self: Timer, now: number) -> (),
	
	_Finish: (self: Timer) -> (),
}

export type TimerScheduler = {
	Add: (self: TimerScheduler, timer: any) -> (),
	Remove: (self: TimerScheduler, timer: any) -> (),
}

return Types