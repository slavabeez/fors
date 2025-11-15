local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer

local currentDetectionConnection
local isDetectionActive = false
local currentRadiusValue = 10

local function StartHitboxDetection(callbackFunction, radiusValue)
    if not callbackFunction then
        warn("Callback function is nil!")
        return function() end
    end
    
    if currentDetectionConnection then
        currentDetectionConnection()
        currentDetectionConnection = nil
    end
    
    isDetectionActive = true
    currentRadiusValue = radiusValue or 10

    local function setupDetection()
        if not isDetectionActive then return end
        
        local character = localPlayer.Character
        if not character then return end
        
        local humanoid = character:FindFirstChild("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not rootPart then return end
        
        local activeHitboxes = {}
        local DETECTION_RADIUS = currentRadiusValue or 10

        local function isKillerHitbox(hitbox)
            if not hitbox then return false end
            if not hitbox.Name then return false end
            
            if hitbox.Name:find(localPlayer.Name) then
                return false
            end
            
            if hitbox:GetAttribute("Damage") and hitbox:GetAttribute("Damage") > 0 then
                return true
            end
            
            if hitbox.Name:find("Killer") or hitbox.Name:find("Damage") then
                return true
            end
            
            return true
        end

        local function checkHitboxTouch(hitbox, character)
            if not hitbox or not character then return false end
            
            local touched = false
            local touchConnection
            
            local function onTouched(otherPart)
                if otherPart and otherPart.Parent == character then
                    touched = true
                    if touchConnection then
                        touchConnection:Disconnect()
                    end
                end
            end
            
            if not hitbox:IsA("BasePart") then return false end
            
            local originalCanTouch = hitbox.CanTouch
            hitbox.CanTouch = true
            
            touchConnection = hitbox.Touched:Connect(onTouched)
            
            RunService.Heartbeat:Wait()
            
            hitbox.CanTouch = originalCanTouch
            if touchConnection then
                touchConnection:Disconnect()
            end
            
            return touched
        end

        local function checkForHitboxes()
            if not isDetectionActive or not character or not rootPart or humanoid.Health <= 0 then
                return
            end
            
            local characterPos = rootPart.Position
            local hitboxesFolder = Workspace:FindFirstChild("Hitboxes")
            if not hitboxesFolder then return end
            
            for _, hitbox in ipairs(hitboxesFolder:GetChildren()) do
                if hitbox:IsA("BasePart") and not hitbox:GetAttribute("Hidden") then
                    if not hitbox.Position then continue end
                    
                    local distance = (hitbox.Position - characterPos).Magnitude
                    
                    if distance and DETECTION_RADIUS and distance <= DETECTION_RADIUS and isKillerHitbox(hitbox) then
                        if checkHitboxTouch(hitbox, character) then
                            if not activeHitboxes[hitbox] then
                                activeHitboxes[hitbox] = true
                                
                                -- 🔧 ЗАЩИЩЕННЫЙ ВЫЗОВ CALLBACK 🔧
                                if type(callbackFunction) == "function" then
                                    pcall(function()
                                        callbackFunction(hitbox, localPlayer, character)
                                    end)
                                end
                            end
                        else
                            activeHitboxes[hitbox] = nil
                        end
                    else
                        activeHitboxes[hitbox] = nil
                    end
                end
            end
        end

        local detectionConnection
        detectionConnection = RunService.Heartbeat:Connect(function()
            pcall(checkForHitboxes)
        end)

        humanoid.Died:Connect(function()
            if detectionConnection then
                detectionConnection:Disconnect()
            end
            table.clear(activeHitboxes)
            if isDetectionActive then
                task.wait(3)
                pcall(setupDetection)
            end
        end)

        return function()
            if detectionConnection then
                detectionConnection:Disconnect()
            end
            table.clear(activeHitboxes)
        end
    end

    local function initializeDetection()
        local stopFunction
        
        localPlayer.CharacterAdded:Connect(function(character)
            if stopFunction then
                stopFunction()
            end
            if isDetectionActive then
                task.wait(1)
                stopFunction = pcall(setupDetection) or nil
            end
        end)

        if localPlayer.Character then
            task.wait(1)
            stopFunction = pcall(setupDetection) or nil
        end
        
        return stopFunction
    end

    currentDetectionConnection = initializeDetection()
    
    return function()
        isDetectionActive = false
        if currentDetectionConnection then
            pcall(currentDetectionConnection)
            currentDetectionConnection = nil
        end
    end
end

return StartHitboxDetection
