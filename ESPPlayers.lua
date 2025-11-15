local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Создаем глобальную функцию для выживших
_G.ESPPlayers = function(enabled)
    if not _G.PlayersESP then
        _G.PlayersESP = {
            Enabled = false,
            CurrentSurvivors = {},
            Highlights = {},
            Connections = {},
            LastCommand = false
        }
    end
    
    local ESP = _G.PlayersESP
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
            
            for _, nameTag in pairs(ESP.NameTags or {}) do
                if nameTag and nameTag.billboard then
                    nameTag.billboard:Destroy()
                end
            end
            ESP.NameTags = {}
            
            ESP.CurrentSurvivors = {}
        end
        
        -- Ищем выживших
        local survivorsFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Survivors")
        if not survivorsFolder then 
            warn("Survivors folder not found!")
            return false 
        end
        
        local survivors = {}
        for _, child in pairs(survivorsFolder:GetChildren()) do
            if child:IsA("Model") then
                table.insert(survivors, child)
            end
        end
        
        if #survivors == 0 then
            warn("No survivors found!")
            return false
        end
        
        ESP.CurrentSurvivors = survivors
        ESP.NameTags = {}
        
        -- Создаем теги и подсветку для каждого выжившего
        for _, survivor in pairs(survivors) do
            local rootPart = survivor:FindFirstChild("HumanoidRootPart") or 
                             survivor:FindFirstChild("Head") or 
                             survivor:FindFirstChildWhichIsA("BasePart")
            
            if not rootPart then 
                warn("No root part found for survivor: " .. survivor.Name)
                continue 
            end
            
            -- BillboardGui
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "SurvivorESP_" .. survivor.Name
            billboard.Adornee = rootPart
            billboard.Size = UDim2.new(0, 250, 0, 50)
            billboard.StudsOffset = Vector3.new(0, 3.5, 0)
            billboard.AlwaysOnTop = true
            billboard.MaxDistance = 2000
            billboard.Parent = rootPart
            
            -- Фон - ПРОЗРАЧНЫЙ
            local background = Instance.new("Frame")
            background.Size = UDim2.new(1, 0, 1, 0)
            background.BackgroundColor3 = Color3.new(0, 0, 0)
            background.BackgroundTransparency = 1.0 -- ПОЛНОСТЬЮ ПРОЗРАЧНЫЙ
            background.BorderSizePixel = 0
            background.Parent = billboard
            
            -- Имя выжившего
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
            nameLabel.BackgroundTransparency = 1 -- Прозрачный фон
            nameLabel.Text = survivor.Name
            nameLabel.TextColor3 = Color3.new(0, 1, 0) -- ЗЕЛЕНЫЙ ЦВЕТ
            nameLabel.TextStrokeTransparency = 0.2 -- Полупрозрачная обводка
            nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
            nameLabel.TextSize = 16
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.Parent = billboard
            
            -- Дистанция
            local distanceLabel = Instance.new("TextLabel")
            distanceLabel.Size = UDim2.new(1, 0, 0.4, 0)
            distanceLabel.Position = UDim2.new(0, 0, 0.6, 0)
            distanceLabel.BackgroundTransparency = 1 -- Прозрачный фон
            distanceLabel.Text = "0m"
            distanceLabel.TextColor3 = Color3.new(1, 1, 1)
            distanceLabel.TextStrokeTransparency = 0.2 -- Полупрозрачная обводка
            distanceLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
            distanceLabel.TextSize = 12
            distanceLabel.Font = Enum.Font.Gotham
            distanceLabel.Parent = billboard
            
            ESP.NameTags[survivor] = {
                billboard = billboard,
                nameLabel = nameLabel,
                distanceLabel = distanceLabel,
                rootPart = rootPart
            }
            
            -- Подсветка частей выжившего ЗЕЛЕНЫМ цветом
            local function highlightParts(obj)
                if obj:IsA("BasePart") then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "SurvivorPartHighlight"
                    highlight.Adornee = obj
                    highlight.FillColor = Color3.new(0, 1, 0) -- ЗЕЛЕНЫЙ ЗАЛИВКА
                    highlight.FillTransparency = 0.4
                    highlight.OutlineColor = Color3.new(0.2, 1, 0.2) -- ЗЕЛЕНАЯ ОБВОДКА
                    highlight.OutlineTransparency = 0
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Parent = obj
                    table.insert(ESP.Highlights, highlight)
                end
                
                for _, child in pairs(obj:GetChildren()) do
                    highlightParts(child)
                end
            end
            
            highlightParts(survivor)
            
            -- Отслеживание удаления выжившего
            ESP.Connections["survivorRemoved_" .. survivor.Name] = survivor.AncestryChanged:Connect(function(_, parent)
                if parent == nil then
                    -- Удаляем тег и подсветку для этого выжившего
                    if ESP.NameTags[survivor] and ESP.NameTags[survivor].billboard then
                        ESP.NameTags[survivor].billboard:Destroy()
                        ESP.NameTags[survivor] = nil
                    end
                    
                    -- Обновляем список выживших
                    for i, surv in pairs(ESP.CurrentSurvivors) do
                        if surv == survivor then
                            table.remove(ESP.CurrentSurvivors, i)
                            break
                        end
                    end
                end
            end)
        end
        
        -- Обновление расстояния для всех выживших
        ESP.Connections.distanceUpdate = RunService.Heartbeat:Connect(function()
            if not ESP.Enabled or not ESP.NameTags then return end
            
            local localPlayer = Players.LocalPlayer
            local localCharacter = localPlayer.Character
            local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
            
            if not localRoot then return end
            
            for survivor, nameTag in pairs(ESP.NameTags) do
                if not nameTag or not nameTag.distanceLabel or not nameTag.rootPart then
                    continue
                end
                
                local distance = (localRoot.Position - nameTag.rootPart.Position).Magnitude
                nameTag.distanceLabel.Text = math.floor(distance) .. "m"
                
                -- Цвет дистанции
                if distance < 15 then
                    nameTag.distanceLabel.TextColor3 = Color3.new(1, 0, 0)
                elseif distance < 30 then
                    nameTag.distanceLabel.TextColor3 = Color3.new(1, 1, 0)
                else
                    nameTag.distanceLabel.TextColor3 = Color3.new(1, 1, 1)
                end
            end
        end)
        
        -- Отслеживание появления новых выживших
        local survivorsFolder = workspace.Players.Survivors
        ESP.Connections.newSurvivorAdded = survivorsFolder.ChildAdded:Connect(function(child)
            wait(1) -- Ждем немного для инициализации модели
            if child:IsA("Model") and ESP.LastCommand then
                -- Перезапускаем ESP для включения нового выжившего
                _G.ESPPlayers(true)
            end
        end)
        
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
        
        if ESP.NameTags then
            for _, nameTag in pairs(ESP.NameTags) do
                if nameTag and nameTag.billboard then
                    nameTag.billboard:Destroy()
                end
            end
            ESP.NameTags = {}
        end
        
        ESP.CurrentSurvivors = {}
        return true
    end
end

-- Авто-обновление
spawn(function()
    while true do
        wait(3)
        if _G.PlayersESP then
            local ESP = _G.PlayersESP
            
            -- Автоматическое переподключение если ESP был включен но отключился
            if ESP.LastCommand and not ESP.Enabled then
                _G.ESPPlayers(true)
            end
            
            -- Проверяем актуальность выживших
            if ESP.Enabled and ESP.NameTags then
                local needsRefresh = false
                
                -- Проверяем существование выживших
                for survivor, nameTag in pairs(ESP.NameTags) do
                    if not survivor.Parent or not nameTag.rootPart or not nameTag.rootPart.Parent then
                        needsRefresh = true
                        break
                    end
                end
                
                -- Проверяем появление новых выживших
                local survivorsFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Survivors")
                if survivorsFolder then
                    local currentCount = 0
                    for _, child in pairs(survivorsFolder:GetChildren()) do
                        if child:IsA("Model") then
                            currentCount = currentCount + 1
                            if not ESP.NameTags[child] then
                                needsRefresh = true
                                break
                            end
                        end
                    end
                    
                    if currentCount ~= #ESP.CurrentSurvivors then
                        needsRefresh = true
                    end
                end
                
                if needsRefresh and ESP.LastCommand then
                    _G.ESPPlayers(true)
                end
            end
        end
    end
end)
