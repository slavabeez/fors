-- Animation Detector Module
local AnimationDetector = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

function AnimationDetector.Start(callback, radius)
    local localPlayer = Players.LocalPlayer
    local stopTracking = false
    
    -- Таблица для отслеживания анимаций
    local trackedAnimations = {}
    
    -- Таблица для хранения предыдущих состояний анимаций
    local previousAnimationStates = {}
    
    -- Список анимаций передвижения, которые нужно игнорировать
    local MOVEMENT_ANIMATIONS = {
        "Walk", "Run", "Idle", "InjuredWalk", "InjuredRun", "InjuredIdle"
    }
    
    local function isMovementAnimation(animName)
        for _, movementAnim in ipairs(MOVEMENT_ANIMATIONS) do
            if animName:find(movementAnim) then
                return true
            end
        end
        return false
    end
    
    local function trackKillerAnimations()
        local connection
        connection = RunService.Heartbeat:Connect(function()
            if stopTracking then return end
            
            local character = localPlayer.Character
            if not character or not character.PrimaryPart then return end
            
            local actorsModule = require(game.ReplicatedStorage.Modules.Actors)
            
            for player, actor in pairs(actorsModule.CurrentActors) do
                if player ~= localPlayer and actor and actor.Rig then
                    local otherCharacter = actor.Rig
                    local distance = (character.PrimaryPart.Position - otherCharacter.PrimaryPart.Position).Magnitude
                    
                    if distance <= radius then
                        local humanoid = otherCharacter:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                            local animator = humanoid:FindFirstChildOfClass("Animator")
                            if animator then
                                local currentAnimations = {}
                                
                                -- Собираем текущие анимации
                                for _, animTrack in ipairs(animator:GetPlayingAnimationTracks()) do
                                    if animTrack.IsPlaying then
                                        currentAnimations[animTrack.Name] = {
                                            Track = animTrack,
                                            Player = player,
                                            Character = otherCharacter,
                                            Distance = distance
                                        }
                                    end
                                end
                                
                                -- Проверяем новые анимации
                                for animName, animData in pairs(currentAnimations) do
                                    local animId = player.Name .. "_" .. animName
                                    
                                    -- Если это новая анимация (не была в предыдущем состоянии)
                                    if not previousAnimationStates[animId] and not isMovementAnimation(animName) then
                                        -- Игнорируем анимации передвижения
                                        if not trackedAnimations[animId] then
                                            trackedAnimations[animId] = true
                                            
                                            -- Вызываем callback для НЕ-передвиженческой анимации
                                            pcall(callback, animData.Track, player, otherCharacter, animName)
                                            
                                            print("🎯 Обнаружена анимация убийцы:", animName)
                                            print("👤 Убийца:", player.Name)
                                            print("📍 Дистанция:", string.format("%.1f", distance))
                                            
                                            -- Автоочистка через 3 секунды
                                            task.delay(3, function()
                                                trackedAnimations[animId] = nil
                                            end)
                                        end
                                    end
                                end
                                
                                -- Обновляем предыдущее состояние
                                previousAnimationStates = currentAnimations
                            end
                        end
                    end
                end
            end
        end)
        return connection
    end
    
    local heartbeatConnection = trackKillerAnimations()
    
    local function stopFunction()
        stopTracking = true
        if heartbeatConnection then
            heartbeatConnection:Disconnect()
        end
        trackedAnimations = {}
        previousAnimationStates = {}
    end
    
    print("🎯 Отслеживание анимаций убийцы запущено! Радиус: " .. radius .. " studs")
    return stopFunction
end

-- Альтернативная версия с анализом скорости анимации
function AnimationDetector.StartAdvanced(callback, radius)
    local localPlayer = Players.LocalPlayer
    local stopTracking = false
    
    local trackedAnimations = {}
    local animationStartTimes = {}
    
    local function trackAllNonMovementAnimations()
        local connection
        connection = RunService.Heartbeat:Connect(function()
            if stopTracking then return end
            
            local character = localPlayer.Character
            if not character or not character.PrimaryPart then return end
            
            local actorsModule = require(game.ReplicatedStorage.Modules.Actors)
            
            for player, actor in pairs(actorsModule.CurrentActors) do
                if player ~= localPlayer and actor and actor.Rig then
                    local otherCharacter = actor.Rig
                    local distance = (character.PrimaryPart.Position - otherCharacter.PrimaryPart.Position).Magnitude
                    
                    if distance <= radius then
                        local humanoid = otherCharacter:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                            local animator = humanoid:FindFirstChildOfClass("Animator")
                            if animator then
                                for _, animTrack in ipairs(animator:GetPlayingAnimationTracks()) do
                                    if animTrack.IsPlaying then
                                        local animName = animTrack.Name
                                        local animId = player.Name .. "_" .. animName
                                        
                                        -- Пропускаем анимации передвижения по ключевым словам
                                        if not (animName:find("Walk") or 
                                               animName:find("Run") or 
                                               animName:find("Idle") or
                                               animName:find("Movement") or
                                               animName:lower():find("move")) then
                                            
                                            -- Проверяем, новая ли это анимация
                                            if not animationStartTimes[animId] then
                                                animationStartTimes[animId] = tick()
                                                
                                                -- Небольшая задержка чтобы убедиться что это не анимация передвижения
                                                task.delay(0.1, function()
                                                    if animTrack.IsPlaying and not trackedAnimations[animId] then
                                                        trackedAnimations[animId] = true
                                                        
                                                        -- Вызываем callback
                                                        pcall(callback, animTrack, player, otherCharacter, animName)
                                                        
                                                        print("🎯 Обнаружена не-передвиженческая анимация:", animName)
                                                        print("👤 Убийца:", player.Name)
                                                    end
                                                end)
                                            end
                                        end
                                    else
                                        -- Сбрасываем таймер если анимация остановилась
                                        local animId = player.Name .. "_" .. animTrack.Name
                                        animationStartTimes[animId] = nil
                                        trackedAnimations[animId] = nil
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
    
    local heartbeatConnection = trackAllNonMovementAnimations()
    
    local function stopFunction()
        stopTracking = true
        if heartbeatConnection then
            heartbeatConnection:Disconnect()
        end
        trackedAnimations = {}
        animationStartTimes = {}
    end
    
    return stopFunction
end

return AnimationDetector
