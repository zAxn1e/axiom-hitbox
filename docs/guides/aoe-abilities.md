# Radial & Explosion AoE Attacks

Spherical spatial queries (`hb.Shape = "Sphere"`) are ideal for ground slams, spell explosions, and area-of-effect (AoE) shockwaves.

---

## Example: Ground Slam Explosion

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Axiom = ReplicatedStorage:WaitForChild("Axiom")
local Hitbox = require(Axiom.Hitbox)

local function TriggerGroundSlam(casterCharacter: Model, slamPosition: Vector3)
    local hb = Hitbox.new()
    hb.Shape = "Sphere"
    hb.Radius = 16 -- 16 studs radius spherical blast
    hb.CFrame = slamPosition
    hb.Duration = 0.15 -- Quick instant explosion burst
    hb.Ignore = { casterCharacter }

    hb.OnHit:Connect(function(targetModel: Model, targetHumanoid: Humanoid, hitPart: BasePart)
        -- Falloff damage calculation based on distance from center
        local targetRoot = targetModel:FindFirstChild("HumanoidRootPart")
        local distance = if targetRoot then (targetRoot.Position - slamPosition).Magnitude else 0
        
        local maxDamage = 50
        local minDamage = 15
        local damageRatio = math.clamp(1 - (distance / hb.Radius), 0, 1)
        local finalDamage = minDamage + (damageRatio * (maxDamage - minDamage))

        targetHumanoid:TakeDamage(finalDamage)
    end)

    hb:Start()

    task.delay(0.2, function()
        hb:Destroy()
    end)
end
```
