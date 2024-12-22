--@name Better Third Person
--@author Jacbo
--@shared

if SERVER then
    local camYaw = 0
    local targetYaw = 0
    local targetPitch = 0
    local yaw = 0
    local pitch = 0
    local turnSpeed = 720
    local active = false
    
    local w, a, s, d
    local function updateAngles()
        local w = w and 1 or 0
        local a = a and 1 or 0
        local s = s and 1 or 0
        local d = d and 1 or 0
        if w - s ~= 0 or a - d ~= 0 then
            targetYaw = camYaw + 180 / math.pi * math.atan2(a - d, w - s)
        end
    end
    
    net.receive("", function()
        camYaw = net.readFloat()
        if active then
            updateAngles()
        end
    end)
    
    net.receive("toggle", function()
        active = net.readBool()
        if active then
            -- Toggle on
            do
                local ang = owner():getEyeAngles()
                targetYaw = ang[2]
                yaw = targetYaw
                pitch = ang[1]
            end
            
            local function updateKeys()
                local w = w and 1 or 0
                local a = a and 1 or 0
                local s = s and 1 or 0
                local d = d and 1 or 0
                net.start("")
                net.writeBool(w - s ~= 0 or a - d ~= 0)
                net.send(owner())
            end
            
            --[[hook.add("KeyPress", "", function(ply, key)
                if ply == owner() then
                    if key == IN_KEY.FORWARD then
                        w = true
                    elseif key == IN_KEY.BACK then
                        s = true
                    elseif key == IN_KEY.MOVELEFT then
                        a = true
                    elseif key == IN_KEY.MOVERIGHT then
                        d = true
                    end
                    updateAngles()
                    updateKeys()
                end
            end)
            
            hook.add("KeyRelease", "", function(ply, key)
                if ply == owner() then
                    if key == IN_KEY.FORWARD then
                        w = false
                    elseif key == IN_KEY.BACK then
                        s = false
                    elseif key == IN_KEY.MOVELEFT then
                        a = false
                    elseif key == IN_KEY.MOVERIGHT then
                        d = false
                    end
                    updateAngles()
                    updateKeys()
                end
            end)]]
            
            net.receive("k", function()
                w = net.readBool()
                a = net.readBool()
                s = net.readBool()
                d = net.readBool()
                updateAngles()
            end)
            
            hook.add("think", "", function()
                local rate = turnSpeed * timer.frametime()
                yaw = math.approachAngle(yaw, targetYaw, rate)
                pitch = math.approachAngle(pitch, targetPitch, rate)
                owner():setEyeAngles(Angle(pitch, yaw, 0))
            end)
        else
            -- Toggle off
            hook.remove("think", "")
        end
    end)
elseif player() == owner() then -- CLIENT
    local active = false
    local camDist = 100
    
    local function activate()
        net.start("toggle")
        net.writeBool(true)
        net.send()
        
        local camAng = eyeAngles()
        local oldCamAng = camAng
        hook.add("mousemoved", "", function(dx, dy)
            camAng = camAng + Angle(dy / 45, -dx / 45, 0)
        end)
        
        hook.add("mouseWheeled", "", function(amount)
            camDist = camDist + amount * -10
        end)
        
        hook.add("think", "", function()
            if camAng ~= oldCamAng then
                oldCamAng = camAng
                net.start("")
                net.writeFloat(camAng[2])
                net.send()
            end
        end)
        
        hook.add("calcview", "", function()
            local forward = camAng:getForward()
            local start = owner():getPos() + Vector(0, 0, 65)
            local stop = start - forward * (camDist + 5)
            return {
                origin = trace.trace(start, stop, owner()).HitPos + forward * 5,
                angles = camAng,
                drawviewer = true
            }
        end)
        
        local w = false
        local a = false
        local s = false
        local d = false
        hook.add("inputPressed", "", function(key)
            local changed = false
            local bind = input.lookupKeyBinding(key)
            if bind == "+forward" then
                w = true
                changed = true
            elseif bind == "+moveleft" then
                a = true
                changed = true
            elseif bind == "+back" then
                s = true
                changed = true
            elseif bind == "+moveright" then
                d = true
                changed = true
            end
            if changed then
                concmd("+forward;-moveleft;-back;-moveright")
                net.start("k")
                net.writeBool(w)
                net.writeBool(a)
                net.writeBool(s)
                net.writeBool(d)
                net.send()
            end
        end)
        
        hook.add("inputReleased", "", function(key)
            local changed = false
            local bind = input.lookupKeyBinding(key)
            if bind == "+forward" then
                w = false
                changed = true
            elseif bind == "+moveleft" then
                a = false
                changed = true
            elseif bind == "+back" then
                s = false
                changed = true
            elseif bind == "+moveright" then
                d = false
                changed = true
            end
            if changed then
                if not w and not a and not s and not d then
                    concmd("-forward")
                end
                net.start("k")
                net.writeBool(w)
                net.writeBool(a)
                net.writeBool(s)
                net.writeBool(d)
                net.send()
            end
        end)
    end
    
    local function deactivate()
        net.start("toggle")
        net.writeBool(false)
        net.send()
        
        hook.remove("calcview", "")
    end
    
    activate()
    
    enableHud(owner(), true)
end    