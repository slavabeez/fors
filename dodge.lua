-- HitboxDetector.lua
-- Полностью совместим с ползунком Slider

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer

local HitboxDetector = {}

function HitboxDetector.Start(callback, radius)
    local isActive = true
    local detectionRadius = radius or 5

    local character = localPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    -- Подписываемся на изменения персонажа
    local charAddedConn = localPlayer.CharacterAdded:Connect(function(char)
        character = char
        root = char:WaitForChild("HumanoidRootPart", 3)
    end)

    local hitboxFolder = Workspace:FindFirstChild("Hitboxes")

    -- Защита: ждём если Hitboxes ещё нет
    if not hitboxFolder then
        hitboxFolder = Workspace.ChildAdded:Wait()
        if hitboxFolder.Name ~= "Hitboxes" then
            hitboxFolder = Workspace:WaitForChild("Hitboxes")
        end
    end

    local function isValidHitbox(part)
        if not part:IsA("BasePart") then return false end
        if part:GetAttribute("Hidden") == true then return false end
        if string.find(part.Name, localPlayer.Name) then return false end
        return true
    end

    local function checkHitboxDistance(hitbox)
        if not character or not root then return false end
        if not hitbox or not hitbox.Parent then return false end

        local distance = (hitbox.Position - root.Position).Magnitude
        return distance <= detectionRadius
    end

    local heartbeatConn = RunService.Heartbeat:Connect(function()
        if not isActive then return end
        if not character or not root then return end
        if not hitboxFolder then return end

        for _, hitbox in ipairs(hitboxFolder:GetChildren()) do
            if isValidHitbox(hitbox) and checkHitboxDistance(hitbox) then
                callback(hitbox, localPlayer, character)
            end
        end
    end)

    -- Функция остановки
    local function stop()
        isActive = false
        if heartbeatConn then heartbeatConn:Disconnect() end
        if charAddedConn then charAddedConn:Disconnect() end
    end

    return stop
end

return HitboxDetector
