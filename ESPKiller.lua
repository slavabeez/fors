-- Вставь этот код по ссылке: https://raw.githubusercontent.com/slavabeez/fors/refs/heads/main/ESPKiller.lua

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Создаем глобальную таблицу
_G.KillerESP = {
    Enabled = false,
    CurrentKiller = nil,
    Highlights = {},
    Connections = {},
    LastCommand = false
}

-- Глобальная функция ESPKiller
_G.ESPKiller = function(enabled)
    local ESP = _G.KillerESP
    ESP.LastCommand = enabled
    
    if enabled then
        -- Включение ESP
        if ESP.Enabled then
            -- Очищаем перед повторной инициализацией
            for name, connection in pairs(ESP.Connections) do
                if connection then connection:Disconnect() end
            end
            ESP.Connections = {}
            
            for _, highlight in pairs(ESP.Highlights) do
                if highlight then highlight:Destroy() end
            end
            ESP.Highlights = {}
            
            if ESP.NameTag and ESP.NameTag.billboard then
                ESP.NameTag.billboard:Destroy()
                ESP.NameTag = nil
            end
            
            ESP.CurrentKiller = nil
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
        local rootPart = killer:FindFirstChild("HumanoidRootPart") or 
                         killer:FindFirstChild("Head") or 
                         killer:FindFirstChildWhichIsA("BasePart")
        
        if not rootPart then 
            return false 
        end
        
        -- BillboardGui
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "KillerESP_" .. killer.Name
        billboard.Adornee = rootPart
        billboard.Size = UDim2.new(0, 250, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3.5, 0)
        billboard.AlwaysOnTop = true
        billboard.MaxDistance = 2000
        billboard.Parent = rootPart
        
        -- Фон
        local background = Instance.new("Frame")
        background.Size = UDim2.new(1, 0, 1, 0)
        background.BackgroundColor3 = Color3.new(0, 0, 0)
        background.BackgroundTransparency = 0.6
        background.BorderSizePixel = 0
        background.Parent = billboard
        
        -- Имя убийцы
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = killer.Name
        nameLabel.TextColor3 = Color3.new(1, 0, 0)
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        nameLabel.TextSize = 16
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.Parent = billboard
        
        -- Дистанция
        local distanceLabel = Instance.new("TextLabel")
        distanceLabel.Size = UDim2.new(1, 0, 0.4, 0)
        distanceLabel.Position = UDim2.new(0, 0, 0.6, 0)
        distanceLabel.BackgroundTransparency = 1
        distanceLabel.Text = "0m"
        distanceLabel.TextColor3 = Color3.new(1, 1, 1)
        distanceLabel.TextStrokeTransparency = 0
        distanceLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        distanceLabel.TextSize = 12
        distanceLabel.Font = Enum.Font.Gotham
        distanceLabel.Parent = billboard
        
        ESP.NameTag = {
            billboard = billboard,
            nameLabel = nameLabel,
            distanceLabel = distanceLabel,
            rootPart = rootPart
        }
        
        -- Подсветка частей
        local function highlightParts(obj)
            if obj:IsA("BasePart") then
                local highlight = Instance.new("Highlight")
                highlight.Name = "KillerPartHighlight"
                highlight.Adornee = obj
                highlight.FillColor = Color3.new(1, 0, 0)
                highlight.FillTransparency = 0.4
                highlight.OutlineColor = Color3.new(1, 0.2, 0.2)
                highlight.OutlineTransparency = 0
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
            if not ESP.Enabled or not ESP.NameTag or not ESP.NameTag.distanceLabel then return end
            
            local localPlayer = Players.LocalPlayer
            local localCharacter = localPlayer.Character
            local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
            
            if not localRoot or not ESP.CurrentKiller then return end
            
            local killerRoot = ESP.NameTag.rootPart
            if not killerRoot then return end
            
            local distance = (localRoot.Position - killerRoot.Position).Magnitude
            ESP.NameTag.distanceLabel.Text = math.floor(distance) .. "m"
            
            -- Цвет дистанции
            if distance < 15 then
                ESP.NameTag.distanceLabel.TextColor3 = Color3.new(1, 0, 0)
                ESP.NameTag.nameLabel.TextColor3 = Color3.new(1, 0, 0)
            elseif distance < 30 then
                ESP.NameTag.distanceLabel.TextColor3 = Color3.new(1, 1, 0)
                ESP.NameTag.nameLabel.TextColor3 = Color3.new(1, 1, 0)
            else
                ESP.NameTag.distanceLabel.TextColor3 = Color3.new(0, 1, 0)
                ESP.NameTag.nameLabel.TextColor3 = Color3.new(1, 0, 0)
            end
        end)
        
        -- Отслеживание удаления убийцы
        if ESP.CurrentKiller then
            ESP.Connections.killerRemoved = ESP.CurrentKiller.AncestryChanged:Connect(function(_, parent)
                if parent == nil then
                    -- Переинициализация через 1 секунду
                    if ESP.Connections.reinitialize then
                        ESP.Connections.reinitialize:Disconnect()
                    end
                    
                    ESP.Connections.reinitialize = RunService.Heartbeat:Connect(function()
                        wait(1)
                        if ESP.Connections.reinitialize then
                            ESP.Connections.reinitialize:Disconnect()
                        end
                        
                        if ESP.LastCommand then
                            _G.ESPKiller(true)
                        end
                    end)
                end
            end)
        end
        
        ESP.Enabled = true
        return true
        
    else
        -- Выключение ESP
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
        wait(3)
        local ESP = _G.KillerESP
        
        if ESP.LastCommand and not ESP.Enabled then
            _G.ESPKiller(true)
        end
        
        if ESP.Enabled and ESP.CurrentKiller and not ESP.CurrentKiller.Parent then
            if ESP.Connections.reinitialize then
                ESP.Connections.reinitialize:Disconnect()
            end
            
            ESP.Connections.reinitialize = RunService.Heartbeat:Connect(function()
                wait(1)
                if ESP.Connections.reinitialize then
                    ESP.Connections.reinitialize:Disconnect()
                end
                
                if ESP.LastCommand then
                    _G.ESPKiller(true)
                end
            end)
        end
    end
end)

print("ESPKiller loaded! Use ESPKiller(true/false) anywhere!")
