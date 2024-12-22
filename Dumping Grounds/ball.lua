--@name Ball
--@author Jacbo
--@shared
--@include safeNet.txt

require("safeNet.txt")
local net = safeNet

if SERVER then
    local radius = 30
    local base = prop.create(chip():getPos() + Vector(0, 0, 50), Angle(), "models/hunter/plates/plate1x1.mdl", true)
    local holo = holograms.create(base:obbCenterW() - base:getUp(), base:getAngles(), "models/sprops/geometry/sphere_60.mdl")
    net.init(function(ply)
        return base:entIndex(), holo:entIndex(), radius
    end)
else -- CLIENT
    local deltaTime = 1
    local oldTime = timer.curtime()
    hook.add("think", "time", function()
        local time = timer.curtime()
        deltaTime = time - oldTime
        oldTime = time
    end)
    
    net.init(function(basei, holoi, radius)
        local base, holo
        hook.add("think", "init", function()
            base = entity(basei)
            holo = entity(holoi):toHologram()
            if base and holo and base:isValid() and holo:isValid() then
                hook.remove("think", "init")
                
                local maxHeight = radius * 1.5
                local holoAng = holo:getAngles()
                local oldPos
                local angVel = {Vector(1,0,0), 0}
        
                hook.add("think", "", function()
                    local origin = base:obbCenterW()
                    local up = base:getUp()
                    local trc = trace.trace(origin, origin - up * (maxHeight + radius), base)
                    local dist
                    if trc.Hit then
                        dist = trc.Fraction * (maxHeight + radius) - radius
                        local pos = trc.HitPos
                        if oldPos and oldPos ~= pos then
                            local dir = pos - oldPos
                            local length = dir:getLength()
                            local dirn = dir / length
                            
                            local axis = dirn:cross(up)
                            local rad = -length / radius
                            holoAng = holoAng:rotateAroundAxis(axis, nil, rad)
                            angVel = {axis, rad}
                            holo:setAngles(holoAng)
                        else
                            angVel[2] = 0
                        end
                        oldPos = pos
                    else
                        oldPos = nil
                        dist = maxHeight
                        if angVel[2] ~= 0 and angVel[2] == angVel[2] and angVel[2] ~= 1/0 and angVel[2] ~= -1/0 then
                            angVel[2] = angVel[2] * (1 - math.sqrt(deltaTime*deltaTime/8))
                            holoAng = holoAng:rotateAroundAxis(angVel[1], nil, angVel[2])
                            holo:setAngles(holoAng)
                        end
                    end
                    holo:setPos(origin - up * dist)
                end)
            end
        end)
    end)
end