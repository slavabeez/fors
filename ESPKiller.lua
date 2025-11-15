local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local KillerESP = {
    Enabled = false,
    CurrentKiller = nil,
    Highlights = {},
    Connections = {},
    LastCommand = false -- Запоминаем последнюю команду
}

-- Основная функция для включения/выключения ESP
function ESPKiller(enabled)
    KillerESP.LastCommand = enabled -- Запоминаем команду
    
    if enabled then
        return KillerESP:Initialize()
    else
        KillerESP:Cleanup()
        return true
    end
end

function KillerESP:FindKiller()
    local killersFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers")
    if not killersFolder then 
        warn("Killers folder not found!")
        return nil 
    end
    
    -- Ищем первого подходящего ребенка (Model или BasePart)
    for _, child in pairs(killersFolder:GetChildren()) do
        if child:IsA("Model") or child:IsA("BasePart") then
            print("Found killer:", child.Name)
            return child
        end
    end
    
    warn("No killer models found in Killers folder!")
    return nil
end

function KillerESP:HighlightPart(part)
    local highlight = Instance.new("Highlight")
    highlight.Name = "KillerPartHighlight"
    highlight.Adornee = part
    highlight.FillColor = Color3.new(1, 0, 0) -- Красный
    highlight.FillTransparency = 0.7 -- Более прозрачный
    highlight.OutlineColor = Color3.new(1, 0.2, 0.2)
    highlight.OutlineTransparency = 0.1 -- Немного прозрачная обводка
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = part
    
    table.insert(self.Highlights, highlight)
    return highlight
end

function KillerESP:CreateNameTag(killer)
    local killerName = killer.Name
    -- Ищем голову для отслеживания
    local head = killer:FindFirstChild("Head")
    local humanoidRootPart = killer:FindFirstChild("HumanoidRootPart")
    local trackingPart = head or humanoidRootPart or killer:FindFirstChildWhichIsA("BasePart")
    
    if not trackingPart then 
        warn("No tracking part found for killer: " .. killerName)
        return nil 
    end
    
    -- Создаем BillboardGui с смещением выше головы
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "KillerESP_" .. killerName
    billboard.Adornee = trackingPart
    billboard.Size = UDim2.new(0, 250, 0, 70)
    
    -- Поднимаем выше, чтобы не перекрывало модель
    if head then
        billboard.StudsOffset = Vector3.new(0, 4.5, 0) -- Выше головы
    else
        billboard.StudsOffset = Vector3.new(0, 4, 0) -- Выше для других частей
    end
    
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 2000
    billboard.Parent = trackingPart
    
    -- Фон для лучшей читаемости (полупрозрачный)
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.new(0, 0, 0)
    background.BackgroundTransparency = 0.6 -- Прозрачный фон
    background.BorderSizePixel = 0
    background.Parent = billboard
    
    -- Заголовок с именем убийцы
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "🔪 " .. killerName .. " 🔪"
    nameLabel.TextColor3 = Color3.new(1, 0, 0)
    nameLabel.TextStrokeTransparency = 0.3 -- Прозрачная обводка текста
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.TextSize = 16
    nameLabel.Font = Enum.Font.GothamBlack
    nameLabel.Parent = billboard
    
    -- Метка расстояния
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = "Calculating..."
    distanceLabel.TextColor3 = Color3.new(1, 1, 1)
    distanceLabel.TextStrokeTransparency = 0.3
    distanceLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    distanceLabel.TextSize = 12
    distanceLabel.Font = Enum.Font.GothamBold
    distanceLabel.Parent = billboard
    
    print("Created name tag for killer: " .. killerName)
    
    return {
        billboard = billboard,
        nameLabel = nameLabel,
        distanceLabel = distanceLabel,
        trackingPart = trackingPart
    }
end

function KillerESP:HighlightAllParts(model)
    local partsHighlighted = 0
    
    local function findAndHighlight(object)
        if object:IsA("BasePart") then
            self:HighlightPart(object)
            partsHighlighted = partsHighlighted + 1
        end
        
        for _, child in pairs(object:GetChildren()) do
            findAndHighlight(child)
        end
    end
    
    findAndHighlight(model)
    print("Highlighted " .. partsHighlighted .. " parts for " .. model.Name)
    return partsHighlighted
end

function KillerESP:UpdateDistance()
    if not self.NameTag or not self.NameTag.distanceLabel then return end
    if not self.Enabled then return end
    
    local localPlayer = Players.LocalPlayer
    local localCharacter = localPlayer.Character
    local localHead = localCharacter and localCharacter:FindFirstChild("Head")
    
    if not localHead or not self.CurrentKiller then return end
    
    local killerHead = self.CurrentKiller:FindFirstChild("Head")
    local killerTrackingPart = self.NameTag.trackingPart
    
    if not killerTrackingPart then return end
    
    local distance = (localHead.Position - killerTrackingPart.Position).Magnitude
    self.NameTag.distanceLabel.Text = "Distance: " .. math.floor(distance) .. "m"
    
    -- Меняем цвет в зависимости от расстояния
    if distance < 15 then
        self.NameTag.distanceLabel.TextColor3 = Color3.new(1, 0, 0) -- Близко (красный)
        self.NameTag.nameLabel.Text = "⚠️ " .. self.CurrentKiller.Name .. " ⚠️"
    elseif distance < 30 then
        self.NameTag.distanceLabel.TextColor3 = Color3.new(1, 1, 0) -- Средне (желтый)
        self.NameTag.nameLabel.Text = "🔪 " .. self.CurrentKiller.Name .. " 🔪"
    else
        self.NameTag.distanceLabel.TextColor3 = Color3.new(0, 1, 0) -- Далеко (зеленый)
        self.NameTag.nameLabel.Text = "🔪 " .. self.CurrentKiller.Name .. " 🔪"
    end
end

function KillerESP:Initialize()
    if self.Enabled then
        self:Cleanup() -- Очищаем перед повторной инициализацией
    end
    
    -- Ищем убийцу
    self.CurrentKiller = self:FindKiller()
    
    if not self.CurrentKiller then
        print("No killer found, but ESP is enabled. Will retry...")
        return false
    end
    
    -- Создаем тег с именем убийцы
    self.NameTag = self:CreateNameTag(self.CurrentKiller)
    
    if not self.NameTag then
        warn("Failed to create name tag for killer!")
        return false
    end
    
    -- Подсвечиваем все части
    local partsCount = self:HighlightAllParts(self.CurrentKiller)
    
    -- Запускаем обновление расстояния
    self.Connections.distanceUpdate = RunService.Heartbeat:Connect(function()
        self:UpdateDistance()
    end)
    
    -- Отслеживаем удаление убийцы
    self.Connections.killerRemoved = self.CurrentKiller.AncestryChanged:Connect(function()
        if not self.CurrentKiller or not self.CurrentKiller.Parent then
            print("Killer was removed, will auto-find new one...")
            self:ScheduleReinitialize()
        end
    end)
    
    self.Enabled = true
    print("ESP successfully activated for: " .. self.CurrentKiller.Name)
    return true
end

function KillerESP:ScheduleReinitialize()
    -- Планируем переинициализацию через 1 секунду
    if self.Connections.reinitialize then
        self.Connections.reinitialize:Disconnect()
    end
    
    self.Connections.reinitialize = RunService.Heartbeat:Connect(function()
        wait(1) -- Ждем 1 секунду
        self.Connections.reinitialize:Disconnect()
        
        if self.LastCommand then -- Переинициализируем только если ESP было включено
            print("Auto-reinitializing ESP...")
            self:Initialize()
        end
    end)
end

function KillerESP:Cleanup()
    self.Enabled = false
    
    -- Отключаем все соединения
    for name, connection in pairs(self.Connections) do
        if connection then
            connection:Disconnect()
        end
    end
    self.Connections = {}
    
    -- Удаляем все подсветки
    for _, highlight in pairs(self.Highlights) do
        if highlight then
            highlight:Destroy()
        end
    end
    self.Highlights = {}
    
    -- Удаляем тег с именем
    if self.NameTag and self.NameTag.billboard then
        self.NameTag.billboard:Destroy()
        self.NameTag = nil
    end
    
    self.CurrentKiller = nil
    print("ESP cleaned up")
end

-- Автоматическая проверка появления убийцы
local function startAutoRefresh()
    while true do
        wait(3) -- Проверяем каждые 3 секунды
        
        -- Если ESP было включено командой, но сейчас нет убийцы - ищем снова
        if KillerESP.LastCommand and not KillerESP.Enabled then
            print("ESP is enabled but no killer found. Searching...")
            KillerESP:Initialize()
        end
        
        -- Если ESP включено и убийца есть, но пропал - переинициализируем
        if KillerESP.Enabled and KillerESP.CurrentKiller and not KillerESP.CurrentKiller.Parent then
            print("Killer lost, reinitializing...")
            KillerESP:ScheduleReinitialize()
        end
    end
end

-- Запускаем авто-обновление в фоне
spawn(startAutoRefresh)

-- Экспортируем основную функцию
return ESPKiller
