--@name Balls
--@author Jacbo
--@shared

if SERVER then
    local owner = owner()
    local pos = chip():getPos()
    local screen = find.closest(find.byClass("starfall_screen", function(ent)
        return ent:getOwner() == owner
    end), pos)
    if screen then
        screen:linkComponent(chip())
        if cb then
            cb(screen)
        end
    else
        hook.add("tick", "find screen", function()
            screen = find.closest(find.byClass("starfall_screen", function(ent)
                return ent:getOwner() == owner
            end), pos)
            if screen then
                screen:linkComponent(chip())
                if cb then
                    cb(screen)
                end
                hook.remove("tick", "find screen")
            end
        end)
    end
else -- CLIENT
    local minSize = 20
    local maxSize = 40
    local ballCount = 30
    local iterations = 3
    local interval = 1 / 30
    local gravConst = 600 * interval * interval / iterations / iterations
    local nextTick = timer.curtime()
    -- {x, y, oldx, oldy, radius}
    local balls = {}
    local spawnedBallCount = 0
    
    local render_drawTexturedRect = render.drawTexturedRect
    local math_sqrt = math.sqrt
    
    local centerx = 256
    local centery = 256
    
    render.createRenderTarget("bg")
    render.createRenderTarget("circle")

    hook.add("renderoffscreen", "init", function()
        render.selectRenderTarget("circle")
        local count = 50
        local interval = math.pi * 2 / count
        local poly = {}
        for i = 1, count do
            table.insert(poly,{x = 512 + 512 * math.cos(i * interval),y = 512 + 512 * math.sin(i * interval)})
        end
        render.clear(Color(0,0,0,0))
        render.setRGBA(255,255,255,255)
        render.drawPoly(poly)
        
        render.selectRenderTarget("bg")
        render.clear(Color(255,255,255))
        render.setRGBA(0,0,0,255)
        render.setRenderTargetTexture("circle")
        render.drawTexturedRect(0,0,1024,1024)
        
        hook.remove("renderoffscreen", "init")
    end)
    
    local init = false
    local screenOldPos
    local screenSizeMult = 1
    
    hook.add("render", "", function()
        render.setRenderTargetTexture("bg")
        render_drawTexturedRect(0, 0, 512, 512)
        
        render.setRenderTargetTexture("circle")
        
        -- Draw balls
        local originx = centerx - 256
        local originy = centery - 256
        for k, ball in ipairs(balls) do
            local radius = ball[5]
            render_drawTexturedRect(ball[1] - radius - originx, ball[2] - radius - originy, radius * 2, radius * 2)
        end
        
        local time = timer.curtime()
        if time >= nextTick then
            -- Tick
            nextTick = nextTick + math.floor((time + interval - nextTick) / interval) * interval
            
            if spawnedBallCount < ballCount then
                -- Spawn ball
                local x = centerx + math.rand(-1, 1)
                local y = centery + math.rand(-1, 1)
                table.insert(balls, {x, y, x, y, math.rand(minSize, maxSize)})
                spawnedBallCount = spawnedBallCount + 1
            end
            
            local screen = render.getScreenEntity()
            
            local screenAngles = screen:getAngles()
            local downLocal = worldToLocal(Vector(0, 0, -1), Angle(), Vector(), screenAngles)
            local gravx = downLocal[2] * gravConst
            local gravy = downLocal[1] * gravConst
            local screenPos = screen:getPos()
            
            if not init then
                init = true
                screenOldPos = screenPos
                local info = render.getScreenInfo(screen)
                --screenSizeMult = info.RS / iterations
                screenSizeMult = info.RS * iterations
            end
            
            local dpos = screenPos - screenOldPos
            screenOldPos = screenPos
            local ballsShift = worldToLocal(dpos, Angle(), Vector(), screenAngles)
            --local shiftx = -ballsShift[2] * screenSizeMult
            --local shifty = -ballsShift[1] * screenSizeMult
            centerx = centerx + ballsShift[2] * screenSizeMult
            centery = centery - ballsShift[1] * screenSizeMult
            
            -- Simulate balls
            for iteration = 1, iterations do
                for i = 1, spawnedBallCount do
                    local ball1 = balls[i]
                    
                    -- Ball collisions
                    for j = i + 1, spawnedBallCount do
                        local ball2 = balls[j]
                        
                        local minDist = ball1[5] + ball2[5]
                        local x1 = ball1[1] - ball2[1]
                        local y1 = ball1[2] - ball2[2]
                        local distSqr = x1 * x1 + y1 * y1
                        
                        if distSqr < minDist * minDist then
                            -- Balls intersecting
                            local dist = math_sqrt(distSqr)
                            local mult = 0.5 * (minDist - dist) / dist
                            
                            ball1[1] = ball1[1] + x1 * mult
                            ball1[2] = ball1[2] + y1 * mult
                            
                            ball2[1] = ball2[1] - x1 * mult
                            ball2[2] = ball2[2] - y1 * mult
                        end
                    end
                    
                    -- Ball boundaries
                    local x1 = ball1[1] - centerx
                    local y1 = ball1[2] - centery
                    local distSqr = x1 * x1 + y1 * y1
                    local maxDist = 256 - ball1[5]
                    
                    if distSqr > maxDist * maxDist then
                        -- Move ball
                        local mult = maxDist / math_sqrt(distSqr)
                        ball1[1] = centerx + x1 * mult
                        ball1[2] = centery + y1 * mult
                    end
                end
                
                -- Move balls
                for k, ball in ipairs(balls) do
                    local tempx = ball[1]
                    local tempy = ball[2]
                    ball[1] = ball[1] * 2 - ball[3] + gravx-- + shiftx
                    ball[2] = ball[2] * 2 - ball[4] + gravy-- + shifty
                    ball[3] = tempx-- + shiftx
                    ball[4] = tempy-- + shifty
                end
            end
        end
    end)
end