--!strict
-- Axiom Core
-- Module: State
-- Purpose: Internal finite state mechanism
-- Version: 1.3.0

local Core = script.Parent.Parent:WaitForChild("Core")
local Types = require(Core:WaitForChild("Types"))

-- Helper Types
type State = Types.HitboxState
type StateMachine = Types.StateMachine

type TransitionTable = {
	[State]: {
		[State]: boolean
	}
}

local State = {}
State.__index = State

local TRANSITIONS: TransitionTable = {
	Idle = {
		Active = true,
	},
	Active = {
		Stopped = true,
		Cooldown = true,
	},
	Stopped = {
		Idle = true,
	},
	Cooldown = {
		Idle = true,
	},
}

function State.new(initial: State?): StateMachine
	local self = setmetatable({}, State)
	
	local object = self :: any
	object.current = initial or "Idle"
	
	return object :: StateMachine
end

function State:canTransition(to: State): boolean
	local self = self :: StateMachine
	
	local allowed = TRANSITIONS[self.current :: State]
	return allowed and allowed[to] == true
end

function State:set(to: State): boolean
	local self = self :: StateMachine
	
	if self:canTransition(to) then
		self.current = to
		return true
	end
	return false
end

function State:is(state: State): boolean
	local self = self :: StateMachine
	return self.current == state
end

return State