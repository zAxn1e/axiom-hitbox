--!strict
-- Axiom Core
-- Module: Scheduler (Timer)
-- Purpose: Centralized timer update loop
-- Version: 1.3.0

local Core = script.Parent
local Types = require(Core:WaitForChild("Types"))
local RunService = game:GetService("RunService")

--// Type Definitions
type Tickable = {
	_Tick: (self: Tickable, now: number) -> ()
}

type TimerScheduler = Types.TimerScheduler

type SchedulerImpl = {
	Step: number,
	Enabled: boolean,
	_active: {[Tickable]: boolean},
	_conn: RBXScriptConnection?,
	_accumulator: number,

	-- Methods definition required for 'self' context
	_EnsureRunning: (self: SchedulerImpl) -> (),
	_TryStop: (self: SchedulerImpl) -> (),
	Add: (self: SchedulerImpl, timer: any) -> (),
	Remove: (self: SchedulerImpl, timer: any) -> (),
	Clear: (self: SchedulerImpl) -> (),
}

local TimerScheduler = {}
TimerScheduler.__index = TimerScheduler

--// Config & Internal State
local self = TimerScheduler :: SchedulerImpl

self.Step = 1 / 30
self.Enabled = true
self._active = {}
self._conn = nil
self._accumulator = 0

--// Internal
function TimerScheduler:_EnsureRunning()
	local self = self :: SchedulerImpl 

	if self._conn then return end

	self._conn = RunService.Heartbeat:Connect(function(dt: number)
		if not self.Enabled then return end

		self._accumulator += dt
		if self._accumulator < self.Step then
			return
		end

		self._accumulator -= self.Step

		local now = os.clock()
		for timer in pairs(self._active) do
			timer:_Tick(now)
		end
	end)
end

function TimerScheduler:_TryStop()
	local self = self :: SchedulerImpl

	if next(self._active) ~= nil then return end

	if self._conn then
		self._conn:Disconnect()
		self._conn = nil :: any
	end
end

--// Public API
function TimerScheduler:Add(timer: any)
	local self = self :: SchedulerImpl
	self._active[timer :: Tickable] = true
	self:_EnsureRunning()
end

function TimerScheduler:Remove(timer: any)
	local self = self :: SchedulerImpl
	self._active[timer :: Tickable] = nil
	self:_TryStop()
end

function TimerScheduler:Clear()
	local self = self :: SchedulerImpl
	table.clear(self._active)
	self:_TryStop()
end

-- Return
return self