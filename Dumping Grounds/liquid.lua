--@name Liquid Container
--@author Jacbo
--@shared

if SERVER then
    local container = prop.create(chip():getPos() + Vector(0,0,25), Angle(), "models/hunter/tubes/tube1x1x2.mdl")
    container:setMaterial("phoenix_storms/glass")
    local center
    do
        local min, max = container:getPhysicsObject():getAABB()
        center = (min + max) / 2
    end
    
    net.receive("", function(_, ply)
        net.start("")
        if net.readBool() then
            net.writeVector(center)
        end
        net.writeEntity(container)
        net.send(ply)
    end)
else -- CLIENT
    local containerRadius = (47.45 - 6) / 2
    local containerVolume = math.pi * containerRadius^2 * 47.45 * 2
    local containerArea = math.pi * containerRadius^2
    local cylinderWidthScale = containerRadius / 47.45
    local liquidVolume = containerVolume / 2
    local center
    
    net.receive("", function()
        if not center then
            center = net.readVector()
        end
        
        net.readEntity(function(container)
            if not container or not container:isValid() then
                -- Invalid entity
                timer.simple(10 + math.rand(0, 2), function()
                    net.start("")
                    net.writeBool(false)
                    net.send()
                end)
                return
            end
            
            -- Valid entity
            local holo = hologram.create(container:localToWorld(center + Vector(0,0,47.45 + 1.5)), container:getAngles(), "models/hunter/tubes/circle2x2.mdl", Vector(0.5, 0.5, 1))
            holo:setParent(container)
            holo:setMaterial("phoenix_storms/glass")
            holo = hologram.create(container:localToWorld(center + Vector(0,0,-47.45 - 1.5)), container:getAngles(), "models/hunter/tubes/circle2x2.mdl", Vector(0.5, 0.5, 1))
            holo:setParent(container)
            holo:setMaterial("phoenix_storms/glass")
            
            local liquidCylinder = hologram.create(Vector(), container:getAngles(), "models/hunter/tubes/circle2x2.mdl")
            liquidCylinder:setParent(container)
            local liquidCap = hologram.create(Vector(), container:getAngles(), "models/hunter/tubes/circle2x2.mdl")
            liquidCap:setParent(container)
            
            --[[local v_pos = container:localToWorld(center)
            local v_oldPos = v_pos
            
            local interval = 1 / 60
            local radius = 50
            timer.create("", interval, 0, function()
                local c_pos = container:localToWorld(center)
                v_pos = v_pos * 2 - v_oldPos + physenv.getGravity() * interval
                local dist = v_pos:getDistanceSqr(c_pos)
                if dist > radius * radius then
                    v_pos = c_pos + (v_pos - c_pos) * radius / math.sqrt(dist)
                end
                v_oldPos = v_pos
            end)]]
            
            --[[local l_up = c_pos - v_pos
                l_up:normalize()
                if l_up[3] < 0 then
                    l_up = -l_up
                end
                
                
                local c_forward = c_up:cross(Vector(0,0,1)):cross(l_up):getNormalized()
                local c_right = c_up:cross(Vector(0,0,1)):cross(l_up):getNormalized()
                
                
                
                --local _, ang = localToWorld(Vector(), Angle(-90, 0, 0), Vector(), l_up:getAngle())
                --liquidCap:setScale(Vector(slopeHypF / 94.9, slopeHypH / 94.9, 0.001))]]
                
            local l_up = Vector(0, 0, 1)
            
            hook.add("think", "", function()
                local c_ang = container:getAngles()
                local c_pos = container:localToWorld(center)
                
                local c_up = container:getUp()
                if c_up[3] < 0 then
                    c_up = -c_up
                end
                local dot = l_up:dot(c_up)
                local parallel = dot > 0.999
                local slopeAng = math.acos(dot)
                local slopeHeight = math.tan(slopeAng) * containerRadius * 2
                --[[if slopeHeight > 94.9 then
                    -- Extends beyond container
                    -- volume = 94.9 * (2 * math.asin(height / 41.45) / math.pi - containerRadius *  height / 20.725)
                else]]
                    -- Fits in container
                    local slopeHyp = containerRadius / dot * 2
                    local height = liquidVolume / containerArea - slopeHeight / 2
                    local totalHeight = height + slopeHeight
                
                    liquidCylinder:setScale(Vector(cylinderWidthScale, cylinderWidthScale, totalHeight / 3))
                    liquidCylinder:setPos(c_pos + c_up * (totalHeight / 2 - 47.45))
                    local capPos = c_pos + c_up * (height + slopeHeight / 2 - 47.45)
                    liquidCylinder:setClip(1, not parallel, capPos, -l_up)
                
                    local capForward = c_up:cross(l_up):cross(l_up)
                    liquidCap:setScale(Vector(slopeHyp / 94.9, cylinderWidthScale, 0.001))
                    liquidCap:setAngles(capForward:getAngle())
                    liquidCap:setPos(capPos)
                    liquidCap:setNoDraw(parallel)
                --end
            end)
        end)
    end)
    net.start("")
    net.writeBool(true)
    net.send()
end