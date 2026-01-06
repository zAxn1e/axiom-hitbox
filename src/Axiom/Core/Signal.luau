--!strict
-- Axiom Core
-- Module: Signal
-- Purpose: Lightweight internal event system
-- Version: 1.3.0

local Signal = {}
Signal.__index = Signal

export type Connection = {
	Disconnect: (self: Connection) -> ()
}

export type Signal<T...> = {
	Connect: (self: Signal<T...>, fn: (T...) -> ()) -> Connection,
	Once: (self: Signal<T...>, fn: (T...) -> ()) -> Connection,
	FireFast: (self: Signal<T...>, T...) -> (),
	FireSafe: (self: Signal<T...>, T...) -> (),
	HasConnections: (self: Signal<T...>) -> boolean,
	DisconnectAllFast: (self: Signal<T...>) -> (),
	Freeze: (self: Signal<T...>) -> (),
	Unfreeze: (self: Signal<T...>) -> (),
	Destroy: (self: Signal<T...>) -> (),
}

type AnyHandler = (...any) -> ()

type SignalInternal = {
	_handlers: {[AnyHandler]: true},
	_pendingRemove: {[AnyHandler]: true},
	_firingDepth: number,
	_frozen: boolean,
	_destroyed: boolean,
}

local safePcall: any = pcall
local DeadConnection = { Disconnect = function() end }

function Signal.new<T...>(): Signal<T...>
	return setmetatable({
		_handlers = {} :: {[AnyHandler]: true},
		_pendingRemove = {} :: {[AnyHandler]: true},
		_firingDepth = 0,
		_frozen = false,
		_destroyed = false,
	}, Signal) :: any
end

function Signal:Connect(fn)
	local internal = (self :: any) :: SignalInternal
	if internal._destroyed then
		warn("[Signal] Attempt to connect to a destroyed signal")
		return DeadConnection
	end
	
	internal._handlers[fn] = true
	
	local disconnected = false
	return {
		Disconnect = function()
			if disconnected then return end
			disconnected = true
			
			if internal._destroyed then return end
			
			if internal._firingDepth > 0 then
				internal._pendingRemove[fn] = true
			else
				internal._handlers[fn] = nil
			end
		end
	}
end

function Signal:Once(fn)
	local disconnected = false
	local conn: Connection

	conn = self:Connect(function(...: any)
		if disconnected then return end
		disconnected = true
		conn:Disconnect()
		fn(...)
	end)

	return conn
end

function Signal:FireFast(...: any)
	local internal = (self :: any) :: SignalInternal
	if internal._frozen or internal._destroyed then return end

	for fn in pairs(internal._handlers) do
		fn(...)
	end
end

function Signal:FireSafe(...: any)
	local internal = (self :: any) :: SignalInternal
	if internal._frozen or internal._destroyed then return end

	internal._firingDepth += 1

	for fn in pairs(internal._handlers) do
		local ok, err = safePcall(fn, ...)
		if not ok then
			warn(`[Signal] Handler error: {err}`)
		end
	end

	internal._firingDepth -= 1

	if internal._firingDepth == 0 then
		for fn in pairs(internal._pendingRemove) do
			internal._handlers[fn] = nil
		end
		internal._pendingRemove = {}
	end
end

function Signal:HasConnections(): boolean
	local internal = (self :: any) :: SignalInternal
	return next(internal._handlers) ~= nil
end

function Signal:DisconnectAllFast()
	local internal = (self :: any) :: SignalInternal
	internal._handlers = {} :: {[AnyHandler]: true}
	internal._pendingRemove = {} :: {[AnyHandler]: true}
end

function Signal:Freeze()
	local internal = (self :: any) :: SignalInternal
	internal._frozen = true
end

function Signal:Unfreeze()
	local internal = (self :: any) :: SignalInternal
	internal._frozen = false
end

function Signal:Destroy()
	local internal = (self :: any) :: SignalInternal
	if internal._destroyed then return end

	internal._destroyed = true
	internal._frozen = true

	self:DisconnectAllFast()
	
	setmetatable(self :: any, nil)
end

return Signal