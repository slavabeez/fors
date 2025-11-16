local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

_G.ESPItems = function(enabled)
    if not _G.ItemsESP then
        _G.ItemsESP = {
            Enabled = false,
            Items = {},
            Highlights = {},
            Connections = {},
            LastCommand = false,
            NameTags = {}
        }
    end
    
    local ESP = _G.ItemsESP
    ESP.LastCommand = enabled
    
    if enabled then
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
            
            ESP.Items = {}
        end
        
        local mapFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Ingame") and workspace.Map.Ingame:FindFirstChild("Map")
        if not mapFolder then 
            return false 
        end
        
        local items = {}
        
        for _, medkit in pairs(mapFolder:GetChildren()) do
            if medkit.Name == "Medkit" then
                table.insert(items, {
                    Object = medkit,
                    Type = "Medkit",
                    Color = Color3.new(0.5, 0, 0.5),
                    DisplayName = "Medkit"
                })
            end
        end
        
        for _, bloxyCola in pairs(mapFolder:GetChildren()) do
            if bloxyCola.Name == "BloxyCola" then
                table.insert(items, {
                    Object = bloxyCola,
                    Type = "BloxyCola", 
                    Color = Color3.new(0.5, 0, 0.5),
                    DisplayName = "Bloxy Cola"
                })
            end
        end
        
        if #items == 0 then
            return false
        end
        
        ESP.Items = items
        
        local function createItemESP(itemData)
            local item = itemData.Object
            local rootPart = item:FindFirstChildWhichIsA("BasePart")
            if not rootPart then 
                return nil
            end
            
            local objectId = tostring(item):gsub(" ", "_")
            
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "ItemESP_" .. objectId
            billboard.Adornee = rootPart
            billboard.Size = UDim2.new(0, 250, 0, 40)
            billboard.StudsOffset = Vector3.new(0, 2.5, 0)
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
            nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = itemData.DisplayName
            nameLabel.TextColor3 = itemData.Color
            nameLabel.TextStrokeTransparency = 0.2
            nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
            nameLabel.TextSize = 16
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.Parent = billboard

            local distanceLabel = Instance.new("TextLabel")
            distanceLabel.Size = UDim2.new(1, 0, 0.4, 0)
            distanceLabel.Position = UDim2.new(0, 0, 0.6, 0)
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
                distanceLabel = distanceLabel,
                rootPart = rootPart,
                itemData = itemData,
                objectId = objectId
            }
            
            local highlight = Instance.new("Highlight")
            highlight.Name = "ItemHighlight_" .. objectId
            highlight.Adornee = item
            highlight.FillColor = Color3.new(0.5, 0, 0.5) -- Фиолетовый
            highlight.FillTransparency = 0.5
            highlight.OutlineColor = Color3.new(0.7, 0.2, 0.7) -- Фиолетовая обводка
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = item
            
            table.insert(ESP.Highlights, highlight)
            
            return espData
        end
        
        for _, itemData in pairs(items) do
            local espData = createItemESP(itemData)
            if espData then
                ESP.NameTags[itemData.Object] = espData
            end
        end

        ESP.Connections.update = RunService.Heartbeat:Connect(function()
            if not ESP.Enabled or not ESP.NameTags then return end
            
            local localPlayer = Players.LocalPlayer
            local localCharacter = localPlayer.Character
            local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
            
            if not localRoot then return end
            
            for item, espData in pairs(ESP.NameTags) do
                if not espData or not espData.distanceLabel or not espData.rootPart then
                    continue
                end
                
                if not item.Parent then
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
            end
        end)
        
        ESP.Connections.childAdded = mapFolder.ChildAdded:Connect(function(child)
            wait(0.5)
            
            if ESP.LastCommand then
                if child.Name == "Medkit" or child.Name == "BloxyCola" then
                    wait(1)
                    _G.ESPItems(true)
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
                    _G.ESPItems(true)
                end
            end
        end)
        
        for item, espData in pairs(ESP.NameTags) do
            ESP.Connections["ancestry_" .. espData.objectId] = item.AncestryChanged:Connect(function(_, parent)
                if parent == nil then
                    if ESP.NameTags[item] then
                        if ESP.NameTags[item].billboard then
                            ESP.NameTags[item].billboard:Destroy()
                        end
                        ESP.NameTags[item] = nil
                        
                        if ESP.LastCommand then
                            wait(1)
                            _G.ESPItems(true)
                        end
                    end
                end
            end)
        end
        
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
        
        ESP.Items = {}
        return true
    end
end

spawn(function()
    while true do
        wait(3)
        if _G.ItemsESP then
            local ESP = _G.ItemsESP
            
            if ESP.LastCommand and not ESP.Enabled then
                _G.ESPItems(true)
            end
            
            if ESP.Enabled then
                local needsRefresh = false
                local mapFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Ingame") and workspace.Map.Ingame:FindFirstChild("Map")
                
                if mapFolder then
                    for item in pairs(ESP.NameTags) do
                        if not item.Parent then
                            needsRefresh = true
                            break
                        end
                    end
                    
                    local currentMedkits = {}
                    local currentBloxyColas = {}
                    
                    for _, child in pairs(mapFolder:GetChildren()) do
                        if child.Name == "Medkit" then
                            table.insert(currentMedkits, child)
                        elseif child.Name == "BloxyCola" then
                            table.insert(currentBloxyColas, child)
                        end
                    end
                    
                    for _, medkit in pairs(currentMedkits) do
                        if not ESP.NameTags[medkit] then
                            needsRefresh = true
                            break
                        end
                    end
                    
                    for _, bloxyCola in pairs(currentBloxyColas) do
                        if not ESP.NameTags[bloxyCola] then
                            needsRefresh = true
                            break
                        end
                    end
                end
                
                if needsRefresh and ESP.LastCommand then
                    _G.ESPItems(true)
                end
            end
        end
    end
end)
