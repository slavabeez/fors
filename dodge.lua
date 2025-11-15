-- Animation Detector Module
local AnimationDetector = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

function AnimationDetector.Start(callback, radius)
    local localPlayer = Players.LocalPlayer
    local stopTracking = false
    
    -- Таблица для отслеживания уже обработанных анимаций
    local trackedAnimations = {}
    
    -- Список анимаций атаки убийцы (из твоей диагностики)
    local KILLER_ATTACK_ANIMATIONS = {
        "Slash", "DemonicPursuit", "BloodHunt", "Execution", "Charge", "Punch"
    }
    
    local function trackKillerAnimations()
        local connection
        connection = RunService.Heartbeat:Connect(function()
            if stopTracking then return end
            
            local character = localPlayer.Character
            if not character or not character.PrimaryPart then return end
            
            local actorsModule = require(game.ReplicatedStorage.Modules.Actors)
            
            for player, actor in pairs(actorsModule.CurrentActors) do
                -- Проверяем только убийц (исключаем локального игрока)
                if player ~= localPlayer and actor and actor.Rig then
                    local otherCharacter = actor.Rig
                    local distance = (character.PrimaryPart.Position - otherCharacter.PrimaryPart.Position).Magnitude
                    
                    -- Проверяем только если в радиусе
                    if distance <= radius then
                        -- Проверяем проигрываемые анимации
                        local humanoid = otherCharacter:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                            local animator = humanoid:FindFirstChildOfClass("Animator")
                            if animator then
                                for _, animTrack in ipairs(animator:GetPlayingAnimationTracks()) do
                                    if animTrack.IsPlaying then
                                        local animName = animTrack.Name
                                        
                                        -- Проверяем, является ли анимация атакой убийцы
                                        local isAttackAnimation = false
                                        for _, attackAnim in ipairs(KILLER_ATTACK_ANIMATIONS) do
                                            if animName:find(attackAnim) then
                                                isAttackAnimation = true
                                                break
                                            end
                                        end
                                        
                                        -- Дополнительные проверки по названию
                                        if not isAttackAnimation then
                                            local lowerName = animName:lower()
                                            if lowerName:find("attack") or 
                                               lowerName:find("slash") or 
                                               lowerName:find("hit") or
                                               lowerName:find("punch") or
                                               lowerName:find("charge") or
                                               lowerName:find("execution") then
                                                isAttackAnimation = true
                                            end
                                        end
                                        
                                        -- Если это анимация атаки и мы ее еще не обрабатывали
                                        if isAttackAnimation then
                                            local animId = player.Name .. "_" .. animName
                                            
                                            if not trackedAnimations[animId] then
                                                trackedAnimations[animId] = true
                                                
                                                -- Вызываем callback
                                                pcall(callback, animTrack, player, otherCharacter, animName)
                                                
                                                -- Логируем для отладки (без копирования в буфер)
                                                print("🎯 Обнаружена анимация убийцы:", animName)
                                                print("👤 Убийца:", player.Name)
                                                print("📍 Дистанция:", string.format("%.1f", distance))
                                                
                                                -- Автоочистка через 2 секунды
                                                task.delay(2, function()
                                                    trackedAnimations[animId] = nil
                                                end)
                                            end
                                        end
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

return AnimationDetector
