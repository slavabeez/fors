-- Вставьте этот код в главный Script (ServerScriptService или StarterPlayerScripts)
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Создаем глобальную таблицу ESP
shared.ESPKiller = {
    Enabled = false,
    CurrentKiller = nil,
    Highlights = {},
    Connections = {},
    LastCommand = false
}

-- Глобальная функция
_G.ESPKiller = function(enabled)
    local ESP = shared.ESPKiller
    ESP.LastCommand = enabled
    
    if enabled then
        -- Инициализация ESP
        if ESP.Enabled then
            ESP:Cleanup()
        end
        
        -- Ищем убийцу
        local killersFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers")
        if not killersFolder then 
            return false 
        end
        
        local killer = nil
        for _, child in pairs(killersFolder:GetChildren()) do
            if child:IsA("Model") or child:IsA("BasePart") then
                killer = child
                break
            end
        end
        
        if not killer then
            return false
        end
        
        ESP.CurrentKiller = killer
        
        -- Создаем тег
        local head = killer:FindFirstChild("Head")
        local trackingPart = head or killer:FindFirstChild("HumanoidRootPart") or killer:FindFirstChildWhichIsA("BasePart")
        
        if not trackingPart then return false end
        
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "KillerESP_" .. killer.Name
        billboard.Adornee = trackingPart
        billboard.Size = UDim2.new(0, 300, 0, 40)
        billboard.StudsOffset = Vector3.new(0, 4, 0)
        billboard.AlwaysOnTop = true
        billboard.MaxDistance = 2000
        billboard.Parent = trackingPart
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = killer.Name
        nameLabel.TextColor3 = Color3.new(1, 0, 0)
        nameLabel.TextStrokeTransparency = 0.3
        nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        nameLabel.TextSize = 16
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.Parent = billboard
        
        ESP.NameTag = {
            billboard = billboard,
            nameLabel = nameLabel,
            trackingPart = trackingPart
        }
        
        -- Подсвечиваем части
        local function highlightParts(obj)
            if obj:IsA("BasePart") then
                local highlight = Instance.new("Highlight")
                highlight.Name = "KillerPartHighlight"
                highlight.Adornee = obj
                highlight.FillColor = Color3.new(1, 0, 0)
                highlight.FillTransparency = 0.7
                highlight.OutlineTransparency = 1
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Parent = obj
                table.insert(ESP.Highlights, highlight)
            end
            
            for _, child in pairs(obj:GetChildren()) do
                highlightParts(child)
            end
        end
        
        highlightParts(killer)
        
        -- Обновление расстояния
        ESP.Connections.distanceUpdate = RunService.Heartbeat:Connect(function()
            if not ESP.Enabled or not ESP.NameTag or not ESP.NameTag.nameLabel then return end
            
            local localPlayer = Players.LocalPlayer
            local localCharacter = localPlayer.Character
            local localHead = localCharacter and localCharacter:FindFirstChild("Head")
            
            if not localHead or not ESP.CurrentKiller then return end
            
            local killerTrackingPart = ESP.NameTag.trackingPart
            if not killerTrackingPart then return end
            
            local distance = (localHead.Position - killerTrackingPart.Position).Magnitude
            
            local displayText = ESP.CurrentKiller.Name .. " [" .. math.floor(distance) .. "m]"
            ESP.NameTag.nameLabel.Text = displayText
            
            if distance < 15 then
                ESP.NameTag.nameLabel.TextColor3 = Color3.new(1, 0, 0)
            elseif distance < 30 then
                ESP.NameTag.nameLabel.TextColor3 = Color3.new(1, 1, 0)
            else
                ESP.NameTag.nameLabel.TextColor3 = Color3.new(0, 1, 0)
            end
        end)
        
        -- Отслеживание удаления убийцы
        ESP.Connections.killerRemoved = killer.AncestryChanged:Connect(function()
            if not ESP.CurrentKiller or not ESP.CurrentKiller.Parent then
                if ESP.Connections.reinitialize then
                    ESP.Connections.reinitialize:Disconnect()
                end
                
                ESP.Connections.reinitialize = RunService.Heartbeat:Connect(function()
                    wait(1)
                    ESP.Connections.reinitialize:Disconnect()
                    
                    if ESP.LastCommand then
                        _G.ESPKiller(true)
                    end
                end)
            end
        end)
        
        ESP.Enabled = true
        return true
        
    else
        -- Очистка ESP
        ESP.Enabled = false
        
        for name, connection in pairs(ESP.Connections) do
            if connection then
                connection:Disconnect()
            end
        end
        ESP.Connections = {}
        
        for _, highlight in pairs(ESP.Highlights) do
            if highlight then
                highlight:Destroy()
            end
        end
        ESP.Highlights = {}
        
        if ESP.NameTag and ESP.NameTag.billboard then
            ESP.NameTag.billboard:Destroy()
            ESP.NameTag = nil
        end
        
        ESP.CurrentKiller = nil
        return true
    end
end

-- Авто-обновление
spawn(function()
    while true do
        wait(2)
        local ESP = shared.ESPKiller
        
        if ESP.LastCommand and not ESP.Enabled then
            _G.ESPKiller(true)
        end
        
        if ESP.Enabled and ESP.CurrentKiller and not ESP.CurrentKiller.Parent then
            if ESP.Connections.reinitialize then
                ESP.Connections.reinitialize:Disconnect()
            end
            
            ESP.Connections.reinitialize = RunService.Heartbeat:Connect(function()
                wait(1)
                ESP.Connections.reinitialize:Disconnect()
                
                if ESP.LastCommand then
                    _G.ESPKiller(true)
                end
            end)
        end
    end
end)
