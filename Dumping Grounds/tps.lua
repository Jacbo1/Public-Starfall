-- Shows server TPS
-- Connect to screen

--@name TPS
--@author Jacbo
--@shared
--@include funcs.txt

math.lerpColor = function(fraction, a, b)
    return Color(a[1] + (b[1] - a[1]) * fraction,
        a[2] + (b[2] - a[2]) * fraction,
        a[3] + (b[3] - a[3]) * fraction,
        a[4] + (b[4] - a[4]) * fraction)
end

math.lerpColors = function(fraction, ...)
    local colors = {...}
    local sub1 = #colors - 1
    local i = math.clamp(math.floor(fraction * sub1) + 1, 1, sub1)
    local a = colors[i]
    local b = colors[i + 1]
    fraction = (fraction - (i-1) / sub1) * sub1
    return Color(a[1] + (b[1] - a[1]) * fraction,
        a[2] + (b[2] - a[2]) * fraction,
        a[3] + (b[3] - a[3]) * fraction,
        a[4] + (b[4] - a[4]) * fraction)
end

require("funcs.txt")

if SERVER then
    funcs.linkToClosestScreen()
    
    local queue = {}
    local tps = 0
    
    --[[net.receive("tps", function()
        tps = net.readFloat()
        net.start("tps")
        net.writeFloat(tps)
        net.send()
    end)
    
    net.receive("info", function()
        net.start("info")
        net.writeFloat(timer.frametime())
        net.send(owner())
    end)]]
else--CLIENT
    local tps = 0
    local perc = 0
    
    local fadedPerc = 0
    local percFadeSpeed = 1
    
    local function thickLine(ax, ay, bx, by, thickness)
        local sidex = by - ay
        local sidey = ax - bx
        local length = math.sqrt(sidex * sidex + sidey * sidey)
        sidex = sidex * thickness * 0.5 / length
        sidey = sidey * thickness * 0.5 / length
        render.drawPoly({
            {x = ax - sidex, y = ay - sidey},
            {x = ax + sidex, y = ay + sidey},
            {x = bx + sidex, y = by + sidey},
            {x = bx - sidex, y = by - sidey}
        })
    end
    
    local function start()
        local gradientMat = material.create("UnlitGeneric")
        gradientMat:setTexture("$basetexture", "gui/gradient_up")
        
        local colors = {{Color(10, 108, 194), Color(35, 202, 252), Color(45, 227, 25)}, {Color(237, 180, 24), Color(230, 230, 0), Color(240, 140, 10)}, {Color(156, 0, 0), Color(255, 23, 77), Color(255, 112, 112)}}
        
        local grid = {}
        local spacing = 50
        local i512 = 1/512
        local i256 = 1/256
        local sin = math.sin
        local cos = math.cos
        --for x = 0-spacing, 511+spacing, spacing do
        for y = 256, 511+spacing, spacing do
            local spacing = spacing * y * i512
            local row = {}
            for x = (-spacing*2-256)*256/y+256, (511+spacing*2-256)*256/y+256, spacing do
                local r1 = math.rand(0, 2)
                local r2 = math.rand(0, 2)
                table.insert(row, {x, y, nil, function(time)
                    return sin(time * r1) * cos(time * r2)
                end})
            end
            table.insert(grid, row)
        end
        
        --Connect vertically
        for i = 1, #grid-1 do
            local row1 = grid[i]
            local row2 = grid[i+1]
            local start = math.round((#row1 - #row2) * 0.5)
            for j = start, #row2+start do
                try(function()
                    row1[j][3] = row2[j-start]
                end)
            end
        end
        
        local font = render.createFont("consolas", 50, nil, true)
        
        local lastTime
        local time = 0
        local init = true
        hook.add("render", "", function()
            if init then
                init = false
                render.setFont(font)
            end
            --startTime = startTime or timer.curtime()
            --perc = math.clamp((timer.curtime()-startTime)*0.1, 0, 1)
            
            local percFade = timer.frametime() * percFadeSpeed
            fadedPerc = fadedPerc + math.clamp(perc - fadedPerc, -percFade, percFade)
            
            local timeMult = math.lerp(fadedPerc, 20, 1)
            local shiftMult = math.lerp(fadedPerc, 70, 10)
            
            lastTime = lastTime or timer.curtime()
            time = time + (timer.curtime() - lastTime) * timeMult
            lastTime = timer.curtime()
            
            render.setColor(math.lerpColors(fadedPerc, colors[3][1], colors[2][1], colors[1][1]))
            render.drawRect(0, 0, 512, 512)
            render.setColor(math.lerpColors(fadedPerc, colors[3][2], colors[2][2], colors[1][2]))
            render.setMaterial(gradientMat)
            render.drawTexturedRect(0, 0, 512, 512)
            
            render.setRGBA(0, 0, 0, 255)
            render.drawRect(0, 180, 512, 50)
            render.setColor(math.lerpColors(perc, colors[3][3], colors[2][3], colors[1][3]))
            render.drawRect(0, 180, 512*perc, 50)
            render.setRGBA(255, 255, 255, 255)
            render.drawRectOutline(0, 180, 512, 50)
            render.drawSimpleText(256, 100, math.round(tps) .. " Server TPS", 1, 1)
            
            
            --for _, point in ipairs(grid) do
            for j, row in ipairs(grid) do
                local x2, y2
                for i = 1, #row-1 do
                    local point1, point2 = row[i], row[i+1]
                    local x1, y1 = x2 or point1[1], y2 or point1[2]
                    x2, y2 = point2[1], point2[2]
                    local y12 = y1 + point1[4](time) * shiftMult
                    local y22 = y2 + point2[4](time) * shiftMult
                    local x12 = (x1 - 256) * y12 * i256 + 256
                    local x22 = (x2 - 256) * y22 * i256 + 256
                    y12 = ((y12-256)*i256)^2*256+256
                    y22 = ((y22-256)*i256)^2*256+256
                    render.drawLine(x12, y12, x22, y22)
                    
                    local point3 = point1[3]
                    if point3 then
                        local x3, y3 = point3[1], point3[2]
                        y3 = y3 + point3[4](time) * shiftMult
                        x3 = (x3 - 256) * y3 * i256 + 256
                        y3 = ((y3-256)*i256)^2*256+256
                        render.drawLine(x12, y12, x3, y3)
                    end
                end
            end
        end)
    end
    
    --[[if player() == owner() then
        local tickInterval = 1
        net.start("info")
        net.send()
        net.receive("info", function()
            tickInterval = net.readFloat()
        end)]]
        
        hook.add("tick", "", function()
            local ft, std
            ft, std = game.serverFrameTime()
            tps = 1/ft
            perc = math.clamp(game.getTickInterval() / ft, 0, 1)
            --[[net.start("tps")
            net.writeFloat(tps)
            net.writeFloat(perc)
            net.send()]]
        end)
        
        start()
    --[[else
        local started = false
        
        net.receive("tps", function()
            tps = net.readFloat()
            perc = net.readFloat()
            if not started then
                started = true
                start()
            end
        end)
    end]]
end