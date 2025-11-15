-- Animation Detector Module - ИСПРАВЛЕННЫЙ
local AnimationDetector = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

function AnimationDetector.Start(callback, radius)
    local localPlayer = Players.LocalPlayer
    local stopTracking = false
    local trackedAnimations = {}
    
    -- Таблица для сопоставления AnimationId с названиями анимаций
    local animationIdToName = {}
    
    -- Функция для определения убийцы
    local function isKiller(actor)
        if not actor or not actor.Config then return false end
        
        -- Проверяем по Class или наличию анимаций атаки
        if actor.Config.Class and actor.Config.Class:lower():find("killer") then
            return true
        end
        
        -- Проверяем по наличию анимаций атаки в Config
        if actor.Config.Animations then
            for animName, animData in pairs(actor.Config.Animations) do
                if animName:find("Slash") or animName:find("Attack") or animName:find("Execution") then
                    return true
                end
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
                if player ~= localPlayer and isKiller(actor) and actor.Rig then
                    local otherCharacter = actor.Rig
                    local distance = (character.PrimaryPart.Position - otherCharacter.PrimaryPart.Position).Magnitude
                    
                    if distance <= radius then
                        -- СПОСОБ 1: Отслеживаем через Animator по реальным AnimationId
                        local humanoid = otherCharacter:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                            local animator = humanoid:FindFirstChildOfClass("Animator")
                            if animator then
                                for _, animTrack in ipairs(animator:GetPlayingAnimationTracks()) do
                                    if animTrack.IsPlaying then
                                        pcall(function()
                                            local animId = tostring(animTrack.Animation.AnimationId)
                                            local animName = animationIdToName[animId] or animId
                                            local animKey = player.Name .. "_" .. animId
                                            
                                            if not trackedAnimations[animKey] then
                                                trackedAnimations[animKey] = true
                                                
                                                -- Определяем тип анимации по ID или названию
                                                local isAttackAnimation = false
                                                
                                                -- Проверяем по ID (можно добавить известные ID атак)
                                                if animId:find("132653655520682") or  -- Пример ID атаки
                                                   animId:find("115946474977409") or  -- Пример ID атаки  
                                                   animId:find("108018357044094") then -- Пример ID атаки
                                                    isAttackAnimation = true
                                                end
                                                
                                                -- Проверяем по названию из кэша
                                                if actor.Cache then
                                                    for cachedName, cachedTrack in pairs(actor.Cache) do
                                                        if cachedTrack == animTrack then
                                                            animName = cachedName
                                                            if cachedName:find("Slash") or 
                                                               cachedName:find("Attack") or 
                                                               cachedName:find("Execution") or
                                                               cachedName:find("Punch") then
                                                                isAttackAnimation = true
                                                            end
                                                            animationIdToName[animId] = cachedName
                                                            break
                                                        end
                                                    end
                                                end
                                                
                                                -- Если это анимация атаки, вызываем callback
                                                if isAttackAnimation then
                                                    pcall(callback, animTrack, player, otherCharacter, animName)
                                                    
                                                    print("🎯 Анимация убийцы обнаружена!")
                                                    print("👤 Убийца:", player.Name)
                                                    print("🎭 Анимация:", animName)
                                                    print("🆔 ID:", animId)
                                                    print("📍 Дистанция:", string.format("%.1f", distance))
                                                    
                                                    task.delay(2, function()
                                                        trackedAnimations[animKey] = nil
                                                    end)
                                                end
                                            end
                                        end)
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
    
    local heartbeatConnection = trackKillerAnimations()
    
    local function stopFunction()
        stopTracking = true
        if heartbeatConnection then
            heartbeatConnection:Disconnect()
        end
        trackedAnimations = {}
    end
    
    print("🎯 Отслеживание анимаций убийцы запущено! Радиус: " .. radius .. " studs")
    return stopFunction
end

-- Упрощенная версия - отслеживает ВСЕ анимации убийцы
function AnimationDetector.StartSimple(callback, radius)
    local localPlayer = Players.LocalPlayer
    local stopTracking = false
    local trackedAnimations = {}

    local function trackAllKillerAnimations()
        local connection
        connection = RunService.Heartbeat:Connect(function()
            if stopTracking then return end
            
            local character = localPlayer.Character
            if not character or not character.PrimaryPart then return end
            
            local actorsModule = require(game.ReplicatedStorage.Modules.Actors)
            
            for player, actor in pairs(actorsModule.CurrentActors) do
                -- Простая проверка: если не локальный игрок и есть риг - считаем убийцей
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
                                        pcall(function()
                                            local animId = tostring(animTrack.Animation.AnimationId)
                                            local animKey = player.Name .. "_" .. animId
                                            
                                            if not trackedAnimations[animKey] then
                                                trackedAnimations[animKey] = true
                                                
                                                -- Вызываем callback для ЛЮБОЙ анимации убийцы
                                                pcall(callback, animTrack, player, otherCharacter, animId)
                                                
                                                print("⚡ Анимация убийцы! ID:", animId)
                                                print("👤 Убийца:", player.Name)
                                                
                                                task.delay(1.5, function()
                                                    trackedAnimations[animKey] = nil
                                                end)
                                            end
                                        end)
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
    
    local heartbeatConnection = trackAllKillerAnimations()
    
    local function stopFunction()
        stopTracking = true
        if heartbeatConnection then
            heartbeatConnection:Disconnect()
        end
        trackedAnimations = {}
    end
    
    return stopFunction
end

return AnimationDetector
