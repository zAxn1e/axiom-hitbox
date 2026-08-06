--!strict
-- Axiom Performance & Benchmark Test Suite
-- Module: HitboxPerformanceTest
-- Purpose: Detailed empirical benchmarks for allocation pressure, spatial query throughput, fast-path hit lookup, and pool O(1) performance.
-- Version: 1.4.0

local Axiom = script.Parent.Parent
local Hitbox = require(Axiom:WaitForChild("Hitbox"))
local Pool = require(Axiom:WaitForChild("Hitbox"):WaitForChild("Pool"))
local Types = require(Axiom.Core:WaitForChild("Types"))

local HitboxPerformanceTest = {}

function HitboxPerformanceTest.RunAllBenchmarks()
	print("==========================================================")
	print("⚡ Starting Axiom v1.4.0 Performance & Benchmark Suite")
	print("==========================================================")

	local results = {}

	-- Helper for microsecond timing
	local function measureTimeMicroseconds(fn: () -> ()): number
		local start = os.clock()
		fn()
		local elapsed = os.clock() - start
		return elapsed * 1000000 -- Convert to microseconds
	end

	-- ----------------------------------------------------
	-- BENCHMARK 1: OverlapParams Zero-Allocation Pressure
	-- ----------------------------------------------------
	do
		print("\n📊 Benchmark 1: OverlapParams Allocation & Start/Stop Lifecycle")
		local ITERATIONS = 10000

		local hb = Hitbox.new()
		hb.Size = Vector3.new(6, 6, 6)
		hb.CFrame = CFrame.identity

		local totalMicros = measureTimeMicroseconds(function()
			for _ = 1, ITERATIONS do
				hb:Start()
				hb:Stop()
			end
		end)

		hb:Destroy()

		local perOpMicros = totalMicros / ITERATIONS
		print(`  - Iterations: {ITERATIONS} Start/Stop cycles`)
		print(`  - Total Elapsed: {string.format("%.2f", totalMicros / 1000)} ms`)
		print(`  - Average Latency: {string.format("%.3f", perOpMicros)} µs / operation`)
		table.insert(results, { name = "OverlapParams Lifecycle", ops = ITERATIONS, avgMicros = perOpMicros })
	end

	-- ----------------------------------------------------
	-- BENCHMARK 2: Spatial Query Throughput (Box vs Sphere)
	-- ----------------------------------------------------
	do
		print("\n📊 Benchmark 2: Spatial Query Performance (Box vs Sphere)")
		local ITERATIONS = 5000

		-- Test Box Query
		local hbBox = Hitbox.new()
		hbBox.Shape = "Box"
		hbBox.Size = Vector3.new(10, 10, 10)
		hbBox:Start()

		local boxMicros = measureTimeMicroseconds(function()
			for _ = 1, ITERATIONS do
				(hbBox :: any):_update(CFrame.identity)
			end
		end)
		hbBox:Destroy()

		-- Test Sphere Query
		local hbSphere = Hitbox.new()
		hbSphere.Shape = "Sphere"
		hbSphere.Radius = 10
		hbSphere:Start()

		local sphereMicros = measureTimeMicroseconds(function()
			for _ = 1, ITERATIONS do
				(hbSphere :: any):_update(CFrame.identity)
			end
		end)
		hbSphere:Destroy()

		print(`  - Box Query ({ITERATIONS} ops): {string.format("%.2f", boxMicros / 1000)} ms ({string.format("%.3f", boxMicros / ITERATIONS)} µs/op)`)
		print(`  - Sphere Query ({ITERATIONS} ops): {string.format("%.2f", sphereMicros / 1000)} ms ({string.format("%.3f", sphereMicros / ITERATIONS)} µs/op)`)
		table.insert(results, { name = "Box Spatial Query", ops = ITERATIONS, avgMicros = boxMicros / ITERATIONS })
		table.insert(results, { name = "Sphere Spatial Query", ops = ITERATIONS, avgMicros = sphereMicros / ITERATIONS })
	end

	-- ----------------------------------------------------
	-- BENCHMARK 3: Fast-Path Hit Lookup Throughput
	-- ----------------------------------------------------
	do
		print("\n📊 Benchmark 3: Fast-Path Hit Lookup & Filter Overhead")
		local ITERATIONS = 50000

		local dummyHitMap: {[Instance]: boolean} = {}
		local dummyModel = Instance.new("Model")

		-- Pre-populate hit map to simulate active hit tracking
		dummyHitMap[dummyModel] = true

		local hitLookupMicros = measureTimeMicroseconds(function()
			for _ = 1, ITERATIONS do
				-- Simulate fast-path lookup check
				local parent: Instance? = dummyModel
				local hit = if parent then dummyHitMap[parent] else false
				if hit then
					-- Fast-path skip
				end
			end
		end)

		dummyModel:Destroy()

		print(`  - Fast-Path Lookups ({ITERATIONS} ops): {string.format("%.2f", hitLookupMicros / 1000)} ms`)
		print(`  - Average Lookup Overhead: {string.format("%.4f", hitLookupMicros / ITERATIONS)} µs / lookup`)
		table.insert(results, { name = "Fast-Path Hit Lookup", ops = ITERATIONS, avgMicros = hitLookupMicros / ITERATIONS })
	end

	-- ----------------------------------------------------
	-- BENCHMARK 4: O(1) Object Pool Acquisition & Stats
	-- ----------------------------------------------------
	do
		print("\n📊 Benchmark 4: Pool O(1) Acquire, Release & Stats Overhead")
		local ACQUIRE_CYCLES = 20000
		local STATS_CYCLES = 100000

		local poolHitboxes: {Hitbox.Hitbox} = {}

		local acquireMicros = measureTimeMicroseconds(function()
			for _ = 1, ACQUIRE_CYCLES do
				local hb = Hitbox.new()
				table.insert(poolHitboxes, hb)
			end
		end)

		local statsMicros = measureTimeMicroseconds(function()
			for _ = 1, STATS_CYCLES do
				Hitbox.GetPoolStats()
			end
		end)

		local releaseMicros = measureTimeMicroseconds(function()
			for _, hb: Hitbox.Hitbox in ipairs(poolHitboxes) do
				hb:Destroy()
			end
		end)

		print(`  - Pool Acquire ({ACQUIRE_CYCLES} ops): {string.format("%.2f", acquireMicros / 1000)} ms ({string.format("%.3f", acquireMicros / ACQUIRE_CYCLES)} µs/op)`)
		print(`  - Pool Release ({ACQUIRE_CYCLES} ops): {string.format("%.2f", releaseMicros / 1000)} ms ({string.format("%.3f", releaseMicros / ACQUIRE_CYCLES)} µs/op)`)
		print(`  - Pool Stats O(1) Check ({STATS_CYCLES} ops): {string.format("%.2f", statsMicros / 1000)} ms ({string.format("%.4f", statsMicros / STATS_CYCLES)} µs/op)`)

		table.insert(results, { name = "Pool Acquire", ops = ACQUIRE_CYCLES, avgMicros = acquireMicros / ACQUIRE_CYCLES })
		table.insert(results, { name = "Pool Release", ops = ACQUIRE_CYCLES, avgMicros = releaseMicros / ACQUIRE_CYCLES })
		table.insert(results, { name = "Pool Stats O(1)", ops = STATS_CYCLES, avgMicros = statsMicros / STATS_CYCLES })
	end

	-- ----------------------------------------------------
	-- BENCHMARK 5: HitResetInterval Continuous Attack Reset
	-- ----------------------------------------------------
	do
		print("\n📊 Benchmark 5: Continuous HitResetInterval Memory & Loop Overhead")
		local RESET_CYCLES = 10000

		local hb = Hitbox.new()
		hb.HitResetInterval = 0.05
		hb:Start()

		local intervalMicros = measureTimeMicroseconds(function()
			for i = 1, RESET_CYCLES do
				(hb :: any)._elapsed = i * 0.01
				(hb :: any):_update(CFrame.identity)
			end
		end)

		hb:Destroy()

		print(`  - Continuous Reset Updates ({RESET_CYCLES} ops): {string.format("%.2f", intervalMicros / 1000)} ms ({string.format("%.3f", intervalMicros / RESET_CYCLES)} µs/op)`)
		table.insert(results, { name = "HitResetInterval Updates", ops = RESET_CYCLES, avgMicros = intervalMicros / RESET_CYCLES })
	end

	-- ----------------------------------------------------
	-- SUMMARY TABLE
	-- ----------------------------------------------------
	print("\n==========================================================")
	print("📈 AXIOM BENCHMARK SUMMARY RESULTS")
	print("==========================================================")
	print(string.format("%-32s | %-12s | %-15s", "Benchmark Name", "Operations", "Avg Latency (µs)"))
	print("----------------------------------------------------------")
	for _, res in ipairs(results) do
		print(string.format("%-32s | %-12d | %-15.4f", res.name, res.ops, res.avgMicros))
	end
	print("==========================================================\n")

	return results
end

return HitboxPerformanceTest
