--!strict
-- Axiom Core
-- Module: Await
-- Purpose: Lightweight coroutine-based synchronization primitives for Roblox
-- Version: 1.3.0

--[[
	Axiom Await Core Library
	
	High-level Intent
	- Provide a practical alternative to Promise chains
	- Embrace Roblox-native coroutine scheduling semantics
	- Safe cancellation, timeouts, and concurrency coordination
	- Suitable for large-scale production game codebases
	
	Design Goals
	- Coroutine-first (not Promise-based)
	- Deterministic wake-ups (no hidden threads, no busy loops)
	- Real cancellation propagation through token trees
	- Minimal allocations / low scheduler overhead
	- Type-aware within Luau’s current limits
	- Ergonomic but explicit (no magic behavior)
	
	------------------------------------------------------------
	CANCELLATION MODEL
	------------------------------------------------------------
	- Cooperative cancellation using CancelToken
	- Parent token cancels children recursively
	- Cancellation is observed via ThrowIfCancelled()
	- Instance-linked tokens auto-cancel on Destroy
	
	Supports:
		* ThrowIfCancelled()
		* OnCancelled(callback)
		* Child() token hierarchy
		* LinkToInstance(instance)
	
	------------------------------------------------------------
	CORE PRIMITIVES
	------------------------------------------------------------
	Await.Signal(signal, timeout?, token?)
	Await.Any(tasks, timeout?, token?)
	Await.All(tasks, timeout?, opts?, token?)
	Await.Sleep(seconds, token?)
	Await.Condition(predicate, timeout?, interval?)
	
	------------------------------------------------------------
	SIGNAL & FLOW EXTENSIONS
	------------------------------------------------------------
	Await.AnySignals(signals, timeout?, token?)
	Await.AllSignals(signals, timeout?, token?)
	Await.NextTick()
	
	------------------------------------------------------------
	FUNCTIONAL UTILITIES
	------------------------------------------------------------
	Await.Try(fn)
	Await.Retry(fn, maxAttempts, opts?)
	Await.Debounce(fn, delay, opts?)
	Await.Throttle(fn, window, opts?)
	Await.Queue()
	Await.Race			-- alias of Await.Any
	
	------------------------------------------------------------
	CONCURRENCY PRIMITIVES
	------------------------------------------------------------
	Await.Mutex()
		* Lock / Unlock
		* Scoped(fn) helper
		* FIFO fairness best-effort
	
	Await.Semaphore(maxCount)
		* Acquire / Release
		* Capacity-limited concurrency
		* Overflow safe-guard warnings
	
	------------------------------------------------------------
	NOTES
	------------------------------------------------------------
	- Promise-agnostic (can be used alongside Promise libs or without them)
	- Fully coroutine-driven (task.spawn / coroutine.yield / delay)
	- Cancellation is cooperative - threads are never force-killed
	- Timeout callbacks are NOT cancelled once scheduled
	    * they are guarded by a 'finished' flag
	    * avoids race conditions and scheduler undefined behaviour
	- Designed to fail loudly on misuse (unlock without lock, overflow release)
]]

local Await = {}

-- ====================================
-- // TYPES DEFINITION
-- ====================================

-- AwaitableSignal
-- A minimal interface expected by Await.Signal.
-- This is intentionally loose to support both Roblox signals
-- and custom signal implementations.
export type AwaitableSignal<T...> = {
	Once: (self: any, fn: (T...) -> ()) -> any,
}

-- CancelToken
type CancelTokenInternal = {
	cancelled: boolean,
	reason: any?,
	_callbacks: { () -> () },
	_children: { CancelTokenInternal },
	
	Cancel: (self: CancelTokenInternal, reason: any?) -> (),
	OnCancelled: (self: CancelTokenInternal, fn: () -> ()) -> (),
	ThrowIfCancelled: (self: CancelTokenInternal) -> (),
	Child: (self: CancelTokenInternal) -> CancelTokenInternal,
	LinkToInstance: (self: CancelTokenInternal, inst: Instance) -> (),
}
export type CancelToken = CancelTokenInternal

-- TryResult
-- Result-based error boundary used by Await.Try.
-- This avoids tuple-based error signaling which is not type-safe in Luau.
export type TryResult = { success: true, values: {any} } | { success: false, error: any }

-- AnyTask
-- A task that may return values.
-- Await.Any packs these values internally.
type AnyTask = () -> ...any

-- VoidTask
-- A side-effect-only task.
-- Return values are intentionally ignored.
type VoidTask = () -> ()

-- Debounce & Throttle
export type DebouncedFn = ((...any) -> ()) & { cancel: () -> (), flush: () -> () }
export type ThrottledFn = ((...any) -> ()) & { cancel: () -> (), flush: () -> () }

-- Mutex & Semaphore
export type Mutex = {
	Lock: (self: Mutex, timeout: number?, token: CancelToken?) -> (),
	Unlock: (self: Mutex) -> (),
	Scoped: (self: Mutex, fn: () -> ...any, timeout: number?, token: CancelToken?) -> ...any,
}

export type Semaphore = {
	Acquire: (self: Semaphore, timeout: number?, token: CancelToken?) -> (),
	Release: (self: Semaphore) -> (),
	Available: (self: Semaphore) -> number,
}

-- ====================================
--// PRIVATE UTILITIES
-- ====================================
local function now(): number
	return os.clock()
end

local function timeoutError(name: string, timeout: number?)
	error(string.format(
		"%s timed out%s",
		name,
		timeout and (" after " .. tostring(timeout) .. "s") or ""
		), 2)
end

-- Safe resume ensures the thread is suspended before resuming
-- avoiding "Cannot resume running coroutine" errors.
local function safeResume(thread: thread)
	if coroutine.status(thread) == "suspended" then
		task.spawn(thread)
	end
end

-- Unified cleanup handler for connections, functions, or instances
local function disconnectConnection(conn: any)
	if not conn then return end
	
	if typeof(conn) == "RBXScriptConnection" then
		(conn :: RBXScriptConnection):Disconnect()
	elseif type(conn) == "function" then
		(conn :: any)()
	elseif type(conn) == "table" and type((conn :: any).Disconnect) == "function" then
		(conn :: any):Disconnect()
	elseif typeof(conn) == "Instance" then
		conn:Destroy()
	end
end

-- ====================================
-- // CORE PRIMITIVES
-- ====================================

--// Await.Token
function Await.Token(): CancelToken
	local token = {} :: CancelTokenInternal
	token.cancelled = false
	token.reason = nil
	token._callbacks = {}
	token._children = {}
	
	-- Cancel
	function token:Cancel(reason: any?)
		if self.cancelled then
			return
		end

		self.cancelled = true
		self.reason = reason

		for _, child in ipairs(self._children) do
			child:Cancel(reason)
		end

		for _, fn in ipairs(self._callbacks) do
			task.spawn(fn)
		end

		table.clear(self._callbacks)
		table.clear(self._children)
	end
	
	-- OnCancelled
	function token:OnCancelled(fn: () -> ())
		if self.cancelled then
			task.spawn(fn)
		else
			table.insert(self._callbacks, fn)
		end
	end
	
	-- ThrowIfCancelled
	function token:ThrowIfCancelled()
		if self.cancelled then
			error(self.reason or "Operation cancelled", 2)
		end
	end
	
	-- Child
	function token:Child(): CancelTokenInternal
		local child = Await.Token() :: CancelTokenInternal

		if self.cancelled then
			child:Cancel(self.reason)
		else
			table.insert(self._children, child)
		end

		return child
	end
	
	-- LinkToInstance
	function token:LinkToInstance(inst: Instance)
		if not inst.Parent then
			self:Cancel("Instance destroyed")
			return
		end

		local conn: RBXScriptConnection
		conn = inst.AncestryChanged:Connect(function(_, parent)
			if parent == nil then
				conn:Disconnect()
				self:Cancel("Instance destroyed")
			end
		end)
	end
	
	return token
end

--// Await.Signal
-- Suspends the current coroutine until the signal fires.
-- Optionally times out after `timeout` seconds.
-- NOTE:
-- Timeout callbacks are NOT canceled if the signal fires early.
-- This is intentional:
--   - Roblox does not provide deterministic cancellation
--   - Canceling scheduled callbacks adds complexity without correctness gains
--   - Extra callbacks are short-lived and guarded by `finished`
-- This function returns the signal payload as variadic values.
-- Due to Luau limitations, results are internally packed into a table.
function Await.Signal<T...>(
	signal: AwaitableSignal<T...>,
	timeout: number?,
	token: CancelToken?
): T...
	if token then
		token:ThrowIfCancelled()
	end

	local thread = coroutine.running()
	local finished = false
	local result: {any}? = nil
	local conn

	local function cleanup()
		disconnectConnection(conn)
		conn = nil
	end

	conn = signal:Once(function(...)
		if finished then return end
		finished = true
		result = {...}
		cleanup()
		safeResume(thread)
	end)

	if token then
		token:OnCancelled(function()
			if finished then return end
			finished = true
			cleanup()
			safeResume(thread)
		end)
	end

	if timeout then
		task.delay(timeout, function()
			if finished then return end
			finished = true
			cleanup()
			safeResume(thread)
		end)
	end

	if not finished then
		coroutine.yield()
	end

	if token then
		token:ThrowIfCancelled()
	end

	if not result then
		timeoutError("Await.Signal", timeout)
	end

	-- Luau limitation (as far as we know)
	-- Generic variadic types (T...) cannot be reified or cast.
	-- This is as far as the type system goes.
	--
	-- If you know a better way that preserves the core design,
	-- feel free to open an issue or reply on DevForum.
	-- We genuinely tried. Luau said "hell nah".
	return table.unpack(result :: {any})
end

--// Await.Any
-- Runs multiple tasks in parallel and resumes when the first task
-- completes successfully.
-- Semantics:
--   - First successful task wins
--   - Failed tasks are ignored
--   - Returned values come from the winning task
-- Must be called from a yielding coroutine
function Await.Any(
	tasks: { AnyTask },
	timeout: number?,
	token: CancelToken?
): ...any
	if not coroutine.isyieldable() then
		error(
			"Await.Any must be called from a yielding coroutine (e.g. task.spawn)",
			2
		)
	end
	
	if #tasks == 0 then
		error("Await.Any requires at least one task", 2)
	end
	
	if token then
		token:ThrowIfCancelled()
	end
	
	local thread: thread = coroutine.running()
	local finished = false
	local result: { any }? = nil
	
	for _, taskFn in ipairs(tasks) do
		task.spawn(function()
			if finished then
				return
			end
			
			local ok, packed = pcall(function()
				return { taskFn() }
			end)
			
			if not ok then
				warn("[Await.Any] task error:", packed)
			end
			
			if finished then
				return
			end
			
			if ok then
				finished = true
				result = packed
				
				safeResume(thread)
			end
		end)
	end

	if timeout then
		task.delay(timeout, function()
			if finished then
				return
			end
			
			finished = true
			
			safeResume(thread)
		end)
	end
	
	if token then
		token:OnCancelled(function()
			if finished then return end
			finished = true
			safeResume(thread)
		end)
	end
	
	if not finished then
		coroutine.yield()
	end
	
	if token then
		token:ThrowIfCancelled()
	end
	
	if not result then
		timeoutError("Await.Any", timeout)
	end
	
	return table.unpack(result :: { any })
end

--// Await.All
-- Synchronization barrier for side-effect tasks.
-- Does NOT aggregate return values.
-- Error behavior:
--   - Default: warn on task errors
--   - opts.throw = true: throw after all tasks complete
-- Errors are collected and thrown from the calling coroutine,
-- not from worker threads.
function Await.All(
	tasks: { VoidTask },
	timeout: number?,
	opts: {
		throw: boolean?
	}?,
	token: CancelToken?
)
	if token and token.cancelled then
		timeoutError("Await.All (cancelled)", timeout)
	end
	
	local remaining: number = #tasks
	if remaining == 0 then
		return
	end
	
	local thread: thread = coroutine.running()
	local finished = false
	
	local start = now()
	local firstError: any = nil
	
	for _, taskFn in ipairs(tasks) do
		task.spawn(function()
			local ok, err = pcall(function()
				taskFn()
				return nil
			end)
			
			if not ok then
				if opts and opts.throw then
					if firstError == nil then
						firstError = err
					end
				else
					warn("[Await.All] task error:", err)
				end
			end
			
			remaining -= 1
			
			if remaining == 0 and not finished then
				finished = true
				safeResume(thread)
			end
		end)
	end
	
	if timeout then
		task.delay(timeout, function()
			if finished then return end
			finished = true
			
			safeResume(thread)
		end)
	end
	
	-- before waiting
	if token then
		token:ThrowIfCancelled()
	end
	
	-- register cancel wakeup
	if token then
		token:OnCancelled(function()
			if finished then return end
			finished = true
			safeResume(thread)
		end)
	end
	
	-- wait
	if not finished then
		coroutine.yield()
	end
	
	-- after wake
	if token then
		token:ThrowIfCancelled()
	end
	
	-- timeout branch
	if timeout and (now() - start) >= (timeout :: number) and remaining > 0 then
		timeoutError("Await.All", timeout)
	end
	
	if firstError ~= nil then
		error(firstError, 2)
	end
end

-- ====================================
-- // SIGNAL & FLOW EXTENSIONS
-- ====================================

--// Await.AnySignals
function Await.AnySignals<T...>(
	signals: { AwaitableSignal<T...> },
	timeout: number?,
	token: CancelToken?
): T...
	local tasks: { AnyTask } = {}
	
	for _, sig in ipairs(signals) do
		table.insert(tasks, function()
			-- NOTE: Don't pass timeout to inner signals.
			-- Await.Any handles the overall timeout.
			-- Passing timeout here causes double-timeout errors and noisy warnings.
			return Await.Signal(sig, nil, token)
		end)
	end
	
	return Await.Any(tasks, timeout, token)
end

--// Await.AllSignals
function Await.AllSignals(
	signals: { AwaitableSignal<any> },
	timeout: number?,
	token: CancelToken?
)
	local tasks: { VoidTask } = {}
	
	for _, sig in ipairs(signals) do
		table.insert(tasks, function()
			Await.Signal(sig, timeout, token)
		end)
	end
	
	Await.All(tasks, timeout, nil, token)
end

--// Await.Condition
-- Polls a predicate until it returns true.
-- This is a helper utility and intentionally polling-based.
-- interval:
--   - nil or 0: check every frame
--   - > 0     : check every `interval` seconds
function Await.Condition(
	predicate: () -> boolean,
	timeout: number?,
	interval: number?,
	token: CancelToken?
)
	if token then token:ThrowIfCancelled() end
	
	local start = now()
	local step = interval or 0 -- 0 = next frame
	
	while not predicate() do
		if token then token:ThrowIfCancelled() end
		if timeout and (now() - start) >= timeout then
			timeoutError("Await.Condition", timeout)
		end
		task.wait(step)
	end
end

--// Await.Sleep
-- Scheduler-based sleep
-- supports cancellation immediately
-- does NOT drift with frame delta
function Await.Sleep(sec: number, token: CancelToken?)
	if token then token:ThrowIfCancelled() end
	
	local thread = coroutine.running()
	local finished = false
	
	task.delay(sec, function()
		if finished then return end
		finished = true
		safeResume(thread)
	end)
	
	if token then
		token:OnCancelled(function()
			if finished then return end
			finished = true
			safeResume(thread)
		end)
	end
	
	if not finished then
		coroutine.yield()
	end
	
	if token then token:ThrowIfCancelled() end
end

-- ====================================
-- // FUNCTIONAL UTILITIES
-- ====================================

--// Await.Retry
function Await.Retry(
	fn: () -> ...any,
	maxAttempts: number,
	opts: {
		delay: number?,
		backoff: number?,
		token: CancelToken?
	}?
): ...any
	
	-- normalize opts
	if opts == nil then
		opts = {}
	end
	
	local normalized = (opts or {}) :: {
		delay: number?,
		backoff: number?,
		token: CancelToken?
	}
	
	local delay: number = normalized.delay or 0
	local backoff: number = normalized.backoff or 1.0
	local token: CancelToken? = normalized.token
	
	for attempt = 1, maxAttempts do
		if token then
			token:ThrowIfCancelled()
		end
		
		local ok, packed = pcall(function()
			return table.pack(fn())
		end)
		
		if ok then
			return table.unpack(packed, 1, packed.n)
		end
		
		-- last attempt -> throw
		if attempt == maxAttempts then
			error(packed, 2)
		end
		
		if delay > 0 then
			Await.Sleep(delay, token)
		end
		delay *= backoff
	end
	
	error("unreachable", 2)
end

--// Await.Try
-- Executes a function inside a protected call and returns a Result object.
-- This avoids tuple-based error handling which is not type-safe in Luau.
function Await.Try(fn: () -> ...any): TryResult
	local packed: {any} = { pcall(fn) }
	local ok = table.remove(packed, 1)
	
	if ok then
		return {
			success = true,
			values = packed
		}
	else
		return {
			success = false,
			error = packed[1]
		}
	end
end

--// Await.NextTick
function Await.NextTick()
	task.wait()
end

--// Await.Debounce
-- Logic: Delay execution until 'delay' seconds have passed since the last call.
function Await.Debounce(
	fn: (...any) -> (),
	delay: number,
	opts: { leading: boolean?, trailing: boolean?, maxWait: number?, token: CancelToken? }?
): DebouncedFn
	local safe = (opts or {}) :: { leading: boolean?, trailing: boolean?, maxWait: number?, token: CancelToken? }
	local leading = safe.leading == true
	local trailing = (safe.trailing ~= false)
	local maxWait = safe.maxWait
	local token = safe.token

	local timer: thread? = nil
	local maxWaitTimer: thread? = nil
	local lastArgs: {any}? = nil
	local trailingPending = false

	local function cancelTimers()
		if timer then
			task.cancel(timer)
			timer = nil
		end
		
		if maxWaitTimer then
			task.cancel(maxWaitTimer)
			maxWaitTimer = nil
		end
	end

	local function invoke(args: {any})
		cancelTimers()
		trailingPending = false
		lastArgs = nil
		if token then token:ThrowIfCancelled() end
		fn(table.unpack(args))
	end

	local function cancel()
		cancelTimers()
		lastArgs = nil
		trailingPending = false
	end

	local function flush()
		if trailingPending and lastArgs then invoke(lastArgs) else cancel() end
	end

	if token then token:OnCancelled(cancel) end

	local function run(...: any)
		lastArgs = {...}
		local isNewSequence = (timer == nil) and (maxWaitTimer == nil)

		if timer then task.cancel(timer) end

		if isNewSequence then
			if leading then
				if token then token:ThrowIfCancelled() end
				fn(table.unpack(lastArgs :: {any}))
				trailingPending = false
			else
				trailingPending = true
			end

			if maxWait and not maxWaitTimer then
				maxWaitTimer = task.delay(maxWait, function()
					maxWaitTimer = nil
					if trailingPending and lastArgs then invoke(lastArgs :: {any}) else cancel() end
				end)
			end
		else
			trailingPending = true
		end

		timer = task.delay(delay, function()
			timer = nil
			if trailing and trailingPending and lastArgs then
				invoke(lastArgs :: {any})
			else
				cancel()
			end
		end)
	end

	local wrapper: any = setmetatable({ cancel = cancel, flush = flush }, {
		__call = function(_, ...) run(...) end
	})
	return wrapper :: DebouncedFn
end

--// Await.Throttle
-- Logic: Ensure execution at most once per 'window'. Do NOT cancel timers.
function Await.Throttle(
	fn: (...any) -> (),
	window: number,
	opts: { leading: boolean?, trailing: boolean?, token: CancelToken? }?
): ThrottledFn
	local safe = (opts or {}) :: { leading: boolean?, trailing: boolean?, token: CancelToken? }
	local leading = (safe.leading ~= false)
	local trailing = (safe.trailing ~= false)
	local token = safe.token

	local lastExecTime = 0
	local lastArgs: {any}? = nil
	local timer: thread? = nil

	local function invoke(args: {any})
		lastExecTime = os.clock()
		timer = nil
		if token then token:ThrowIfCancelled() end
		fn(table.unpack(args))
	end

	local function cancel()
		if timer then
			task.cancel(timer)
			timer = nil
		end
		lastArgs = nil
		lastExecTime = 0 -- [FIXED] Reset cooldown on cancel
	end

	local function flush()
		if lastArgs then
			local args = lastArgs
			cancel()
			-- After cancel (reset), we invoke immediately
			invoke(args)
		else
			cancel()
		end
	end

	if token then token:OnCancelled(cancel) end

	local function onTimer()
		if trailing and lastArgs then
			invoke(lastArgs)
			lastArgs = nil
		else
			timer = nil
		end
	end

	local function call(...: any)
		local now = os.clock()
		lastArgs = {...}

		local timeSinceLast = now - lastExecTime
		local isOutsideWindow = timeSinceLast >= window

		if isOutsideWindow and not timer then
			if leading then
				invoke(lastArgs :: {any})
				lastArgs = nil
				return
			else
				lastExecTime = now
			end
		end

		if not timer then
			local remaining = window - (now - lastExecTime)
			if remaining < 0 then remaining = 0 end
			timer = task.delay(remaining, onTimer)
		end
	end

	local wrapper: any = setmetatable({ cancel = cancel, flush = flush }, {
		__call = function(_, ...) call(...) end
	})
	return wrapper :: ThrottledFn
end

--// Await.Queue
-- Serialize async jobs FIFO
function Await.Queue()
	local running = false
	local queue: { () -> () } = {}
	local scheduled = false
	
	local function process()
		if running or scheduled then return end
		scheduled = true
		
		task.defer(function()
			scheduled = false
			if running then return end
			running = true
			
			while #queue > 0 do
				local job = table.remove(queue, 1) :: () -> ()
				local ok: boolean, err: any = pcall(function()
					job()
					return nil
				end)
				if not ok then
					warn("[Await.Queue] job error:", err)
				end
			end
			
			running = false
		end)
	end
	
	return function(job: () -> ())
		table.insert(queue, job)
		process()
	end
end

-- ====================================
-- // CONCURRENCY PRIMITIVES
-- ====================================

function Await.Mutex(): Mutex
	local queue: { thread } = {}
	local locked = false
	local mutex = {} :: any
	
	function mutex:Lock(timeout: number?, token: CancelToken?)
		if token then token:ThrowIfCancelled() end
		if not locked then
			locked = true
			return
		end
		
		local thread = coroutine.running()
		table.insert(queue, thread)
		local finished = false
		
		if timeout then
			task.delay(timeout, function()
				if finished then return end
				finished = true
				for i, t in ipairs(queue) do
					if t == thread then 
						table.remove(queue, i) 
						break 
					end
				end
				safeResume(thread)
			end)
		end
		
		if token then
			token:OnCancelled(function()
				if finished then return end
				finished = true
				for i, t in ipairs(queue) do
					if t == thread then 
						table.remove(queue, i) 
						break 
					end
				end
				safeResume(thread)
			end)
		end
		
		coroutine.yield()
		local wasTimedOutOrCancelled = finished
		finished = true -- prevent stale timeout/cancel callbacks from spuriously resuming
		if token then token:ThrowIfCancelled() end
		
		if timeout and wasTimedOutOrCancelled then timeoutError("Mutex.Lock", timeout) end
	end
	
	-- NOTE: timing out a waiter does NOT unlock the mutex.
	-- Only the holder may call Unlock().
	function mutex:Unlock()
		if not locked then error("Mutex.Unlock called when not locked", 2) end
		local nextThread = table.remove(queue, 1)
		if nextThread then safeResume(nextThread) else locked = false end
	end
	
	function mutex:Scoped(fn, timeout: number?, token: CancelToken?)
		self:Lock(timeout, token)
		local ok, result = pcall(function() return table.pack(fn()) end)
		self:Unlock()
		if not ok then error(result, 2) end
		return table.unpack(result, 1, result.n)
	end
	
	return mutex :: Mutex
end

function Await.Semaphore(maxCount: number): Semaphore
	assert(maxCount >= 1, "Semaphore max must be >= 1")
	local count = maxCount
	local queue: { thread } = {}
	local sem = {} :: any
	
	function sem:Available() return count end
	
	function sem:Acquire(timeout: number?, token: CancelToken?)
		if token then token:ThrowIfCancelled() end
		if count > 0 then
			count -= 1
			return
		end
		
		local thread = coroutine.running()
		table.insert(queue, thread)
		local finished = false
		
		if timeout then
			task.delay(timeout, function()
				if finished then return end
				finished = true
				for i, t in ipairs(queue) do
					if t == thread then
						table.remove(queue, i)
						break
					end
				end
				safeResume(thread)
			end)
		end
		
		if token then
			token:OnCancelled(function()
				if finished then return end
				finished = true
				for i, t in ipairs(queue) do
					if t == thread then 
						table.remove(queue, i) 
						break 
					end
				end
				safeResume(thread)
			end)
		end
		
		coroutine.yield()
		local wasTimedOutOrCancelled = finished
		finished = true -- prevent stale timeout/cancel callbacks from spuriously resuming
		if token then token:ThrowIfCancelled() end
		if timeout and wasTimedOutOrCancelled then timeoutError("Semaphore.Acquire", timeout) end
	end
	
	function sem:Release()
		if #queue > 0 then
			local nextThread = table.remove(queue, 1)
			if nextThread ~= nil then safeResume(nextThread) end
		else
			count += 1
			if count > maxCount then
				count = maxCount
				warn("[Await.Semaphore] release overflow")
			end
		end
	end
	
	return sem :: Semaphore
end

-- ====================================
-- // ALIASES
-- ====================================

--// Await.Race
Await.Race = Await.Any

return Await