print("v3")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer

local HitboxDetector = {}

function HitboxDetector.Start(callbackFunction, radiusValue)
    if HitboxDetector.Stop then
        HitboxDetector.Stop()
    end
    
    local isActive = true
    local detectionRadius = radiusValue or 10
    
    local function safeCallback(...)
        if isActive and callbackFunction then
            pcall(callbackFunction, ...)
        end
    end
    
    local function setupDetection()
        if not isActive then return end
        
        local character = localPlayer.Character
        if not character then return end
        
        local humanoid = character:FindFirstChild("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not rootPart or humanoid.Health <= 0 then return end
        
        local activeHitboxes = {}
        
        local function isKillerHitbox(hitbox)
            if not hitbox then return false end
            if hitbox.Name:find(localPlayer.Name) then return false end
            return true
        end
        
        local function checkHitboxTouch(hitbox)
            if not hitbox then return false end
            
            local touched = false
            local touchConnection
            
            local function onTouched(otherPart)
                if otherPart and otherPart.Parent == character then
                    touched = true
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
            if not isActive or not character or not rootPart then return end
            
            local hitboxesFolder = Workspace:FindFirstChild("Hitboxes")
            if not hitboxesFolder then return end
            
            for _, hitbox in ipairs(hitboxesFolder:GetChildren()) do
                if not isActive then break end
                
                if hitbox:IsA("BasePart") and not hitbox:GetAttribute("Hidden") then
                    local distance = (hitbox.Position - rootPart.Position).Magnitude
                    
                    if distance <= detectionRadius and isKillerHitbox(hitbox) then
                        if checkHitboxTouch(hitbox) then
                            if not activeHitboxes[hitbox] then
                                activeHitboxes[hitbox] = true
                                safeCallback(hitbox, localPlayer, character)
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
        
        local heartbeatConnection = RunService.Heartbeat:Connect(function()
            pcall(checkForHitboxes)
        end)
        
        local function cleanup()
            if heartbeatConnection then
                heartbeatConnection:Disconnect()
            end
            table.clear(activeHitboxes)
        end
        
        humanoid.Died:Connect(function()
            cleanup()
            if isActive then
                task.wait(3)
                pcall(setupDetection)
            end
        end)
        
        localPlayer.CharacterRemoving:Connect(function()
            cleanup()
        end)
        
        return cleanup
    end
    
    local stopFunction = setupDetection()
    
    localPlayer.CharacterAdded:Connect(function()
        if isActive then
            task.wait(2)
            if stopFunction then
                stopFunction()
            end
            stopFunction = setupDetection()
        end
    end)
    
    HitboxDetector.Stop = function()
        isActive = false
        if stopFunction then
            pcall(stopFunction)
            stopFunction = nil
        end
        HitboxDetector.Stop = nil
    end
    
    return HitboxDetector.Stop
end

return HitboxDetector
