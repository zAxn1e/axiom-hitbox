--!strict
local Core = script.Parent
local Await = require(Core:WaitForChild("Await"))

local Concurrency = {}

export type LockHandle = {
    Acquire: (self: LockHandle, timeout: number?, token: Await.CancelToken?) -> (),
    Release: (self: LockHandle) -> (),
    Scoped: (self: LockHandle, fn: () -> ...any, timeout: number?, token: Await.CancelToken?) -> ...any,
}

Concurrency.LockService = require(script:WaitForChild("LockService"))
Concurrency.Atomic = require(script:WaitForChild("Atomic"))
Concurrency.Transaction = require(script:WaitForChild("Transaction"))
Concurrency.Actor = require(script:WaitForChild("Actor"))
Concurrency.Trade = require(script:WaitForChild("Trade"))

function Concurrency.Lock(key: string): LockHandle
    return Concurrency.LockService:GetLock(key)
end

Concurrency.Await = Await

return Concurrency