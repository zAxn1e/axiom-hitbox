# Channeling Skills & Persistent Auras

For continuous channeled abilities (laser beams, whirlwinds, or poison clouds), use **`HitResetInterval`** combined with long `Duration` settings.

---

## Example: Spin Attack / Whirlwind

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Axiom = ReplicatedStorage:WaitForChild("Axiom")
local Hitbox = require(Axiom.Hitbox)

local function StartWhirlwind(casterCharacter: Model, duration: number)
    local root = casterCharacter:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local hb = Hitbox.new()
    hb.Shape = "Sphere"
    hb.Radius = 10
    hb.CFrame = root
    hb.Duration = duration
    
    -- Reset hit memory every 0.4 seconds -> hits targets 2.5x per second
    hb.HitResetInterval = 0.4 
    hb.Ignore = { casterCharacter }

    hb.OnHit:Connect(function(targetModel: Model, targetHumanoid: Humanoid)
        targetHumanoid:TakeDamage(8)
    end)

    hb:Start()

    -- Automatically release back to pool when channeling ends
    task.delay(duration + 0.1, function()
        hb:Destroy()
    end)
end
```
