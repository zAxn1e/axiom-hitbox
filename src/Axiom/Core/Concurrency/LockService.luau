--!strict
local Core = script.Parent.Parent
local Await = require(Core:WaitForChild("Await"))

-- feature
local ENABLE_LEAK_DETECTOR = false
local ENABLE_CLEANUP_SCHEDULER = true

-- cleanup
local IDLE_TTL = 60               -- seconds a lock must be idle before cleanup
local CLEANUP_INTERVAL = 30       -- sweep interval
local SLOW_LOCK_THRESHOLD = 2

export type KeyedLock = {
	Acquire: (self: KeyedLock, timeout: number?, token: Await.CancelToken?) -> (),
	Release: (self: KeyedLock) -> (),
	Scoped: (self: KeyedLock, fn: () -> ...any, timeout: number?, token: Await.CancelToken?) -> ...any,
}

type KeyedLockInternal = KeyedLock & {
	_held: number,
	_acquires: number,
	_releases: number,
	_lastUsed: number,
}

local LockService = {}
LockService.__index = LockService

local locks: { [string]: KeyedLockInternal } = {}

local LockStats: {
	totalAcquired: number,
	totalReleased: number,
	slowLocks: number,
	leakedLocks: number,
	cleanedLocks: number,
} = {
	totalAcquired = 0,
	totalReleased = 0,
	slowLocks = 0,
	leakedLocks = 0,
	cleanedLocks = 0,
}

local function createLock(lockKey: string): KeyedLockInternal
	local mutex = Await.Mutex()

	local lock = {} :: KeyedLockInternal

	lock._held = 0
	lock._acquires = 0
	lock._releases = 0
	lock._lastUsed = os.clock()

	function lock:Acquire(timeout: number?, token: Await.CancelToken?)
        local selfInternal = self :: KeyedLockInternal
        local t0 = os.clock()

        selfInternal._acquires += 1
        LockStats.totalAcquired += 1
        selfInternal._lastUsed = os.clock()

        local ok, err = pcall(function()
            mutex:Lock(timeout, token)
        end)

        if not ok then
            -- ❗ acquire failed, do NOT mark held
            warn("[LockService] failed acquire key=", lockKey, " err=", err)
            error(err, 2)
        end

        -- ✔️ only now we really own the lock
        selfInternal._held += 1

        local dt = os.clock() - t0
        if dt >= SLOW_LOCK_THRESHOLD then
            LockStats.slowLocks += 1
            warn("[LockService] slow acquire key=", lockKey, " waited=", dt)
        end
    end

	function lock:Release()
        local selfInternal = self :: KeyedLockInternal

        if selfInternal._held <= 0 then
            warn("[LockService] Release() without held key=", lockKey)
            return
        end

        selfInternal._held -= 1
        selfInternal._releases += 1
        selfInternal._lastUsed = os.clock()

        LockStats.totalReleased += 1

        local ok, err = pcall(function()
            mutex:Unlock()
        end)

        if not ok then
            warn("[LockService] unlock failed key=", lockKey, " err=", err)
        end
    end

	function lock:Scoped(fn, timeout: number?, token: Await.CancelToken?)
		self:Acquire(timeout, token)

		local ok, result = pcall(function() return table.pack(fn()) end)

		self:Release()

		if not ok then
			error(result, 2)
		end

		return table.unpack(result, 1, result.n)
	end

	-- LEAK DETECTOR
	if ENABLE_LEAK_DETECTOR then
		task.spawn(function()
			local lastWarn = 0

			while true do
				task.wait(5)

				if lock._held > 0 and os.clock() - lastWarn > 30 then
					lastWarn = os.clock()
					LockStats.leakedLocks += 1
					warn("[LockService] possible leaked lock key=", lockKey, " held=", lock._held)
				end
			end
		end)
	end

	return lock
end

function LockService:GetLock(key: string): KeyedLock
	local existing = locks[key]
	if existing then
		return existing
	end

	local new = createLock(key)
	locks[key] = new
	return new
end

-- CLEANUP SCHEDULER
if ENABLE_CLEANUP_SCHEDULER then
	task.spawn(function()
		while true do
			task.wait(CLEANUP_INTERVAL)

			local now = os.clock()

			for key, lk in pairs(locks) do
				local internal = lk :: KeyedLockInternal

				if internal._held == 0 then
					if now - internal._lastUsed >= IDLE_TTL then
						locks[key] = nil
						LockStats.cleanedLocks += 1
					 end
				end
			end
		end
	end)
end

function LockService:Stats()
	return LockStats
end

return LockService