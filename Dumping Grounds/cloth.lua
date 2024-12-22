-- https://www.youtube.com/watch?v=GY8gq-EZhF4

--@name Cloth
--@author Jacbo
--@server
--@include spawn_blocking.txt

require("spawn_blocking.txt")

corWrap(function()
    if SERVER then
        local count = 3
        local length = 15
        
        local pin1 = Vector(0, -count * length * 0.5, 0)
        local pin2 = Vector(0, count * length * 0.5, 0)
        
        --{pos, prev pos, locked, holo}
        local points = {}
        --{point A, point B, length, holo}
        local sticks = {}
        
        local origin = chip():getPos()
        local dy = chip():getForward()[2] * length
        local dz = chip():getForward()[3] * length
        local scale = Vector(length, 3, 3) / 12
        
        local point2d = {}
        local pin1id, pind2id
        
        do
            local pointCount = 0
            local y1 = -count * 0.5
            local t = {}
            for y = -count * 0.5, count * 0.5 do
                t[y] = {}
                local t1 = t[y]
                local t2 = t[y - 1]
                for z = 0, -count, -1 do
                    local v = origin + Vector(0, dy * y, dz * z)
                    table.insert(points, {v, v, false})
                    pointCount = pointCount + 1
                    t1[z] = pointCount
                    if y > y1 then
                        table.insert(sticks, {t2[z], pointCount, length*0.5, holograms.create(v, Angle(), "models/holograms/cube.mdl", scale)})
                    end
                    if z < 0 then
                        table.insert(sticks, {t1[z + 1], pointCount, length*0.5, holograms.create(v, Angle(), "models/holograms/cube.mdl", scale)})
                    end
                end
            end
            
            pin1id = t[-count * 0.5][0]
            pin2id = t[count * 0.5][0]
            
            points[pin1id][3] = true
            points[pin2id][3] = true
        end
        
        --points[1][3] = true
        
        local gravity = physenv.getGravity() * game.getTickInterval()^2
        local iterations = 1
        
        hook.add("think", "", function()
            points[pin1id][1] = chip():localToWorld(pin1)
            points[pin2id][1] = chip():localToWorld(pin2)
            
            for _, p in ipairs(points) do
                if not p[3] then
                    local pre = p[1]
                    p[1] = p[1] * 2 - p[2] + gravity
                    p[2] = pre
                end
                --p[4]:setPos(p[1])
            end
            
            for i = 1, iterations do
                for _, stick in ipairs(sticks) do
                    local point1 = points[stick[1]]
                    local point2 = points[stick[2]]
                    --local length = stick[3] * 0.5
                    local center = (point1[1] + point2[1]) * 0.5
                    local dir = (point1[1] - point2[1]):getNormalized() * stick[3]
                    if not point1[3] then
                        point1[1] = center + dir
                    end
                    if not point2[3] then
                        point2[1] = center - dir
                    end
                    local holo = stick[4]
                    holo:setPos(center)
                    holo:setAngles(dir:getAngle())
                end
            end
        end)
    else -- CLIENT
        
    end
end)