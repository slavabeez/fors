-- Animation Detector Module
local AnimationDetector = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

function AnimationDetector.Start(callback, radius)
    local localPlayer = Players.LocalPlayer
    local character = localPlayer.Character
    local stopTracking = false
    
    -- Настройки
    local TRACKING_RADIUS = radius or 5
    local CHECK_INTERVAL = 0.05
    
    -- Таблица для отслеживания анимаций
    local trackedAnimations = {}
    
    -- Функция для проверки расстояния
    local function isInRange(position, targetRadius)
        if not character or not character.PrimaryPart then
            return false
        end
        local distance = (character.PrimaryPart.Position - position).Magnitude
        return distance <= targetRadius
    end
    
    -- Функция для поиска анимаций через загрузку анимаций
    local function findAttackAnimations()
        local attackAnimations = {}
        
        for _, player in ipairs(Players:GetPlayers()) do
            -- Пропускаем локального игрока
            if player ~= localPlayer then
                local otherCharacter = player.Character
                
                if otherCharacter and otherCharacter.PrimaryPart then
                    -- Получаем актора игрока
                    local actorsModule = require(game.ReplicatedStorage.Modules.Actors)
                    local actor = actorsModule.CurrentActors[player]
                    
                    if actor and actor.Rig then
                        -- Проверяем кэш анимаций актора
                        for animName, animTrack in pairs(actor.Cache or {}) do
                            if typeof(animTrack) == "userdata" and animTrack.IsPlaying then
                                -- Ищем анимации атаки по названию
                                if animName:lower():find("attack") or 
                                   animName:lower():find("swing") or 
                                   animName:lower():find("execution") or
                                   animName:lower():find("kill") then
                                    
                                    table.insert(attackAnimations, {
                                        Player = player,
                                        Character = otherCharacter,
                                        Animation = animTrack,
                                        Position = otherCharacter.PrimaryPart.Position,
                                        AnimationName = animName,
                                        Actor = actor,
                                        Timestamp = tick()
                                    })
                                end
                            end
                        end
                        
                        -- Проверяем текущие проигрываемые анимации
                        local humanoid = actor.Rig:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                            local animator = humanoid:FindFirstChildOfClass("Animator")
                            if animator then
                                for _, animTrack in ipairs(animator:GetPlayingAnimationTracks()) do
                                    if animTrack.IsPlaying and (
                                        animTrack.Name:lower():find("attack") or
                                        animTrack.Name:lower():find("swing") or
                                        animTrack.Name:lower():find("hit")
                                    ) then
                                        table.insert(attackAnimations, {
                                            Player = player,
                                            Character = otherCharacter,
                                            Animation = animTrack,
                                            Position = otherCharacter.PrimaryPart.Position,
                                            AnimationName = animTrack.Name,
                                            Actor = actor,
                                            Timestamp = tick()
                                        })
                                    end
                                end
                            end
                        end
                    end
                    
                    -- Дополнительная проверка через создание хитбоксов (признак атаки)
                    local hitboxesFolder = Workspace:FindFirstChild("Hitboxes")
                    if hitboxesFolder then
                        for _, hitbox in ipairs(hitboxesFolder:GetChildren()) do
                            if hitbox:IsA("BasePart") and hitbox.Name:find(player.Name) then
                                -- Если у игрока есть активный хитбокс - он атакует
                                table.insert(attackAnimations, {
                                    Player = player,
                                    Character = otherCharacter,
                                    Animation = nil, -- Нет конкретной анимации, но есть хитбокс
                                    Position = otherCharacter.PrimaryPart.Position,
                                    AnimationName = "HitboxAttack",
                                    Actor = nil,
                                    Timestamp = tick(),
                                    HasHitbox = true
                                })
                                break
                            end
                        end
                    end
                end
            end
        end
        
        return attackAnimations
    end
    
    -- Основная функция отслеживания
    local function trackAnimations()
        local connection
        connection = RunService.Heartbeat:Connect(function()
            if stopTracking then
                connection:Disconnect()
                return
            end
            
            -- Обновляем ссылку на персонажа
            character = localPlayer.Character
            if not character or not character.PrimaryPart then
                return
            end
            
            -- Ищем анимации атаки
            local attackAnims = findAttackAnimations()
            
            for _, animData in ipairs(attackAnims) do
                local animId = animData.Player.Name .. "_" .. animData.AnimationName .. "_" .. tostring(math.floor(animData.Timestamp))
                
                -- Если анимация в радиусе и мы ее еще не отслеживали
                if isInRange(animData.Position, TRACKING_RADIUS) and not trackedAnimations[animId] then
                    -- Вызываем callback с информацией об анимации
                    pcall(callback, animData.Animation, animData.Player, animData.Character, animData.AnimationName)
                    
                    -- Помечаем как отслеженную
                    trackedAnimations[animId] = true
                    
                    -- Логирование для отладки
                    print("🎯 Обнаружена анимация атаки:", animData.AnimationName)
                    print("👤 Игрок:", animData.Player.Name)
                    print("📍 Расстояние:", (character.PrimaryPart.Position - animData.Position).Magnitude)
                    print("⏰ Время:", animData.Timestamp)
                    
                    -- Автоматическая очистка через 1 секунду
                    task.delay(1, function()
                        trackedAnimations[animId] = nil
                    end)
                end
            end
            
            -- Очистка старых записей (старше 3 секунд)
            local currentTime = tick()
            for animId, timestamp in pairs(trackedAnimations) do
                if currentTime - timestamp > 3 then
                    trackedAnimations[animId] = nil
                end
            end
        end)
        
        return connection
    end
    
    -- Обработчик изменения персонажа
    local characterConnection
    characterConnection = localPlayer.CharacterAdded:Connect(function(newCharacter)
        character = newCharacter
        print("🔁 Персонаж изменен, возобновление отслеживания...")
    end)
    
    -- Запускаем отслеживание
    local heartbeatConnection = trackAnimations()
    
    -- Функция для остановки
    local function stopFunction()
        stopTracking = true
        if heartbeatConnection then
            heartbeatConnection:Disconnect()
        end
        if characterConnection then
            characterConnection:Disconnect()
        end
        trackedAnimations = {}
        print("🛑 Отслеживание анимаций остановлено")
    end
    
    print("🎯 Отслеживание анимаций атаки запущено! Радиус: " .. TRACKING_RADIUS .. " studs")
    return stopFunction
end

-- Улучшенная версия с мониторингом Execution анимаций
function AnimationDetector.StartExecutionTracking(callback, radius)
    local localPlayer = Players.LocalPlayer
    local character = localPlayer.Character
    local stopTracking = false
    
    local TRACKING_RADIUS = radius or 5
    
    -- Отслеживаем конкретно Execution анимации
    local function monitorExecutions()
        local connection
        connection = RunService.Heartbeat:Connect(function()
            if stopTracking then
                connection:Disconnect()
                return
            end
            
            character = localPlayer.Character
            if not character or not character.PrimaryPart then
                return
            end
            
            -- Ищем игроков с Execution анимациями
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= localPlayer then
                    local otherCharacter = player.Character
                    if otherCharacter and otherCharacter.PrimaryPart then
                        local distance = (character.PrimaryPart.Position - otherCharacter.PrimaryPart.Position).Magnitude
                        
                        if distance <= TRACKING_RADIUS then
                            -- Проверяем Execution статус через атрибуты
                            if otherCharacter:GetAttribute("Executing") then
                                pcall(callback, nil, player, otherCharacter, "Execution")
                                print("⚡ Обнаружена Execution анимация рядом!")
                            end
                            
                            -- Проверяем через анимации в кэше
                            local actorsModule = require(game.ReplicatedStorage.Modules.Actors)
                            local actor = actorsModule.CurrentActors[player]
                            
                            if actor and actor.Cache then
                                for animName, animTrack in pairs(actor.Cache) do
                                    if animName:lower():find("execution") and typeof(animTrack) == "userdata" and animTrack.IsPlaying then
                                        pcall(callback, animTrack, player, otherCharacter, "Execution")
                                        print("⚡ Обнаружена Execution анимация в кэше!")
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
        
        return connection
    end
    
    local heartbeatConnection = monitorExecutions()
    local characterConnection = localPlayer.CharacterAdded:Connect(function(newCharacter)
        character = newCharacter
    end)
    
    local function stopFunction()
        stopTracking = true
        if heartbeatConnection then
            heartbeatConnection:Disconnect()
        end
        if characterConnection then
            characterConnection:Disconnect()
        end
    end
    
    print("🎯 Отслеживание Execution анимаций запущено! Радиус: " .. TRACKING_RADIUS .. " studs")
    return stopFunction
end

return AnimationDetector
