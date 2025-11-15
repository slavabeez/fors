-- Animation Detector Module
local AnimationDetector = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

function AnimationDetector.Start(callback, radius)
    local localPlayer = Players.LocalPlayer
    local stopTracking = false
    local trackedAnimations = {}
    
    -- Ключевые слова анимаций передвижения для исключения
    local movementKeywords = {
        "Walk", "Run", "Idle", "Injured", "Better", "Movement", "Move"
    }
    
    -- Функция для проверки, является ли анимация передвижением
    local function isMovementAnimation(animationId, animator)
        -- Проверяем по длине анимации (анимации передвижения обычно длинные и зациклены)
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                if track.Animation.AnimationId == animationId then
                    -- Анимации передвижения обычно длиннее 2 секунд
                    if track.Length > 2 then
                        return true
                    end
                end
            end
        end
        return false
    end
    
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

    local function trackKillerAnimations()
        local connection
        connection = RunService.Heartbeat:Connect(function()
            if stopTracking then return end
            
            local character = localPlayer.Character
            if not character or not character.PrimaryPart then return end
            
            -- Получаем убийцу из папки Killers
            local killerModel = getKillerFromFolder()
            if not killerModel then
                -- print("❌ Убийца не найден в папке Killers")
                return
            end
            
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
                                                    
                                                    print("🎯 ОБНАРУЖЕНА АНИМАЦИЯ УБИЙЦЫ!")
                                                    print("👤 Убийца:", player.Name)
                                                    print("🎭 Риг:", otherCharacter.Name)
                                                    print("🆔 ID анимации:", animId)
                                                    print("📍 Дистанция:", string.format("%.1f", distance))
                                                    print("✅ Совпадение с убийцей из папки Killers!")
                                                    
                                                    -- Автоочистка через 2 секунды
                                                    task.delay(2, function()
                                                        trackedAnimations[animKey] = nil
                                                    end)
                                                else
                                                    print("🚶 Пропущена анимация передвижения:", animId)
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

-- Улучшенная версия с дополнительной диагностикой
function AnimationDetector.StartWithDiagnostics(callback, radius)
    local localPlayer = Players.LocalPlayer
    local stopTracking = false
    local trackedAnimations = {}

    local function getKillerFromFolder()
        local killersFolder = Workspace.Players:FindFirstChild("Killers")
        if not killersFolder then 
            print("❌ Папка Killers не найдена!")
            return nil 
        end
        
        local killers = killersFolder:GetChildren()
        print("🔍 Найдено в папке Killers:", #killers)
        for i, killer in ipairs(killers) do
            print("  " .. i .. ". " .. killer.Name)
        end
        
        if #killers > 0 then
            return killers[1]
        end
        return nil
    end

    local function isMovementAnimation(animId, animator)
        -- Проверяем по длине (передвижение > 2 сек)
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
                    
                    -- КРИТИЧЕСКАЯ ПРОВЕРКА: сравниваем имя рига с именем убийцы из папки
                    if otherCharacter.Name == killerModel.Name then
                        print("✅ НАЙДЕН УБИЙЦА:", player.Name, "Риг:", otherCharacter.Name)
                        
                        if distance <= radius then
                            local humanoid = otherCharacter:FindFirstChildOfClass("Humanoid")
                            if humanoid then
                                local animator = humanoid:FindFirstChildOfClass("Animator")
                                if animator then
                                    local tracks = animator:GetPlayingAnimationTracks()
                                    if #tracks > 0 then
                                        print("🎭 Анимаций у убийцы:", #tracks)
                                    end
                                    
                                    for _, animTrack in ipairs(tracks) do
                                        if animTrack.IsPlaying then
                                            pcall(function()
                                                local animId = animTrack.Animation.AnimationId
                                                local animKey = player.Name .. "_" .. tostring(animId)
                                                
                                                if not trackedAnimations[animKey] then
                                                    -- Проверяем длину анимации
                                                    local isMovement = isMovementAnimation(animId, animator)
                                                    
                                                    if not isMovement then
                                                        trackedAnimations[animKey] = true
                                                        pcall(callback, animTrack, player, otherCharacter, tostring(animId))
                                                        
                                                        print("⚡ ВЫЗВАН CALLBACK! Анимация убийцы!")
                                                        print("🆔 ID:", animId)
                                                        print("📏 Длина:", animTrack.Length)
                                                        
                                                        task.delay(2, function()
                                                            trackedAnimations[animKey] = nil
                                                        end)
                                                    else
                                                        print("🚶 Пропущена (длина " .. animTrack.Length .. " сек):", animId)
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
    
    print("🎯 Отслеживание анимаций убийцы ЗАПУЩЕНО! Радиус: " .. radius .. " studs")
    return stopFunction
end

return AnimationDetector
