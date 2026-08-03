--!strict
-- Axiom Hitbox Framework
-- Module: Hitbox
-- Version: 1.4.0

--// Services
local RunService = game:GetService("RunService")

local Axiom = script.Parent
local Signal = require(Axiom.Core:WaitForChild("Signal"))
local HitboxState = require(script:WaitForChild("State"))
local Pool = require(script:WaitForChild("Pool"))
local Types = require(Axiom.Core:WaitForChild("Types"))

--// Export Types
export type HitboxPredictionMethod = Types.HitboxPredictionMethod
export type HitboxShape = Types.HitboxShape
export type Hitbox = Types.Hitbox

--// Internal Constants
local DEFAULT_POOL_WARM = 30

--// Class
local Hitbox = {}
Hitbox.__index = Hitbox

--// Helper Functions
local function applyAngularPrediction(cf: CFrame, angVel: Vector3, dt: number): CFrame
	local speed = angVel.Magnitude
	if speed == 0 then return cf end
	return cf * CFrame.fromAxisAngle(angVel / speed, speed * dt)
end

--// Factory
local function createHitbox(): Hitbox
	local self = setmetatable({}, Hitbox)
	
	local object = self :: any
	object.StateMachine = HitboxState.new("Idle")
	object.OnStart = Signal.new()
	object.OnStop = Signal.new()
	object.OnUpdate = Signal.new()
	object.OnHit = Signal.new()
	
	object._humCache = setmetatable({}, { __mode = "k" })
	object._defaultOverlap = OverlapParams.new()
	object._defaultOverlap.FilterType = Enum.RaycastFilterType.Exclude
	object._defaultOverlap.RespectCanCollide = false
	
	object._hit = {}
	object._conn = nil
	object._visualizerPart = nil
	object._elapsed = 0
	object._destroyed = false
	object._activeOverlap = OverlapParams.new()
	
	object.Size = Vector3.new(4,4,4)
	object.Shape = "Box"
	object.Radius = 4
	object.HitResetInterval = nil
	object._lastHitReset = 0
	object.CFrame = CFrame.identity
	object.Offset = CFrame.identity
	object.Duration = math.huge
	object.Visualizer = false
	object.UsePrediction = false
	object.PredictionTime = 0.06
	object.PredictionMethod = "Linear"
	object.Ignore = {}
	object.OverlapParams = nil
	
	return object :: Hitbox
end

local function resetHitbox(self: Hitbox)
	if self._conn then
		self._conn:Disconnect()
		self._conn = nil
	end
	
	self:_hideVisualizer()
	
	self.Size = Vector3.new(4,4,4)
	self.Shape = "Box"
	self.Radius = 4
	self.HitResetInterval = nil
	self._lastHitReset = 0
	self.CFrame = CFrame.identity
	self.Offset = CFrame.identity
	self.Duration = math.huge
	self.Visualizer = false
	self.OverlapParams = nil
	self._elapsed = 0
	
	self.UsePrediction = false
	self.PredictionTime = 0.06
	self.PredictionMethod = "Linear"
	
	if not self.Ignore then self.Ignore = {} end
	table.clear(self.Ignore)
	
	table.clear(self._hit)
	table.clear(self._humCache)
	
	self.StateMachine:set("Idle")
	self._destroyed = false
end

--// POOL
type Pool<T> = Pool.Pool<T> 
local _POOL: Pool<Hitbox> = Pool.new(createHitbox, resetHitbox) :: any
_POOL:warm(DEFAULT_POOL_WARM)

--// API
function Hitbox.new(): Hitbox
	return _POOL:acquire()
end

function Hitbox:SetCFrame(cf: CFrame | BasePart | Attachment | Vector3)
	self.CFrame = cf
end

function Hitbox:Start()
	if self._destroyed then
		warn("Attempt to use Hitbox after Destroy()")
		return
	end
	if not self.StateMachine:set("Active") then return end
	
	self.Duration = ((self.Duration :: number?) or math.huge) :: number
	
	self.Offset = self.Offset or CFrame.identity
	self._destroyed = false
	
	table.clear(self._hit :: any) 
	self._lastHitReset = 0
	
	if type(self.Ignore) ~= "table" then self.Ignore = {} end
	
	local sourceParams = self.OverlapParams or self._defaultOverlap
	local activeOverlap = self._activeOverlap or OverlapParams.new()
	activeOverlap.FilterType = sourceParams.FilterType
	activeOverlap.CollisionGroup = sourceParams.CollisionGroup
	activeOverlap.RespectCanCollide = sourceParams.RespectCanCollide
	activeOverlap.MaxParts = sourceParams.MaxParts
	activeOverlap.Tolerance = sourceParams.Tolerance

	if not self.OverlapParams then
		activeOverlap.FilterDescendantsInstances = self.Ignore
	else
		activeOverlap.FilterDescendantsInstances = sourceParams.FilterDescendantsInstances
	end
	self._activeOverlap = activeOverlap

	self._elapsed = 0
	self.OnStart:FireSafe(self)
	self:_ensureVisualizer()
	
	local durationLimit = self.Duration
	self._conn = RunService.Heartbeat:Connect(function(dt: number)
		self._elapsed += dt
		if (self._elapsed >= durationLimit) or (self._destroyed) then
			self:Stop()
			return
		end

		local baseCFrame = self:_resolveBaseCFrame()
		if not baseCFrame then
			self:Stop()
			return
		end

		self:_updateVisualizer(baseCFrame)
		self.OnUpdate:FireFast(dt, self)
		self:_update(baseCFrame)
	end)
end

function Hitbox:Stop()
	if not self.StateMachine:set("Stopped") then return end

	if self._conn then
		self._conn:Disconnect()
		self._conn = nil :: any
	end

	self:_hideVisualizer()
	self.OnStop:FireSafe(self)
end

function Hitbox:_cleanup()
	if self._conn then
		self._conn:Disconnect()
		self._conn = nil :: any
	end

	self.OnHit:DisconnectAllFast()
	self.OnUpdate:DisconnectAllFast()
	self.OnStart:DisconnectAllFast()
	self.OnStop:DisconnectAllFast()

	if self._visualizerPart then
		self._visualizerPart:Destroy()
		self._visualizerPart = nil :: any
	end
end

function Hitbox:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	self:_cleanup()

	_POOL:release(self)
end

--// State Queries
function Hitbox:GetState(): string
	return self.StateMachine.current
end

function Hitbox:Is(state: string): boolean
	return self.StateMachine:is(state)
end

function Hitbox:IsActive(): boolean
	return self.StateMachine:is("Active")
end

--// Internals
function Hitbox:_update(baseCFrame: CFrame)
	local activeOverlap = self._activeOverlap
	if not activeOverlap then return end

	-- Check HitResetInterval for continuous/channeling attacks
	local interval = self.HitResetInterval
	if interval and interval > 0 then
		if self._elapsed - (self._lastHitReset or 0) >= interval then
			self._lastHitReset = self._elapsed
			table.clear(self._hit)
		end
	end

	local cf = baseCFrame * (self.Offset or CFrame.identity)
	local parts: {BasePart}

	if self.Shape == "Sphere" then
		local r = self.Radius or (self.Size.X / 2)
		parts = workspace:GetPartBoundsInRadius(cf.Position, r, activeOverlap)
	else
		parts = workspace:GetPartBoundsInBox(cf, self.Size, activeOverlap)
	end

	for _, part in ipairs(parts) do
		local parent = part.Parent
		if parent and self._hit[parent] then
			continue
		end

		local model = part:FindFirstAncestorOfClass("Model")
		if model and not self._hit[model] then
			local hum = self._humCache[model]
			if not hum then
				hum = model:FindFirstChildOfClass("Humanoid")
				if hum then self._humCache[model] = hum end
			end

			if hum then
				self._hit[model] = true
				self.OnHit:FireSafe(model, hum, part)
			end
		end
	end
end

function Hitbox:_resolveBaseCFrame(): CFrame?
	if typeof(self.CFrame) == "CFrame" then
		return self.CFrame :: CFrame
	elseif typeof(self.CFrame) == "Vector3" then
		return CFrame.new(self.CFrame :: Vector3)
	end

	local part = self.CFrame
	if typeof(part) == "Instance" then
		if part:IsA("Attachment") then
			local att = part :: Attachment
			if not att:IsDescendantOf(game) then return nil end
			return att.WorldCFrame
		elseif part:IsA("BasePart") then
			local basePart = part :: BasePart
			if not basePart:IsDescendantOf(game) then return nil end

			if not self.UsePrediction then return basePart.CFrame end
			
			local dt = (self.PredictionTime or 0) :: number
			if dt <= 0 then return basePart.CFrame end

			local method = self.PredictionMethod or "Linear"
			local cf = basePart.CFrame

			if method == "Linear" or method == "LinearAngular" then
				cf = cf + basePart.AssemblyLinearVelocity * dt
			end

			if method == "Angular" or method == "LinearAngular" then
				cf = applyAngularPrediction(cf, basePart.AssemblyAngularVelocity, dt)
			end

			return cf
		end
	end

	return CFrame.identity
end

--// Debug visualization
function Hitbox:_ensureVisualizer()
	if not self.Visualizer then return end

	if not self._visualizerPart then
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Transparency = 0.7
		p.Color = Color3.fromRGB(255,60,60)
		p.Material = Enum.Material.Neon
		self._visualizerPart = p
	end

	self._visualizerPart.Parent = workspace
end

function Hitbox:_updateVisualizer(baseCFrame: CFrame)
	if not self._visualizerPart or not self.Visualizer then return end

	if self.Shape == "Sphere" then
		local r = self.Radius or (self.Size.X / 2)
		self._visualizerPart.Shape = Enum.PartType.Ball
		self._visualizerPart.Size = Vector3.new(r * 2, r * 2, r * 2)
	else
		self._visualizerPart.Shape = Enum.PartType.Block
		self._visualizerPart.Size = self.Size
	end

	self._visualizerPart.CFrame = baseCFrame * self.Offset
end

function Hitbox:_hideVisualizer()
	if self._visualizerPart then
		self._visualizerPart.Parent = nil
	end
end

function Hitbox.GetPoolStats()
	return _POOL:stats()
end

return Hitbox