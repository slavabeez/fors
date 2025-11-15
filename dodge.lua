-- Animation Detector Module
local AnimationDetector = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

function AnimationDetector.Start(callback, radius)
    local localPlayer = Players.LocalPlayer
    local stopTracking = false
    
    -- Функция для копирования в буфер обмена
    local function copyToClipboard(text)
        pcall(function()
            setclipboard(tostring(text))
        end)
    end
    
    local function trackAnimations()
        local connection
        connection = RunService.Heartbeat:Connect(function()
            if stopTracking then return end
            
            local character = localPlayer.Character
            if not character or not character.PrimaryPart then return end
            
            local actorsModule = require(game.ReplicatedStorage.Modules.Actors)
            local detectedAnimations = {}
            
            for player, actor in pairs(actorsModule.CurrentActors) do
                if player ~= localPlayer and actor and actor.Rig then
                    local otherCharacter = actor.Rig
                    local distance = (character.PrimaryPart.Position - otherCharacter.PrimaryPart.Position).Magnitude
                    
                    if distance <= radius then
                        -- Проверяем текущие проигрываемые анимации через Animator
                        local humanoid = otherCharacter:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                            local animator = humanoid:FindFirstChildOfClass("Animator")
                            if animator then
                                for _, animTrack in ipairs(animator:GetPlayingAnimationTracks()) do
                                    if animTrack.IsPlaying then
                                        -- Проверяем анимации атаки по названию
                                        local animName = animTrack.Name:lower()
                                        if animName:find("attack") or 
                                           animName:find("slash") or 
                                           animName:find("punch") or
                                           animName:find("hit") or
                                           animName:find("execution") or
                                           animName:find("charge") or
                                           animName:find("demonic") or
                                           animName:find("blood") then
                                            
                                            -- Собираем информацию для отладки
                                            local animInfo = string.format("🎯 АНИМАЦИЯ: %s | Игрок: %s | Дистанция: %.1f", 
                                                animTrack.Name, player.Name, distance)
                                            table.insert(detectedAnimations, animInfo)
                                            
                                            -- Вызываем callback
                                            pcall(callback, animTrack, player, otherCharacter, animTrack.Name)
                                        end
                                    end
                                end
                            end
                        end
                        
                        -- Дополнительно проверяем Config.Animations на наличие анимаций атаки
                        if actor.Config and actor.Config.Animations then
                            for animName, animData in pairs(actor.Config.Animations) do
                                local lowerName = animName:lower()
                                if lowerName:find("attack") or 
                                   lowerName:find("slash") or 
                                   lowerName:find("punch") or
                                   lowerName:find("execution") or
                                   lowerName:find("demonic") or
                                   lowerName:find("blood") then
                                    
                                    local animInfo = string.format("⚡ CONFIG АНИМАЦИЯ: %s | Игрок: %s | Дистанция: %.1f", 
                                        animName, player.Name, distance)
                                    table.insert(detectedAnimations, animInfo)
                                end
                            end
                        end
                    end
                end
            end
            
            -- Если найдены анимации, копируем информацию в буфер обмена
            if #detectedAnimations > 0 then
                local debugText = "ОБНАРУЖЕНЫ АНИМАЦИИ АТАКИ:\n" .. table.concat(detectedAnimations, "\n")
                copyToClipboard(debugText)
                print(debugText)
            end
        end)
        return connection
    end
    
    local heartbeatConnection = trackAnimations()
    
    local function stopFunction()
        stopTracking = true
        if heartbeatConnection then
            heartbeatConnection:Disconnect()
        end
    end
    
    print("🎯 Отслеживание анимаций запущено! Радиус: " .. radius .. " studs")
    return stopFunction
end

-- Упрощенная версия для тестирования
function AnimationDetector.StartSimple(callback, radius)
    local localPlayer = Players.LocalPlayer
    local stopTracking = false
    
    local function trackAllAnimations()
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
                        -- Логируем ВСЕ анимации для отладки
                        local humanoid = otherCharacter:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                            local animator = humanoid:FindFirstChildOfClass("Animator")
                            if animator then
                                for _, animTrack in ipairs(animator:GetPlayingAnimationTracks()) do
                                    if animTrack.IsPlaying then
                                        -- Вызываем callback для ЛЮБОЙ анимации
                                        pcall(callback, animTrack, player, otherCharacter, animTrack.Name)
                                        
                                        -- Автоматически копируем информацию
                                        local debugText = string.format("АНИМАЦИЯ: %s | Игрок: %s | Дистанция: %.1f", 
                                            animTrack.Name, player.Name, distance)
                                        pcall(function() setclipboard(debugText) end)
                                        print("📋 Скопировано в буфер:", debugText)
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
    
    local heartbeatConnection = trackAllAnimations()
    
    local function stopFunction()
        stopTracking = true
        if heartbeatConnection then
            heartbeatConnection:Disconnect()
        end
    end
    
    return stopFunction
end

return AnimationDetector
