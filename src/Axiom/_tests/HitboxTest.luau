--!strict
-- Axiom Unit Test Suite
-- Module: HitboxTest
-- Purpose: Automated validation for Hitbox lifecycle, pool recycling, state transitions, sphere shapes, and interval resets.

local Axiom = script.Parent.Parent
local Hitbox = require(Axiom:WaitForChild("Hitbox"))
local CharacterService = require(Axiom:WaitForChild("Service"):WaitForChild("CharacterService"))

local HitboxTest = {}

function HitboxTest.RunAllTests()
	print("========================================")
	print("🧪 Starting Axiom v1.4.0 Test Suite...")
	print("========================================")

	local passed = 0
	local failed = 0

	local function assertTest(name: string, condition: boolean, errMessage: string?)
		if condition then
			passed += 1
			print(`  ✅ PASS: {name}`)
		else
			failed += 1
			warn(`  ❌ FAIL: {name} - {errMessage or "Assertion failed"}`)
		end
	end

	-- ----------------------------------------------------
	-- TEST 1: State Machine & Re-start Transition
	-- ----------------------------------------------------
	do
		local hb = Hitbox.new()
		assertTest("Initial State is Idle", hb:GetState() == "Idle")

		hb:Start()
		assertTest("State after Start is Active", hb:IsActive())

		hb:Stop()
		assertTest("State after Stop is Stopped", hb:GetState() == "Stopped")

		-- Test Stopped -> Active transition (BUG-01 Fix)
		hb:Start()
		assertTest("Re-start from Stopped transitions to Active", hb:IsActive())

		hb:Stop()
		hb:Destroy()
		assertTest("State after Destroy is cleaned", not hb:IsActive())
	end

	-- ----------------------------------------------------
	-- TEST 2: Sphere Shape & Radius Configuration
	-- ----------------------------------------------------
	do
		local hb = Hitbox.new()
		hb.Shape = "Sphere"
		hb.Radius = 15

		assertTest("Hitbox Shape is Sphere", hb.Shape == "Sphere")
		assertTest("Hitbox Radius is 15", hb.Radius == 15)

		hb:Destroy()
	end

	-- ----------------------------------------------------
	-- TEST 3: Hit Reset Interval Property
	-- ----------------------------------------------------
	do
		local hb = Hitbox.new()
		hb.HitResetInterval = 0.25

		assertTest("HitResetInterval is set", hb.HitResetInterval == 0.25)
		hb:Destroy()
	end

	-- ----------------------------------------------------
	-- TEST 4: Pool Recycling & Zero Memory Leak
	-- ----------------------------------------------------
	do
		local initialStats = Hitbox.GetPoolStats()
		local activeHitboxes = {}

		for i = 1, 50 do
			local hb = Hitbox.new()
			hb.Size = Vector3.new(i, i, i)
			hb:Start()
			table.insert(activeHitboxes, hb)
		end

		local activeStats = Hitbox.GetPoolStats()
		assertTest("Pool acquired 50 hitboxes", activeStats.inUse >= 50)

		for _, hb in ipairs(activeHitboxes) do
			hb:Destroy()
		end

		local endStats = Hitbox.GetPoolStats()
		assertTest("Pool fully released all hitboxes (inUse == 0)", endStats.inUse == 0)
	end

	-- ----------------------------------------------------
	-- TEST 5: Attachment CFrame Setting
	-- ----------------------------------------------------
	do
		local hb = Hitbox.new()
		local att = Instance.new("Attachment")
		hb:SetCFrame(att)

		assertTest("SetCFrame accepts Attachment instance", hb.CFrame == att)
		att:Destroy()
		hb:Destroy()
	end

	-- ----------------------------------------------------
	-- TEST 6: Vector3 CFrame Setting & Auto-Conversion
	-- ----------------------------------------------------
	do
		local hb = Hitbox.new()
		local pos = Vector3.new(10, 20, 30)
		hb:SetCFrame(pos)

		assertTest("SetCFrame accepts Vector3 position", hb.CFrame == pos)
		hb:Destroy()
	end

	print("========================================")
	print(`📊 Test Results: {passed} Passed | {failed} Failed`)
	print("========================================")

	return failed == 0
end

return HitboxTest
