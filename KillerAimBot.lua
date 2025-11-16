-- Скрипт для loadstring
if _G.KillerAimBot then
    _G.KillerAimBot:Stop()
    _G.KillerAimBot = nil
end

_G.KillerAimBot = {
    Settings = {
        Enabled = false,
        MaxDistance = 50,
        UpdateInterval = 0.1,
        SmoothAim = true,
        Smoothness = 0.5,
        AimHeightOffset = 0
    }
}

-- Локальные переменные
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local connection = nil
local lastUpdate = 0
local currentKiller = nil

-- Локальные функции
local function findKiller()
    local killersFolder = workspace:FindFirstChild("Players")
    if killersFolder then
        killersFolder = killersFolder:FindFirstChild("Killers")
        if killersFolder then
            for _, killerModel in pairs(killersFolder:GetChildren()) do
                if killerModel:IsA("Model") and killerModel:FindFirstChild("Humanoid") and killerModel.Humanoid.Health > 0 then
                    return killerModel
                end
            end
        end
    end
    return nil
end

local function getSurvivors()
    local survivors = {}
    local survivorsFolder = workspace:FindFirstChild("Players")
    if survivorsFolder then
        survivorsFolder = survivorsFolder:FindFirstChild("Survivors")
        if survivorsFolder then
            for _, survivor in pairs(survivorsFolder:GetChildren()) do
                if survivor:IsA("Model") and survivor:FindFirstChild("Humanoid") and survivor.Humanoid.Health > 0 then
                    table.insert(survivors, survivor)
                end
            end
        end
    end
    return survivors
end

local function findNearestSurvivor(killerPosition)
    local survivors = getSurvivors()
    local nearestSurvivor = nil
    local shortestDistance = _G.KillerAimBot.Settings.MaxDistance
    
    for _, survivor in pairs(survivors) do
        local humanoidRootPart = survivor:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            local distance = (killerPosition - humanoidRootPart.Position).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                nearestSurvivor = survivor
            end
        end
    end
    
    return nearestSurvivor, shortestDistance
end

local function lookAtTarget(killer, targetPosition)
    local humanoidRootPart = killer:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local killerPosition = humanoidRootPart.Position
    
    -- Применяем смещение по высоте
    local targetWithOffset = Vector3.new(
        targetPosition.X,
        targetPosition.Y + _G.KillerAimBot.Settings.AimHeightOffset,
        targetPosition.Z
    )
    
    local direction = (targetWithOffset - killerPosition).Unit
    
    if _G.KillerAimBot.Settings.SmoothAim then
        -- Плавный поворот
        local currentLook = humanoidRootPart.CFrame.LookVector
        local smoothFactor = _G.KillerAimBot.Settings.Smoothness
        local smoothedDirection = currentLook:Lerp(direction, smoothFactor)
        
        local lookVector = Vector3.new(smoothedDirection.X, 0, smoothedDirection.Z)
        if lookVector.Magnitude > 0 then
            humanoidRootPart.CFrame = CFrame.new(killerPosition, killerPosition + lookVector)
        end
    else
        -- Мгновенный поворот
        local lookVector = Vector3.new(direction.X, 0, direction.Z)
        if lookVector.Magnitude > 0 then
            humanoidRootPart.CFrame = CFrame.new(killerPosition, killerPosition + lookVector)
        end
    end
end

local function updateAimBot(deltaTime)
    if not _G.KillerAimBot.Settings.Enabled then return end
    
    lastUpdate = lastUpdate + deltaTime
    if lastUpdate < _G.KillerAimBot.Settings.UpdateInterval then return end
    lastUpdate = 0
    
    -- Поиск убийцы если он не найден или удален
    if not currentKiller or not currentKiller.Parent then
        currentKiller = findKiller()
        if not currentKiller then return end
    end
    
    local killerRoot = currentKiller:FindFirstChild("HumanoidRootPart")
    if not killerRoot then return end
    
    local nearestSurvivor, distance = findNearestSurvivor(killerRoot.Position)
    if nearestSurvivor then
        local survivorRoot = nearestSurvivor:FindFirstChild("HumanoidRootPart")
        if survivorRoot then
            lookAtTarget(currentKiller, survivorRoot.Position)
        end
    end
end

-- Глобальные функции для управления
function _G.KillerAimBot:Start()
    if connection then
        connection:Disconnect()
    end
    
    self.Settings.Enabled = true
    currentKiller = findKiller()
    
    connection = RunService.Heartbeat:Connect(updateAimBot)
    print("KillerAimBot: Started")
end

function _G.KillerAimBot:Stop()
    if connection then
        connection:Disconnect()
        connection = nil
    end
    
    self.Settings.Enabled = false
    currentKiller = nil
    print("KillerAimBot: Stopped")
end

function _G.KillerAimBot:Toggle()
    if self.Settings.Enabled then
        self:Stop()
    else
        self:Start()
    end
end

function _G.KillerAimBot:SetMaxDistance(distance)
    self.Settings.MaxDistance = distance
    print("KillerAimBot: MaxDistance set to", distance)
end

function _G.KillerAimBot:SetUpdateInterval(interval)
    self.Settings.UpdateInterval = interval
    print("KillerAimBot: UpdateInterval set to", interval)
end

function _G.KillerAimBot:SetSmoothAim(enabled)
    self.Settings.SmoothAim = enabled
    print("KillerAimBot: SmoothAim", enabled and "enabled" or "disabled")
end

function _G.KillerAimBot:SetSmoothness(value)
    self.Settings.Smoothness = math.clamp(value, 0.1, 1.0)
    print("KillerAimBot: Smoothness set to", self.Settings.Smoothness)
end

function _G.KillerAimBot:SetAimHeightOffset(offset)
    self.Settings.AimHeightOffset = offset
    print("KillerAimBot: AimHeightOffset set to", offset)
end

function _G.KillerAimBot:GetStatus()
    return {
        Enabled = self.Settings.Enabled,
        KillerFound = currentKiller ~= nil,
        MaxDistance = self.Settings.MaxDistance
    }
end
