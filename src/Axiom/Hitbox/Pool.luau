--!strict
-- Axiom Core
-- Module: Pool
-- Version: 1.3.0

local RunService = game:GetService("RunService")

--// 1. PUBLIC TYPE
export type Pool<T> = {
	warm: (self: Pool<T>, count: number) -> (),
	acquire: (self: Pool<T>) -> T,
	release: (self: Pool<T>, obj: T) -> (),
	stats: (self: Pool<T>) -> {available: number, inUse: number},
}

--// 2. PRIVATE TYPE
type PrivatePool = {
	-- Properties
	_available: {any},
	_inUse: {[any]: boolean},
	_create: () -> any,
	_reset: ((any) -> ())?,
	_lastUseTime: number,
	_lastShrinkTime: number,

	-- Methods
	_startAdaptiveLoop: (self: PrivatePool) -> (),
	warm: (self: PrivatePool, count: number) -> (),
	acquire: (self: PrivatePool) -> any,
	release: (self: PrivatePool, obj: any) -> (),
	stats: (self: PrivatePool) -> {available: number, inUse: number},
}

--// Internal Constants
local BASE_POOL = 20
local IDLE_TIME = 30
local SHRINK_INTERVAL = 5
local SHRINK_RATE = 1

local Pool = {} 
Pool.__index = Pool

--// Constructor
function Pool.new<T>(createFn: () -> T, resetFn: (T) -> ()): Pool<T>
	local self = {
		_available = {},
		_inUse = {},

		_create = createFn,
		_reset = resetFn,

		_lastUseTime = os.clock(),
		_lastShrinkTime = 0,
	}

	setmetatable(self, Pool)
	
	local privateSelf = (self :: any) :: PrivatePool
	privateSelf:_startAdaptiveLoop()
	
	return (self :: any) :: Pool<T>
end

--// Methods
function Pool:warm(count: number)
	local self = self :: PrivatePool

	for _ = 1, count do
		table.insert(self._available, self._create())
	end
end

function Pool:acquire()
	local self = self :: PrivatePool

	self._lastUseTime = os.clock()

	local obj = table.remove(self._available)
	if not obj then
		obj = self._create()
	end

	self._inUse[obj] = true
	return obj
end

function Pool:release(obj: any)
	local self = self :: PrivatePool

	if not self._inUse[obj] then return end

	self._inUse[obj] = nil
	if self._reset then
		self._reset(obj)
	end

	table.insert(self._available, obj)
end

function Pool:_startAdaptiveLoop()
	local self = self :: PrivatePool

	RunService.Heartbeat:Connect(function()
		local now = os.clock()

		if next(self._inUse) then return end
		if now - self._lastUseTime < IDLE_TIME then return end
		if now - self._lastShrinkTime < SHRINK_INTERVAL then return end

		self._lastShrinkTime = now

		for _ = 1, SHRINK_RATE do
			if #self._available <= BASE_POOL then return end
			table.remove(self._available)
		end
	end)
end

function Pool:stats()
	local self = self :: PrivatePool

	local inUseCount = 0
	for _ in pairs(self._inUse) do 
		inUseCount += 1 
	end

	return {
		available = #self._available,
		inUse = inUseCount,
	}
end

return Pool