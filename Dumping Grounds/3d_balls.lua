--@name 3D Balls
--@author Jacbo
--@shared

if SERVER then
    local physSphere = prop.create(chip():getPos() + Vector(0, 0, 50), Angle(), "models/hunter/misc/sphere2x2.mdl", true)
    physSphere:setDrawShadow(false)
    physSphere:setColor(Color(0, 0, 0, 0))
    
    local shellRadius = 47.45 - 2
    
    local shellHolo = holograms.create(physSphere:obbCenterW(), Angle(), "models/holograms/hq_sphere.mdl", Vector(shellRadius * 2 / 12) * Vector(1, 1, -1))
    shellHolo:setColor(Color(0, 0, 0, 255))
    shellHolo:setParent(physSphere)
    shellHolo:suppressEngineLighting(true)
    
    local ballCount = 20
    local iterations = 1
    local gravConst = physenv.getGravity() * (game.getTickInterval() / iterations)^2
    -- {pos, oldpos, radius}
    local balls = {}
    local spawnedBallCount = 0
    
    local math_sqrt = math.sqrt
    
    hook.add("think", "", function()
        -- Tick
        local sphereCenter = physSphere:obbCenterW()
        
        if spawnedBallCount < ballCount and holograms.canSpawn() then
            -- Spawn ball
            local pos = sphereCenter + Vector(math.rand(-1, 1), math.rand(-1, 1), math.rand(-1, 1))
            local radius = math.rand(5, 10)
            table.insert(balls, {pos, pos, radius, holograms.create(pos, Angle(), "models/holograms/hq_sphere.mdl", Vector(radius * 2 / 12))})
            spawnedBallCount = spawnedBallCount + 1
        end
        
        -- Simulate balls
        for iteration = 1, iterations do
            for i = 1, spawnedBallCount do
                local ball1 = balls[i]
                
                -- Ball collisions
                for j = i + 1, spawnedBallCount do
                    local ball2 = balls[j]
                    
                    local minDist = ball1[3] + ball2[3]
                    local dp = ball1[1] - ball2[1]
                    local distSqr = dp:dot(dp)
                    
                    if distSqr < minDist * minDist then
                        -- Balls intersecting
                        local dist = math_sqrt(distSqr)
                        local mult = 0.5 * (minDist - dist) / dist
                        
                        ball1[1] = ball1[1] + dp * mult
                        ball2[1] = ball2[1] - dp * mult
                    end
                end
            end
            
            -- Move balls
            for k, ball in ipairs(balls) do
                local temp = ball[1]
                ball[1] = ball[1] * 2 - ball[2] + gravConst
                ball[2] = temp
            end
            
            -- Ball boundaries
            for i = 1, spawnedBallCount do
                local ball1 = balls[i]
                local dp = ball1[1] - sphereCenter
                local distSqr = dp:dot(dp)
                local maxDist = shellRadius - ball1[3]
                
                if distSqr > maxDist * maxDist then
                    -- Move ball
                    local mult = maxDist / math_sqrt(distSqr)
                    ball1[1] = sphereCenter + dp * mult
                end
            end
        end
        
        -- Move holos
        for k, ball in ipairs(balls) do
            ball[4]:setPos(ball[1])
        end
    end)
else -- CLIENT
    
end