-- Animation Detector Module
local AnimationDetector = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

function AnimationDetector.Start(callback, radius)
    local localPlayer = Players.LocalPlayer
    local stopTracking = false
    local trackedAnimations = {}
    
    -- Функция для получения убийцы из папки Killers
    local function getKillerFromFolder()
        local killersFolder = Workspace.Players:FindFirstChild("Killers")
        if not killersFolder then return nil end
        
        local killers = killersFolder:GetChildren()
        if #killers > 0 then
            return killers[1] -- Берем первого убийцу
        end
        return nil
    end

    -- Функция для проверки, является ли анимация передвижением
    local function isMovementAnimation(animId, animator)
        -- Проверяем по длине анимации (анимации передвижения обычно длинные)
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                if track.Animation.AnimationId == animId and track.Length > 2 then
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
            
            -- Получаем убийцу из папки Killers
            local killerModel = getKillerFromFolder()
            if not killerModel then return end
            
            local actorsModule = require(game.ReplicatedStorage.Modules.Actors)
            
            -- Проверяем всех игроков
            for player, actor in pairs(actorsModule.CurrentActors) do
                if player ~= localPlayer and actor and actor.Rig then
                    local otherCharacter = actor.Rig
                    local distance = (character.PrimaryPart.Position - otherCharacter.PrimaryPart.Position).Magnitude
                    
                    -- Сравниваем риг игрока с ригом убийцы из папки Killers
                    if otherCharacter.Name == killerModel.Name and distance <= radius then
                        local humanoid = otherCharacter:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                            local animator = humanoid:FindFirstChildOfClass("Animator")
                            if animator then
                                for _, animTrack in ipairs(animator:GetPlayingAnimationTracks()) do
                                    if animTrack.IsPlaying then
                                        pcall(function()
                                            local animId = animTrack.Animation.AnimationId
                                            local animKey = player.Name .. "_" .. tostring(animId)
                                            
                                            if not trackedAnimations[animKey] then
                                                -- Пропускаем анимации передвижения
                                                if not isMovementAnimation(animId, animator) then
                                                    trackedAnimations[animKey] = true
                                                    
                                                    -- Вызываем callback для НЕ-передвиженческой анимации убийцы
                                                    pcall(callback, animTrack, player, otherCharacter, tostring(animId))
                                                    
                                                    -- Автоочистка через 2 секунды
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
    
    return stopFunction
end

-- Тихая версия без лишних выводов
function AnimationDetector.StartSilent(callback, radius)
    local localPlayer = Players.LocalPlayer
    local stopTracking = false
    local trackedAnimations = {}

    local function getKillerFromFolder()
        local killersFolder = Workspace.Players:FindFirstChild("Killers")
        if not killersFolder then return nil end
        local killers = killersFolder:GetChildren()
        return #killers > 0 and killers[1] or nil
    end

    local function isMovementAnimation(animId, animator)
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                if track.Animation.AnimationId == animId and track.Length > 2 then
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
            
            local killerModel = getKillerFromFolder()
            if not killerModel then return end
            
            local actorsModule = require(game.ReplicatedStorage.Modules.Actors)
            
            for player, actor in pairs(actorsModule.CurrentActors) do
                if player ~= localPlayer and actor and actor.Rig then
                    local otherCharacter = actor.Rig
                    local distance = (character.PrimaryPart.Position - otherCharacter.PrimaryPart.Position).Magnitude
                    
                    if otherCharacter.Name == killerModel.Name and distance <= radius then
                        local humanoid = otherCharacter:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                            local animator = humanoid:FindFirstChildOfClass("Animator")
                            if animator then
                                for _, animTrack in ipairs(animator:GetPlayingAnimationTracks()) do
                                    if animTrack.IsPlaying then
                                        pcall(function()
                                            local animId = animTrack.Animation.AnimationId
                                            local animKey = player.Name .. "_" .. tostring(animId)
                                            
                                            if not trackedAnimations[animKey] and not isMovementAnimation(animId, animator) then
                                                trackedAnimations[animKey] = true
                                                pcall(callback, animTrack, player, otherCharacter, tostring(animId))
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
    
    local heartbeatConnection = trackKillerAnimations()
    
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
