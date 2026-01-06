--!strict

-- Axiom Core
-- Module: CharacterService
-- Purpose: Managed, type-safe access to LocalPlayer character lifecycle
-- Version: 1.3.0

--[[
	Axiom Character Service
	
	High-level Intent
	- Provide a guaranteed, synchronous-looking API for accessing Character components
	- Abstract away Roblox's asynchronous character loading chaos
	- Eliminate repetitive `WaitForChild` and nil-checking in client logic
	- Centralize character state tracking for the LocalPlayer
	
	Design Goals
	- Strict Type Safety (Luau strict mode compliant)
	- Race-Condition Proof (Handles late joins, fast respawns, and cleanup)
	- Yield-Until-Ready (Getters automatically block until components exist)
	- Zero-overhead access once initialized (Cached references)
	
	------------------------------------------------------------
	LIFECYCLE MANAGEMENT
	------------------------------------------------------------
	- Automatically binds to Player.CharacterAdded
	- Resolves critical components (Root, Humanoid, Animator) internally
	- Safe unbinding on CharacterRemoving to prevent memory leaks
	- Self-initializes on require (Lazy loading)
	
	------------------------------------------------------------
	ACCESS PATTERNS (API)
	------------------------------------------------------------
	Getters (Yielding):
		* Get() -> (Model, Root, Humanoid, Animator)
		* GetCharacter() -> Model
		* GetHumanoid() -> Humanoid
		* GetRoot() -> BasePart
		* GetAnimator() -> Animator
	
	Note: All Getters guarantee non-nil returns. They will yield 
	execution via Axiom.Await if the character is currently missing 
	or spawning.
	
	------------------------------------------------------------
	SIGNALS & EVENTS
	------------------------------------------------------------
	CharacterService.CharacterAdded
		* Fires with (Model) after all internal components are bound
		* Guaranteed to be safe for immediate consumption
		
	CharacterService.CharacterRemoving
		* Fires with (Model) just before cleanup
		
	------------------------------------------------------------
	STATE (READ-ONLY)
	------------------------------------------------------------
	Exposed properties are nullable (?) types for direct inspection:
		.Character
		.Root
		.Humanoid
		.Animator
		
	Use these for non-blocking checks (e.g., UI updates).
	Use Getters for game logic requiring the character.
--]]

local Players = game:GetService("Players")
local Player = Players.LocalPlayer :: Player

local Axiom = script.Parent.Parent
local Signal = require(Axiom.Core:WaitForChild("Signal"))
local Await = require(Axiom.Core:WaitForChild("Await"))

-- Types
export type CharacterService = {
	-- State (read-only externally)
	Character: Model?,
	Root: BasePart?,
	Humanoid: Humanoid?,
	Animator: Animator?,

	-- Signals
	CharacterAdded: Signal.Signal<Model>,
	CharacterRemoving: Signal.Signal<Model>,

	-- API
	GetCharacter: (self: CharacterService) -> Model,
	GetHumanoid: (self: CharacterService) -> Humanoid,
	GetAnimator: (self: CharacterService) -> Animator,
	GetRoot: (self: CharacterService) -> BasePart,
	Get: (self: CharacterService) -> (Model, BasePart, Humanoid, Animator),

	-- Internal
	_initialized: boolean,
	_Init: (self: CharacterService) -> (),
	_Bind: (self: CharacterService, char: Model) -> (),
	_Unbind: (self: CharacterService) -> (),
	_AwaitReady: (self: CharacterService) -> () ,
}

-- Implementation
local CharacterService: CharacterService = {} :: any

-- State
CharacterService.Character = nil
CharacterService.Root = nil
CharacterService.Humanoid = nil
CharacterService.Animator = nil

-- Signals
CharacterService.CharacterAdded = Signal.new()
CharacterService.CharacterRemoving = Signal.new()

-- Internal
CharacterService._initialized = false

function CharacterService:_Init()
	if self._initialized then
		return
	end
	self._initialized = true

	Player.CharacterAdded:Connect(function(char)
		self:_Bind(char)
	end)

	Player.CharacterRemoving:Connect(function()
		self:_Unbind()
	end)

	local currentCharacter = Player.Character
	if currentCharacter then
		self:_Bind(currentCharacter)
	end
end

function CharacterService:_Bind(char: Model)
	local root = char:WaitForChild("HumanoidRootPart") :: BasePart
	local humanoid = char:WaitForChild("Humanoid") :: Humanoid
	local animator = humanoid:WaitForChild("Animator") :: Animator

	self.Character = char
	self.Root = root
	self.Humanoid = humanoid
	self.Animator = animator

	self.CharacterAdded:FireSafe(char)
end

function CharacterService:_Unbind()
	if self.Character then
		self.CharacterRemoving:FireSafe(self.Character)
	end

	self.Character = nil
	self.Root = nil
	self.Humanoid = nil
	self.Animator = nil
end

function CharacterService:_AwaitReady()
	if not self.Character then
		Await.Signal(self.CharacterAdded)
	end
end

function CharacterService:GetCharacter(): Model
	self:_AwaitReady()

	local character = assert(self.Character, "Character missing")
	return character :: Model
end


function CharacterService:GetHumanoid(): Humanoid
	if self.Humanoid then
		return self.Humanoid
	end

	Await.Signal(self.CharacterAdded :: any)
	local Humanoid = assert(self.Humanoid, "Humanoid missing")
	return Humanoid :: Humanoid
end

function CharacterService:GetAnimator(): Animator
	if self.Animator then
		return self.Animator
	end

	Await.Signal(self.CharacterAdded)
	local Animator = assert(self.Animator, "Animator missing")
	return Animator :: Animator
end

function CharacterService:GetRoot(): BasePart
	if self.Root then
		return self.Root
	end

	Await.Signal(self.CharacterAdded)
	local Root = assert(self.Root, "Root missing")
	return Root :: BasePart
end

function CharacterService:Get()
	self:_AwaitReady()

	return assert(self.Character), assert(self.Root), assert(self.Humanoid), assert(self.Animator)
end

-- Self Init
if not CharacterService._initialized then
	CharacterService:_Init()
end

return CharacterService