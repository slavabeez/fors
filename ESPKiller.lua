print("e")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local KillerESP = {
    Enabled = true,
    CurrentKiller = nil,
    Highlights = {},
    Connection = nil
}

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
    highlight.FillTransparency = 0.4
    highlight.OutlineColor = Color3.new(1, 0.2, 0.2)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = part
    
    table.insert(self.Highlights, highlight)
    return highlight
end

function KillerESP:CreateNameTag(killer)
    -- Используем имя убийцы (название модели)
    local killerName = killer.Name
    local rootPart = killer:FindFirstChild("HumanoidRootPart") or 
                     killer:FindFirstChild("Head") or 
                     killer:FindFirstChildWhichIsA("BasePart")
    
    if not rootPart then 
        warn("No root part found for killer: " .. killerName)
        return nil 
    end
    
    -- Создаем BillboardGui
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "KillerESP_" .. killerName
    billboard.Adornee = rootPart
    billboard.Size = UDim2.new(0, 300, 0, 80)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 2000
    billboard.Parent = rootPart
    
    -- Заголовок с именем убийцы
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "🔪 " .. killerName .. " 🔪" -- Показываем имя модели
    nameLabel.TextColor3 = Color3.new(1, 0, 0)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.TextSize = 18
    nameLabel.Font = Enum.Font.GothamBlack
    nameLabel.Parent = billboard
    
    -- Метка расстояния
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = "Calculating distance..."
    distanceLabel.TextColor3 = Color3.new(1, 1, 1)
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    distanceLabel.TextSize = 14
    distanceLabel.Font = Enum.Font.GothamBold
    distanceLabel.Parent = billboard
    
    print("Created name tag for killer: " .. killerName)
    
    return {
        billboard = billboard,
        nameLabel = nameLabel,
        distanceLabel = distanceLabel,
        rootPart = rootPart
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
    local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
    
    if not localRoot or not self.CurrentKiller then return end
    
    local killerRoot = self.NameTag.rootPart
    if not killerRoot then return end
    
    local distance = (localRoot.Position - killerRoot.Position).Magnitude
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
    -- Очищаем старые подсветки
    self:Cleanup()
    
    -- Ищем убийцу
    self.CurrentKiller = self:FindKiller()
    
    if not self.CurrentKiller then
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
    self.Connection = RunService.Heartbeat:Connect(function()
        self:UpdateDistance()
    end)
    
    print("ESP successfully activated for: " .. self.CurrentKiller.Name)
    return true
end

function KillerESP:Toggle(enabled)
    self.Enabled = enabled
    
    -- Включаем/выключаем все подсветки
    for _, highlight in pairs(self.Highlights) do
        highlight.Enabled = enabled
    end
    
    if self.NameTag and self.NameTag.billboard then
        self.NameTag.billboard.Enabled = enabled
    end
end

function KillerESP:Cleanup()
    -- Отключаем соединение
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
    
    -- Удаляем все подсветки
    for _, highlight in pairs(self.Highlights) do
        highlight:Destroy()
    end
    self.Highlights = {}
    
    -- Удаляем тег с именем
    if self.NameTag and self.NameTag.billboard then
        self.NameTag.billboard:Destroy()
        self.NameTag = nil
    end
    
    self.CurrentKiller = nil
end

function KillerESP:Restart()
    self:Cleanup()
    wait(0.5)
    return self:Initialize()
end

-- Автоматическая проверка появления/исчезновения убийцы
local function startAutoRefresh()
    while true do
        wait(3) -- Проверяем каждые 3 секунды
        
        local currentKillerExists = KillerESP.CurrentKiller and KillerESP.CurrentKiller.Parent
        local killersFolderExists = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers")
        
        if not currentKillerExists and killersFolderExists then
            -- Убийца исчез или был удален
            print("Killer disappeared, searching for new one...")
            KillerESP:Restart()
        elseif not killersFolderExists then
            -- Папка убийц исчезла
            KillerESP:Cleanup()
        end
    end
end

-- Основная инициализация
wait(2) -- Ждем загрузки игры

if KillerESP:Initialize() then
    print("Killer ESP started successfully!")
    spawn(startAutoRefresh)
else
    warn("Failed to initialize Killer ESP. Will retry automatically...")
    spawn(startAutoRefresh)
end

return KillerESP
