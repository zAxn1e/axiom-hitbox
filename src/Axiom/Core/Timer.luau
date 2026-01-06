--!strict
-- Axiom Core
-- Module: Timer
-- Purpose: Internal timing primitive
-- Version: 1.3.0

--// Services
local RunService = game:GetService("RunService")

local Core = script.Parent
local Signal = require(Core:WaitForChild("Signal"))
local Types = require(Core:WaitForChild("Types"))
local Scheduler = require(Core:WaitForChild("Scheduler")) :: Types.TimerScheduler

--// Re-export Type
export type Timer = Types.Timer

local Timer = {}
Timer.__index = Timer

--// Constructor
function Timer.new(duration: number): Timer
	assert(type(duration) == "number", "Duration must be a number")
	assert(duration > 0, "Duration must be positive")

	local self = setmetatable({}, Timer)
	
	local object = self :: any

	object.Duration = duration
	object.Remaining = duration
	object.Running = false

	object.OnFinished = Signal.new()
	object.OnUpdated = Signal.new()

	object._emitUpdate = false
	object._startTime = 0
	object._paused = false
	object._pauseTime = 0

	return object :: Timer
end

function Timer:Start()
	local self = self :: Timer
	if self.Running then return end

	self.Running = true
	self._paused = false
	self._startTime = os.clock()

	Scheduler:Add(self)
end

function Timer:Stop()
	local self = self :: Timer
	if not self.Running then return end
	self.Running = false

	Scheduler:Remove(self)
end

function Timer:Pause()
	local self = self :: Timer

	if not self.Running or self._paused then return end
	self._paused = true
	self._pauseTime = os.clock()
end

function Timer:Resume()
	local self = self :: Timer

	if not self._paused then return end

	if self.Remaining <= 0 then
		self:_Finish()
		return
	end

	local delta = os.clock() - self._pauseTime
	self._startTime += delta
	self._paused = false
end

function Timer:Reset(duration: number?)
	local self = self :: Timer

	self:Stop()

	if duration ~= nil then
		assert(type(duration) == "number" and duration > 0, "Duration must be positive")
		self.Duration = duration
	end

	self.Remaining = self.Duration

	self._paused = false
	self._pauseTime = 0
	self._startTime = 0
end

function Timer:Destroy()
	local self = self :: Timer
	self:Stop()

	self.OnFinished:DisconnectAllFast()
	self.OnUpdated:DisconnectAllFast()

	table.clear(self :: any)
	setmetatable(self :: any, nil)
end

--// Utilities
function Timer:SetEmitUpdates(enabled: boolean)
	local self = self :: Timer
	self._emitUpdate = enabled
end

function Timer:GetRemaining(): number
	local self = self :: Timer
	return self.Remaining
end

function Timer:GetElapsed(): number
	local self = self :: Timer
	return self.Duration - self.Remaining
end

function Timer:IsRunning(): boolean
	local self = self :: Timer
	return self.Running
end

function Timer:IsPaused(): boolean
	local self = self :: Timer
	return self._paused
end

function Timer:IsFinished(): boolean
	local self = self :: Timer
	return self.Remaining <= 0
end

function Timer:GetProgress(): number
	local self = self :: Timer
	return 1 - (self.Remaining / self.Duration)
end

--// Internals
function Timer:_Tick(now: number)
	local self = self :: Timer

	if not self.Running or self._paused then
		return
	end

	self.Remaining = math.max(
		self.Duration - (now - self._startTime),
		0
	)

	if self._emitUpdate then
		self.OnUpdated:FireFast(self.Remaining)
	end

	if self.Remaining <= 0 then
		self:_Finish()
	end
end

function Timer:_Finish()
	local self = self :: Timer

	if not self.Running then return end
	self:Stop()
	self.Remaining = 0
	self.OnFinished:FireSafe()
end

return Timer