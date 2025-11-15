local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Создаем глобальную функцию для генераторов
_G.ESPGenerators = function(enabled)
    if not _G.GeneratorsESP then
        _G.GeneratorsESP = {
            Enabled = false,
            Generators = {},
            FakeGenerators = {},
            Highlights = {},
            Connections = {},
            LastCommand = false,
            NameTags = {}
        }
    end
    
    local ESP = _G.GeneratorsESP
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
            
            for _, nameTag in pairs(ESP.NameTags) do
                if nameTag and nameTag.billboard then
                    nameTag.billboard:Destroy()
                end
            end
            ESP.NameTags = {}
            
            ESP.Generators = {}
            ESP.FakeGenerators = {}
        end
        
        -- Ищем генераторы
        local mapFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Ingame") and workspace.Map.Ingame:FindFirstChild("Map")
        if not mapFolder then 
            warn("Map folder not found!")
            return false 
        end
        
        -- Переименовываем и собираем настоящие генераторы
        local generatorCount = 1
        local generators = {}
        local fakeGenerators = {}
        
        for _, child in pairs(mapFolder:GetChildren()) do
            if child.Name == "Generator" then
                -- Переименовываем генераторы
                local newName = "Generator" .. generatorCount
                while mapFolder:FindFirstChild(newName) do
                    generatorCount = generatorCount + 1
                    newName = "Generator" .. generatorCount
                end
                child.Name = newName
                table.insert(generators, child)
                generatorCount = generatorCount + 1
                
            elseif child.Name == "FakeGenerator" then
                table.insert(fakeGenerators, child)
            end
        end
        
        if #generators == 0 and #fakeGenerators == 0 then
            warn("No generators found!")
            return false
        end
        
        ESP.Generators = generators
        ESP.FakeGenerators = fakeGenerators
        
        -- Функция для создания ESP объекта
        local function createGeneratorESP(generator, isFake)
            local rootPart = generator:FindFirstChildWhichIsA("BasePart")
            if not rootPart then 
                warn("No root part found for generator: " .. generator.Name)
                return nil
            end
            
            -- Ищем Progress StringValue
            local progressValue = generator:FindFirstChild("Progress")
            if not progressValue or not progressValue:IsA("StringValue") then
                warn("No Progress StringValue found for generator: " .. generator.Name)
            end
            
            -- BillboardGui
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "GeneratorESP_" .. generator.Name
            billboard.Adornee = rootPart
            billboard.Size = UDim2.new(0, 300, 0, 60)
            billboard.StudsOffset = Vector3.new(0, 4, 0)
            billboard.AlwaysOnTop = true
            billboard.MaxDistance = 2000
            billboard.Parent = rootPart
            
            -- Фон - ПРОЗРАЧНЫЙ
            local background = Instance.new("Frame")
            background.Size = UDim2.new(1, 0, 1, 0)
            background.BackgroundColor3 = Color3.new(0, 0, 0)
            background.BackgroundTransparency = 1.0
            background.BorderSizePixel = 0
            background.Parent = billboard
            
            -- Название генератора
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = generator.Name .. (isFake and " (FAKE)" or "")
            nameLabel.TextColor3 = isFake and Color3.new(1, 0, 0) or Color3.new(1, 1, 0) -- Красный для фейков, желтый для настоящих
            nameLabel.TextStrokeTransparency = 0.2
            nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
            nameLabel.TextSize = 14
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.Parent = billboard
            
            -- Прогресс
            local progressLabel = Instance.new("TextLabel")
            progressLabel.Size = UDim2.new(1, 0, 0.3, 0)
            progressLabel.Position = UDim2.new(0, 0, 0.4, 0)
            progressLabel.BackgroundTransparency = 1
            progressLabel.Text = progressValue and "Progress: " .. progressValue.Value .. "%" or "Progress: N/A"
            progressLabel.TextColor3 = Color3.new(1, 1, 1)
            progressLabel.TextStrokeTransparency = 0.2
            progressLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
            progressLabel.TextSize = 12
            progressLabel.Font = Enum.Font.Gotham
            progressLabel.Parent = billboard
            
            -- Дистанция
            local distanceLabel = Instance.new("TextLabel")
            distanceLabel.Size = UDim2.new(1, 0, 0.3, 0)
            distanceLabel.Position = UDim2.new(0, 0, 0.7, 0)
            distanceLabel.BackgroundTransparency = 1
            distanceLabel.Text = "0m"
            distanceLabel.TextColor3 = Color3.new(1, 1, 1)
            distanceLabel.TextStrokeTransparency = 0.2
            distanceLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
            distanceLabel.TextSize = 12
            distanceLabel.Font = Enum.Font.Gotham
            distanceLabel.Parent = billboard
            
            local espData = {
                billboard = billboard,
                nameLabel = nameLabel,
                progressLabel = progressLabel,
                distanceLabel = distanceLabel,
                rootPart = rootPart,
                progressValue = progressValue,
                isFake = isFake,
                currentProgress = progressValue and tonumber(progressValue.Value) or 0
            }
            
            -- Подсветка генератора
            local highlight = Instance.new("Highlight")
            highlight.Name = "GeneratorHighlight"
            highlight.Adornee = generator
            highlight.FillTransparency = 0.6
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            
            -- Устанавливаем цвет в зависимости от типа и прогресса
            if isFake then
                -- Фейк генератор - всегда красный
                highlight.FillColor = Color3.new(1, 0, 0)
                highlight.OutlineColor = Color3.new(1, 0.2, 0.2)
            else
                -- Настоящий генератор - желтый, при 100% - зеленый
                if espData.currentProgress >= 100 then
                    highlight.FillColor = Color3.new(0, 1, 0)
                    highlight.OutlineColor = Color3.new(0.2, 1, 0.2)
                    nameLabel.TextColor3 = Color3.new(0, 1, 0) -- Зеленый текст для завершенных
                else
                    highlight.FillColor = Color3.new(1, 1, 0)
                    highlight.OutlineColor = Color3.new(1, 1, 0.2)
                end
            end
            
            highlight.Parent = generator
            table.insert(ESP.Highlights, highlight)
            
            return espData
        end
        
        -- Создаем ESP для настоящих генераторов
        for _, generator in pairs(generators) do
            local espData = createGeneratorESP(generator, false)
            if espData then
                ESP.NameTags[generator] = espData
            end
        end
        
        -- Создаем ESP для фейковых генераторов
        for _, fakeGenerator in pairs(fakeGenerators) do
            local espData = createGeneratorESP(fakeGenerator, true)
            if espData then
                ESP.NameTags[fakeGenerator] = espData
            end
        end
        
        -- Обновление расстояния и прогресса
        ESP.Connections.update = RunService.Heartbeat:Connect(function()
            if not ESP.Enabled or not ESP.NameTags then return end
            
            local localPlayer = Players.LocalPlayer
            local localCharacter = localPlayer.Character
            local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
            
            if not localRoot then return end
            
            for generator, espData in pairs(ESP.NameTags) do
                if not espData or not espData.distanceLabel or not espData.rootPart then
                    continue
                end
                
                -- Обновление расстояния
                local distance = (localRoot.Position - espData.rootPart.Position).Magnitude
                espData.distanceLabel.Text = math.floor(distance) .. "m"
                
                -- Цвет дистанции
                if distance < 10 then
                    espData.distanceLabel.TextColor3 = Color3.new(0, 1, 0)
                elseif distance < 25 then
                    espData.distanceLabel.TextColor3 = Color3.new(1, 1, 0)
                else
                    espData.distanceLabel.TextColor3 = Color3.new(1, 1, 1)
                end
                
                -- Обновление прогресса
                if espData.progressValue then
                    local currentProgress = tonumber(espData.progressValue.Value) or 0
                    espData.progressLabel.Text = "Progress: " .. espData.progressValue.Value .. "%"
                    
                    -- Обновляем цвет если прогресс изменился
                    if not espData.isFake and currentProgress ~= espData.currentProgress then
                        espData.currentProgress = currentProgress
                        
                        -- Находим highlight для этого генератора
                        local highlight = generator:FindFirstChild("GeneratorHighlight")
                        if highlight then
                            if currentProgress >= 100 then
                                -- Зеленый для завершенных генераторов
                                highlight.FillColor = Color3.new(0, 1, 0)
                                highlight.OutlineColor = Color3.new(0.2, 1, 0.2)
                                espData.nameLabel.TextColor3 = Color3.new(0, 1, 0)
                            else
                                -- Желтый для незавершенных
                                highlight.FillColor = Color3.new(1, 1, 0)
                                highlight.OutlineColor = Color3.new(1, 1, 0.2)
                                espData.nameLabel.TextColor3 = Color3.new(1, 1, 0)
                            end
                        end
                    end
                end
            end
        end)
        
        -- Отслеживание изменений в папке генераторов
        ESP.Connections.childAdded = mapFolder.ChildAdded:Connect(function(child)
            wait(0.5) -- Ждем немного для инициализации
            
            if ESP.LastCommand then
                if child.Name == "Generator" or child.Name == "FakeGenerator" then
                    -- Перезапускаем ESP для включения нового генератора
                    _G.ESPGenerators(true)
                end
            end
        end)
        
        ESP.Connections.childRemoved = mapFolder.ChildRemoved:Connect(function(child)
            if ESP.LastCommand then
                if ESP.NameTags[child] then
                    -- Удаляем ESP данные для удаленного генератора
                    if ESP.NameTags[child].billboard then
                        ESP.NameTags[child].billboard:Destroy()
                    end
                    ESP.NameTags[child] = nil
                    
                    -- Перезапускаем ESP для обновления списка
                    _G.ESPGenerators(true)
                end
            end
        end)
        
        ESP.Enabled = true
        print("Generators ESP activated: " .. #generators .. " real, " .. #fakeGenerators .. " fake")
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
            for _, espData in pairs(ESP.NameTags) do
                if espData and espData.billboard then
                    espData.billboard:Destroy()
                end
            end
            ESP.NameTags = {}
        end
        
        ESP.Generators = {}
        ESP.FakeGenerators = {}
        print("Generators ESP deactivated")
        return true
    end
end

-- Авто-обновление
spawn(function()
    while true do
        wait(5) -- Проверяем реже, т.к. генераторы не часто меняются
        if _G.GeneratorsESP then
            local ESP = _G.GeneratorsESP
            
            -- Автоматическое переподключение если ESP был включен но отключился
            if ESP.LastCommand and not ESP.Enabled then
                _G.ESPGenerators(true)
            end
            
            -- Проверяем актуальность генераторов
            if ESP.Enabled and ESP.NameTags then
                local needsRefresh = false
                local mapFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Ingame") and workspace.Map.Ingame:FindFirstChild("Map")
                
                if mapFolder then
                    -- Проверяем существование генераторов
                    for generator in pairs(ESP.NameTags) do
                        if not generator.Parent then
                            needsRefresh = true
                            break
                        end
                    end
                    
                    -- Проверяем появление новых генераторов
                    for _, child in pairs(mapFolder:GetChildren()) do
                        if (child.Name == "Generator" or child.Name:find("Generator%d")) and child.Name ~= "FakeGenerator" then
                            if not ESP.NameTags[child] then
                                needsRefresh = true
                                break
                            end
                        elseif child.Name == "FakeGenerator" then
                            if not ESP.NameTags[child] then
                                needsRefresh = true
                                break
                            end
                        end
                    end
                end
                
                if needsRefresh and ESP.LastCommand then
                    _G.ESPGenerators(true)
                end
            end
        end
    end
end)
