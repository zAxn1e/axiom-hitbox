--[[

	Axiom Core - Await Documentation
	====================================

	Author: Iv_0x

	Module: Await
	Core Version: 1.3.0
	Docs Status: Up-to-date

	Compatibility:
	- Axiom Core >= 1.3.0
	- Roblox Luau runtime

	Last Updated: 2026-01-04
	
	====================================

	This document details the Await synchronization library,
	its design philosophy, primitives, and usage patterns.

	This file is documentation-only.
	It is NOT required by any runtime module.

	----------------------------------------------------
	1. Overview
	----------------------------------------------------

	Await is a lightweight, production-grade synchronization
	library built explicitly for the Roblox scheduler.

	Unlike generic Promise libraries, Await embraces
	Roblox's native coroutine model (`task.spawn`, `task.wait`)
	to provide deterministic and efficient concurrency.

	Key Objectives:
	- Predictable scheduling semantics
	- Structured cooperative cancellation
	- Deterministic resource cleanup
	- Zero-allocation wherever possible

	----------------------------------------------------
	2. Design Philosophy
	----------------------------------------------------

	Await is NOT a Promise implementation.

	It avoids:
	- Deeply nested method chains (.then().then())
	- Implicit error swallowing
	- "Magic" state management

	It promotes:
	- Flat, imperative control flow
	- Explicit error boundaries (Await.Try)
	- Manual but clear token-based cancellation

	----------------------------------------------------
	3. Cancellation Model
	----------------------------------------------------

	Cancellation in Await is **Cooperative**.

	- Threads are never force-killed externally.
	- Cancellation is propagated via `CancelToken`.
	- Workflows must explicitly check for cancellation.

	Creating a Token:
	
		local token = Await.Token()
		
		-- Child tokens are cancelled when parent is cancelled
		local subToken = token:Child() 

	Checking Cancellation:

		-- Throws an error if the token is cancelled
		token:ThrowIfCancelled()

	Auto-Cancellation:

		-- Token automatically cancels when 'part' is destroyed
		token:LinkToInstance(part)

	----------------------------------------------------
	4. Core Primitives
	----------------------------------------------------

	Await.Signal(signal, timeout?, token?)
		Yields until an RBXScriptSignal fires.
		Returns the signal arguments.
		Throws error on timeout or cancellation.

	Await.Any(tasks, timeout?, token?)
		Runs tasks in parallel. Resumes when the FIRST
		task completes successfully.
		Returns results from the winning task.

	Await.All(tasks, timeout?, opts?, token?)
		Synchronization barrier. Waits for ALL tasks.
		Does not aggregate return values.
		opts.throw = true to rethrow the first error encountered.

	Await.Sleep(seconds, token?)
		A wrapper around task.delay that supports
		cancellation and token validation.

	Await.Condition(predicate, timeout?, interval?)
		Polls the predicate function until it returns true.

	----------------------------------------------------
	5. Functional Utilities
	----------------------------------------------------

	Await.Try(fn) -> Result
		Executes a function safely.
		Returns a result object:
		{ success: true, values: {...} } OR { success: false, error: ... }

	Await.Retry(fn, maxAttempts, opts?)
		Retries a function upon failure.
		Supports linear backoff and cancellation.

	Await.Debounce(fn, delay, opts?)
		Coalesces multiple calls into a single execution
		after the delay window.

	Await.Throttle(fn, window, opts?)
		Ensures a function is executed at most once
		per specified time window.

	Await.Queue()
		Returns a function wrapper that serializes
		execution in First-In-First-Out (FIFO) order.

	----------------------------------------------------
	6. Concurrency Primitives
	----------------------------------------------------

	These primitives manage access to shared resources.

	Mutex (Mutual Exclusion):
		Allows only one thread to access a resource at a time.
		
		local lock = Await.Mutex()
		lock:Scoped(function()
			-- Critical section
		end)

	Semaphore:
		Limits concurrent access to a set number (N).
		Useful for rate-limiting or connection pooling.

	----------------------------------------------------
	7. Scheduler Semantics
	----------------------------------------------------

	Await operates on the Roblox task scheduler.

	Important considerations:
	- `timeout` is not real-time; it depends on framerate.
	- `Debounce` and `Throttle` guarantees are loose
	  due to frame-alignment (Heartbeat).
	- Cancellation is checked at "Safe Points" (yields).

	----------------------------------------------------
	8. Best Practices
	----------------------------------------------------

	+ Always pass `token` to long-running async operations.
	+ Use `Await.Try` instead of `pcall` for structured data.
	+ Prefer `Await.All` for initializing multiple systems.
	+ Use `Mutex` when modifying shared table state.
	+ Do not assume exact millisecond precision for timeouts.

	----------------------------------------------------
	9. Appendix
	----------------------------------------------------

	Cancellation Propagation:
	Destroying an Instance linked via `LinkToInstance`
	is the recommended way to clean up tasks associated
	with game objects (e.g., Units, UI, Effects).

]]

return {}