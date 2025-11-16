local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

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
        
        local mapFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Ingame") and workspace.Map.Ingame:FindFirstChild("Map")
        if not mapFolder then 
            return false 
        end
        
        local generators = {}
        local fakeGenerators = {}
        
        for i = 1, 5 do
            local generatorName = "Generator" .. i
            local generator = mapFolder:FindFirstChild(generatorName)
            if generator then
                table.insert(generators, generator)
            end
        end
        
        local baseGenerator = mapFolder:FindFirstChild("Generator")
        if baseGenerator then
            -- Переименовываем новый генератор
            local newName = "Generator1"
            local count = 1
            while mapFolder:FindFirstChild(newName) do
                count = count + 1
                newName = "Generator" .. count
            end
            if count <= 5 then
                baseGenerator.Name = newName
                table.insert(generators, baseGenerator)
            end
        end
        
        local fakeGenerator = mapFolder:FindFirstChild("FakeGenerator")
        if fakeGenerator then
            table.insert(fakeGenerators, fakeGenerator)
        end
        
        if #generators == 0 and #fakeGenerators == 0 then
            return false
        end
        
        ESP.Generators = generators
        ESP.FakeGenerators = fakeGenerators
        
        local function createGeneratorESP(generator, isFake)
            local rootPart = generator:FindFirstChildWhichIsA("BasePart")
            if not rootPart then 
                return nil
            end
            
            local progressValue = generator:FindFirstChild("Progress")
            if not progressValue or not progressValue:IsA("StringValue") then
            end
            
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "GeneratorESP_" .. generator.Name
            billboard.Adornee = rootPart
            billboard.Size = UDim2.new(0, 300, 0, 60)
            billboard.StudsOffset = Vector3.new(0, 4, 0)
            billboard.AlwaysOnTop = true
            billboard.MaxDistance = 2000
            billboard.Parent = rootPart
            
            local background = Instance.new("Frame")
            background.Size = UDim2.new(1, 0, 1, 0)
            background.BackgroundColor3 = Color3.new(0, 0, 0)
            background.BackgroundTransparency = 1.0
            background.BorderSizePixel = 0
            background.Parent = billboard
            
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
            
            local highlight = Instance.new("Highlight")
            highlight.Name = "GeneratorHighlight"
            highlight.Adornee = generator
            highlight.FillTransparency = 0.6
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            
            if isFake then
                -- Фейк генератор - всегда красный
                highlight.FillColor = Color3.new(1, 0, 0)
                highlight.OutlineColor = Color3.new(1, 0.2, 0.2)
            else
                if espData.currentProgress >= 100 then
                    highlight.FillColor = Color3.new(0, 1, 0)
                    highlight.OutlineColor = Color3.new(0.2, 1, 0.2)
                    nameLabel.TextColor3 = Color3.new(0, 1, 0)
                else
                    highlight.FillColor = Color3.new(1, 1, 0)
                    highlight.OutlineColor = Color3.new(1, 1, 0.2)
                end
            end
            
            highlight.Parent = generator
            table.insert(ESP.Highlights, highlight)
            
            return espData
        end
        
        for _, generator in pairs(generators) do
            local espData = createGeneratorESP(generator, false)
            if espData then
                ESP.NameTags[generator] = espData
            end
        end
        
        for _, fakeGenerator in pairs(fakeGenerators) do
            local espData = createGeneratorESP(fakeGenerator, true)
            if espData then
                ESP.NameTags[fakeGenerator] = espData
            end
        end
        
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
            
                local distance = (localRoot.Position - espData.rootPart.Position).Magnitude
                espData.distanceLabel.Text = math.floor(distance) .. "m"
                
                if distance < 10 then
                    espData.distanceLabel.TextColor3 = Color3.new(0, 1, 0)
                elseif distance < 25 then
                    espData.distanceLabel.TextColor3 = Color3.new(1, 1, 0)
                else
                    espData.distanceLabel.TextColor3 = Color3.new(1, 1, 1)
                end
                
                if espData.progressValue then
                    local currentProgress = tonumber(espData.progressValue.Value) or 0
                    espData.progressLabel.Text = "Progress: " .. espData.progressValue.Value .. "%"
                    
                    if not espData.isFake and currentProgress ~= espData.currentProgress then
                        espData.currentProgress = currentProgress
                        
                        local highlight = generator:FindFirstChild("GeneratorHighlight")
                        if highlight then
                            if currentProgress >= 100 then

                                highlight.FillColor = Color3.new(0, 1, 0)
                                highlight.OutlineColor = Color3.new(0.2, 1, 0.2)
                                espData.nameLabel.TextColor3 = Color3.new(0, 1, 0)
                            else

                                highlight.FillColor = Color3.new(1, 1, 0)
                                highlight.OutlineColor = Color3.new(1, 1, 0.2)
                                espData.nameLabel.TextColor3 = Color3.new(1, 1, 0)
                            end
                        end
                    end
                end
            end
        end)
        

        ESP.Connections.childAdded = mapFolder.ChildAdded:Connect(function(child)
            wait(0.5)
            
            if ESP.LastCommand then
                if child.Name == "Generator" or child.Name:match("Generator%d") then
                    -- Если это новый Generator, переименовываем его
                    if child.Name == "Generator" then
                        local newName = "Generator1"
                        local count = 1
                        while mapFolder:FindFirstChild(newName) do
                            count = count + 1
                            newName = "Generator" .. count
                        end
                        if count <= 5 then
                            child.Name = newName
                        end
                    end
                    
                    wait(1)
                    _G.ESPGenerators(true)
                elseif child.Name == "FakeGenerator" then
                    wait(1)
                    _G.ESPGenerators(true)
                end
            end
        end)
        
        ESP.Connections.childRemoved = mapFolder.ChildRemoved:Connect(function(child)
            if ESP.LastCommand then
                if ESP.NameTags[child] then
                    if ESP.NameTags[child].billboard then
                        ESP.NameTags[child].billboard:Destroy()
                    end
                    ESP.NameTags[child] = nil
                    
                    wait(1)
                    _G.ESPGenerators(true)
                end
            end
        end)
        
        ESP.Enabled = true
        return true
        
    else
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
        return true
    end
end

spawn(function()
    while true do
        wait(5)
        if _G.GeneratorsESP then
            local ESP = _G.GeneratorsESP
            
            if ESP.LastCommand and not ESP.Enabled then
                _G.ESPGenerators(true)
            end
            

            if ESP.Enabled and ESP.NameTags then
                local needsRefresh = false
                local mapFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Ingame") and workspace.Map.Ingame:FindFirstChild("Map")
                
                if mapFolder then
                    for generator in pairs(ESP.NameTags) do
                        if not generator.Parent then
                            needsRefresh = true
                            break
                        end
                    end
                    
                    for i = 1, 5 do
                        local generatorName = "Generator" .. i
                        local generator = mapFolder:FindFirstChild(generatorName)
                        if generator and not ESP.NameTags[generator] then
                            needsRefresh = true
                            break
                        end
                    end
                    
                    local fakeGenerator = mapFolder:FindFirstChild("FakeGenerator")
                    if fakeGenerator and not ESP.NameTags[fakeGenerator] then
                        needsRefresh = true
                    end
                    
                    local baseGenerator = mapFolder:FindFirstChild("Generator")
                    if baseGenerator then
                        needsRefresh = true
                    end
                end
                
                if needsRefresh and ESP.LastCommand then
                    _G.ESPGenerators(true)
                end
            end
        end
    end
end)
