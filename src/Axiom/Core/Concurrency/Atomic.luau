--!strict
local LockService = require(script.Parent.LockService)

export type AtomicValue<T> = {
    Get: (self: AtomicValue<T>) -> T,
    Update: (self: AtomicValue<T>, fn: (T) -> T) -> T,
}

local Atomic = {}
Atomic.__index = Atomic

function Atomic.new<T>(key: string, initial: T): AtomicValue<T>
    local self: any = setmetatable({}, Atomic)

    self._key = key
    self._value = initial

    return self :: AtomicValue<T>
end

function Atomic:Get<T>(): T
    return (self :: any)._value
end

function Atomic:Update<T>(fn: (T) -> T): T
    local key: string = (self :: any)._key
    local lock = LockService:GetLock("atomic:" .. key)

    return lock:Scoped(function()
        local s: any = self
        local v = s._value
        local newV = fn(v)
        s._value = newV
        return newV
    end)
end

return Atomic