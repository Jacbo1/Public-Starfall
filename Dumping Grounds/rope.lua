--@name Rope
--@author Jacbo
--@shared
--@include spawn_blocking.txt

require("spawn_blocking.txt")

corWrap(function()
    if SERVER then
        local count = 20
        
        --{pos, prev pos, locked, holo}
        local points = {}
        --{point A, point B, length, holo}
        local sticks = {}
        
        local origin = chip():getPos()
        local length = 10
        local delta = Vector(1):getNormalized() * length
        local scale = Vector(length, 3, 3) / 12
        for i = 1, count do
            local v = origin + delta * (i - 1)
            //table.insert(points, {v, v, false, holograms.create(v, Angle(), "models/holograms/cube.mdl")})
            table.insert(points, {v, v, false})
            if i ~= 1 then
                table.insert(sticks, {i-1, i, length*0.5, holograms.create(v, Angle(), "models/holograms/cube.mdl", scale)})
            end
        end
        points[1][3] = true
        
        local iterations = 1
        local gravity = physenv.getGravity() * (game.getTickInterval() / iterations)^2
        
        hook.add("think", "", function()
            points[1][1] = chip():getPos()
            
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
                
                for _, p in ipairs(points) do
                    if not p[3] then
                        local pre = p[1]
                        p[1] = p[1] * 2 - p[2] + gravity
                        p[2] = pre
                    end
                    //p[4]:setPos(p[1])
                end
            end
        end)
    else -- CLIENT
        
    end
end)