-- Sudoku solver that uses Wave Function Collapse
-- https://www.youtube.com/watch?v=oBTkGgIgQe8

--@name Sudoku Wave Function Collapse
--@author Jacbo
--@shared
--@include better_coroutines.txt

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
    local corlib = require("better_coroutines.txt")
    
    local math_floor = math.floor
    local render_drawTexturedRectUV = render.drawTexturedRectUV
    local render_pushMatrix = render.pushMatrix
    local render_popMatrix = render.popMatrix
    local render_drawPoly = render.drawPoly
    local render_drawRect = render.drawRect
    local math_cos = math.cos
    local math_sin = math.sin
    local math_rand = math.rand
    local table_insert = table.insert
    local table_remove = table.remove
    
    local function drawRectOutlineThickness(x, y, w, h, thickness)
        render_drawRect(x, y, w, thickness)
        render_drawRect(x, y + thickness, thickness, h - thickness * 2)
        render_drawRect(x, y + h - thickness, w, thickness)
        render_drawRect(x + w - thickness, y + thickness, thickness, h - thickness * 2)
    end
    
    render.createRenderTarget("main")
    render.createRenderTarget("numbers")
    
    local boardSize = 1024 - 100
    local xOffset = (1024 - boardSize) / 2
    
    local bigDiff = boardSize / 3
    local bigDiff2 = bigDiff * 0.5
    local smallDiff = bigDiff / 3
    local smallDiff2 = smallDiff * 0.5
    local smallerDiff = smallDiff / 3
    local smallerDiff2 = smallerDiff * 0.5
    
    local buttons = {}
    local redrawQueued = false
    
    -- {x, y, sideVel, vertVel, ang, angVel, number, time}
    local fallingTiles = {}
    local maxSideVel = 50
    local vertVel = -100
    local gravity = 200
    local maxAngVel = 30
    local popInterval = 0.01
    local lastPopTime = 0
    local solving = false
    local solvingOnce = false
    
    local popQueue = {}
    
    local state = {}
    
    local function reset()
        solving = false
        solvingOnce = false
        popQueue = {}
        
        state = {}
        for x = 1, 3 do
            local t = {}
            for y = 1, 3 do
                -- Big grid
                local t2 = {}
                for x1 = 1, 3 do
                    local t3 = {}
                    for y1 = 1, 3 do
                        -- Small grid
                        local t4 = {}
                        for i = 1, 9 do
                            -- Choices
                            table_insert(t4, true)
                        end
                        table_insert(t3, t4)
                    end
                    table_insert(t2, t3)
                end
                table_insert(t, t2)
            end
            table_insert(state, t)
        end
        
        redrawQueued = true
    end
    
    reset()
    
    local function renderNumber(number, x, y, w, h, rotation)
        local u1 = ((number - 1) % 3) / 3
        local v1 = math_floor((number - 1) / 3) / 3
        local u2 = (((number - 1) % 3) + 1) / 3
        local v2 = (math_floor((number - 1) / 3) + 1) / 3
        if rotation and rotation ~= 0 then
            -- Rotate
            local cos = math_cos(rotation)
            local sin = math_sin(rotation)
            local w2 = w * 0.5;
            local h2 = h * 0.5;
            render_drawPoly({
                {
                    x = x - w2 * cos + h2 * sin,
                    y = y - w2 * sin - h2 * cos,
                    u = u1,
                    v = v1
                }, {
                    x = x + w2 * cos + h2 * sin,
                    y = y + w2 * sin - h2 * cos,
                    u = u2,
                    v = v1
                }, {
                    x = x + w2 * cos - h2 * sin,
                    y = y + w2 * sin + h2 * cos,
                    u = u2,
                    v = v2
                }, {
                    x = x - w2 * cos - h2 * sin,
                    y = y - w2 * sin + h2 * cos,
                    u = u1,
                    v = v2
                }
            })
            --x = x * cos - y * sin,
            --y = x * sin + y * cos
        else
            render_drawTexturedRectUV(x - w * 0.5, y - h * 0.5, w, h, u1, v1, u2, v2)
        end
    end
    
    local buttonFont
    
    local function drawBoard()
        redrawQueued = false
        render.selectRenderTarget("main")
        render.setRenderTargetTexture("numbers")
        render.clear(Color(0, 0, 0, 255))
        
        -- Draw numbers
        for x1 = 1, 3 do
            for y1 = 1, 3 do
                -- Big grid
                for x2 = 1, 3 do
                    for y2 = 1, 3 do
                        -- Small grid
                        local x = (x1 - 1) * bigDiff + (x2 - 1) * smallDiff + xOffset
                        local y = (y1 - 1) * bigDiff + (y2 - 1) * smallDiff
                        
                        local count = 0
                        local nums = {}
                        
                        for k, v in ipairs(state[x1][y1][x2][y2]) do
                            if v then
                                count = count + 1
                                table_insert(nums, k)
                            end
                        end
                        
                        if count == 1 then
                            -- One choice
                            renderNumber(nums[1], x + smallDiff2, y + smallDiff2, smallDiff, smallDiff)
                        else
                            x = x - smallerDiff2
                            y = y + smallerDiff2
                            -- Multiple choices
                            local counter = 0
                            for k, v in ipairs(nums) do
                                counter = counter + 1
                                x = x + smallerDiff
                                if counter == 4 then
                                    counter = 1
                                    x = x - smallerDiff * 3
                                    y = y + smallerDiff
                                end
                                
                                renderNumber(v, x, y, smallerDiff, smallerDiff)
                            end
                        end
                    end
                end
            end
        end
        
        -- Draw lines
        local smallGridThick = 2
        local smallGridThick2 = smallGridThick * 0.5
        local bigGridThick = 8
        local bigGridThick2 = bigGridThick * 0.5
        
        --render_drawRect(xOffset, 0, boardSize, bigGridThick)
        --render_drawRect(xOffset + boardSize - bigGridThick - 1, 0, bigGridThick, boardSize)
        --render_drawRect(xOffset, boardSize - bigGridThick - 1, boardSize, bigGridThick)
        --render_drawRect(xOffset, 0, bigGridThick, boardSize)
        drawRectOutlineThickness(xOffset, 0, boardSize, boardSize, bigGridThick)
        
        render_drawRect(xOffset + bigDiff - bigGridThick2, 0, bigGridThick, boardSize)
        render_drawRect(xOffset + bigDiff * 2 - bigGridThick2, 0, bigGridThick, boardSize)
        
        render_drawRect(xOffset, bigDiff - bigGridThick2, boardSize, bigGridThick)
        render_drawRect(xOffset, bigDiff * 2 - bigGridThick2, boardSize, bigGridThick)
        
        for x = smallDiff - smallGridThick2 + xOffset, boardSize - smallDiff + xOffset, smallDiff do
            render_drawRect(x, 0, smallGridThick, boardSize)
        end
        
        for y = smallDiff - smallGridThick2, boardSize - smallDiff, smallDiff do
            render_drawRect(xOffset, y, boardSize, smallGridThick)
        end
        
        render.setFont(buttonFont)
        
        -- Draw buttons
        for k, v in ipairs(buttons) do
            drawRectOutlineThickness(v.x, v.y, v.w, v.h, 4)
            render.drawSimpleText(v.x + v.w * 0.5, v.y + v.h * 0.5, v.text, 1, 1)
        end
    end
    
    local function selectNumber(x1, y1, x2, y2, number)
        local time = timer.systime()
        
        local choices = state[x1][y1][x2][y2]
        
        local x = (x1 - 1) * bigDiff + (x2 - 1) * smallDiff - smallerDiff2 + xOffset
        local y = (y1 - 1) * bigDiff + (y2 - 1) * smallDiff + smallerDiff2
        
        local counter = 0
        for i = 1, 9 do
            if choices[i] then
                counter = counter + 1
                x = x + smallerDiff
                if counter == 4 then
                    counter = 1
                    x = x - smallerDiff * 3
                    y = y + smallerDiff
                end
                if i ~= number then
                    choices[i] = false
                    -- Spawn falling number
                    table_insert(fallingTiles, {x * 0.5, y * 0.5, math_rand(-maxSideVel, maxSideVel), vertVel, 0, math_rand(-maxAngVel, maxAngVel), i, time})
                end
            end
        end
        
        -- Propogate change
        for x1a = 1, 3 do
            for x2a = 1, 3 do
                if x1a ~= x1 and state[x1a][y1][x2a][y2][number] then
                    --  Pop off
                    table_insert(popQueue, {x1a, y1, x2a, y2, number})
                end
            end
        end
        
        for y1a = 1, 3 do
            for y2a = 1, 3 do
                if y1a ~= y1 and state[x1][y1a][x2][y2a][number] then
                    --  Pop off
                    table_insert(popQueue, {x1, y1a, x2, y2a, number})
                end
            end
        end
        
        for x2a = 1, 3 do
            for y2a = 1, 3 do
                if (x2a ~= x2 or y2a ~= y2) and state[x1][y1][x2a][y2a][number] then
                    -- Pop off
                    table_insert(popQueue, {x1, y1, x2a, y2a, number})
                end
            end
        end
        
        redrawQueued = true
        lastPopTime = timer.curtime()
    end
    
    local function solveOnce()
        solvingOnce = false
        
        -- Select a tile to set
        local smallestAmt = 9
        local smallestSet = {}
    
        for x1 = 1, 3 do
            for y1 = 1, 3 do
                -- Big grid
                for x2 = 1, 3 do
                    for y2 = 1, 3 do
                        -- Small grid
                        local count = 0
                        
                        for k, v in ipairs(state[x1][y1][x2][y2]) do
                            if v then
                                count = count + 1
                                if count > smallestAmt then
                                    break
                                end
                            end
                        end
                        
                        if count > 1 then
                            if count < smallestAmt then
                                smallestAmt = count
                                smallestSet = {{x1, y1, x2, y2}}
                            elseif count <= smallestAmt then
                                table_insert(smallestSet, {x1, y1, x2, y2})
                            end
                        end
                    end
                end
            end
        end
        
        local count = #smallestSet
        if count > 0 then
            -- Found a set of tiles
            local coords = smallestSet[math.random(1, count)]
            local stateChoices = state[coords[1]][coords[2]][coords[3]][coords[4]]
            
            --local choice = math.random(1, smallestAmt)
            local choice = 1
        
            local counter = 0
            for i = 1, 9 do
                if stateChoices[i] then
                    counter = counter + 1
                    if counter == choice then
                        selectNumber(coords[1], coords[2], coords[3], coords[4], i)
                        break
                    end
                end
            end
            
            return true
        end
        
        return false
    end
    
    local function pop()
        local count = #popQueue
        if count > 0 then
            local curtime = timer.curtime()
            local systime = timer.systime()
            if curtime > lastPopTime + popInterval then
                while count > 0 and curtime > lastPopTime + popInterval do
                    -- Pop
                    local index = math.random(1, count)
                    local data = popQueue[index]
                    local stateChoices = state[data[1]][data[2]][data[3]][data[4]]
                    
                    if stateChoices[data[5]] then
                        local x = (data[1] - 1) * bigDiff + (data[3] - 1) * smallDiff - smallerDiff2 + xOffset
                        local y = (data[2] - 1) * bigDiff + (data[4] - 1) * smallDiff + smallerDiff2
                    
                        local counter = 0
                        for i = 1, data[5] do
                            if stateChoices[i] then
                                counter = counter + 1
                                x = x + smallerDiff
                                if counter == 4 then
                                    counter = 1
                                    x = x - smallerDiff * 3
                                    y = y + smallerDiff
                                end
                            end
                        end
                    
                        counter = 0
                        for i = 1, 9 do
                            if stateChoices[i] then
                                counter = counter + 1
                            end
                        end
                    
                        if counter <= 1 then
                            print("ERROR")
                        end
                        stateChoices[data[5]] = false
                        table_insert(fallingTiles, {x * 0.5, y * 0.5, math_rand(-maxSideVel, maxSideVel), vertVel, 0, math_rand(-maxAngVel, maxAngVel), data[5], systime})
                        lastPopTime = lastPopTime + popInterval
                    end
                    table_remove(popQueue, index)
                    count = count - 1
                end
                redrawQueued = true
            end
            
            return true
        end
        
        return false
    end
    
    local solveFull = corlib.wrap(function()
        while #popQueue > 0 do coroutine.yield() end
        while solveOnce() do
            while #popQueue > 0 do coroutine.yield() end
        end
        while #popQueue > 0 do coroutine.yield() end
        solving = false
        return true
    end)

    local init = false
    hook.add("renderoffscreen", "", function()
        if not init then
            init = true
            
            -- Draw numbers
            render.selectRenderTarget("numbers")
            render.clear(Color(0, 0, 0, 0))
            render.setRGBA(255, 255, 255, 255)
            render.setFont(render.createFont("coolvetica", 1024 / 3 * 0.9, nil, true))
            local i = 0
            local diff = 1024 / 3
            for y = diff * 0.5, diff * 2.5, diff do
                for x = diff * 0.5, diff * 2.5, diff do
                    i = i + 1
                    render.drawSimpleText(x, y, tostring(i), 1, 1)
                end
            end
            
            redrawQueued = true
        end
        
        if solving then
            solveFull()
        end
        
        if not pop() and solvingOnce then
            solveOnce()
        end
        
        if redrawQueued then
            drawBoard()
        end
    end)

    --[[hook.add("renderoffscreen", "", function()
        render.selectRenderTarget("")
        
    end)]]
    
    local maxCPU = math.min(0.004, quotaMax() * 0.75)
    if player() == owner() then
        maxCPU = quotaMax() * 0.75
    end
    local fallingNumberIndex = 1
    
    local function drawFallingNumbers()
        render.setRenderTargetTexture("numbers")
        render.setRGBA(255, 0, 0, 255)
        local maxy = 512 + 512 / 27 * 2
        local size = 512 / 27
        --local ftime = timer.frametime()
        --local grav = gravity * ftime
        local systime = timer.systime()
        
        local count = #fallingTiles
        
        for j = 1, count do
            if quotaAverage() > maxCPU then return end
            
            local particle = fallingTiles[fallingNumberIndex]
            if not particle then continue end
            local ftime = systime - particle[8]
            particle[4] = particle[4] + gravity * ftime
            particle[2] = particle[2] + particle[4] * ftime
            
            if particle[2] > maxy then
                -- Delete since offscreen
                table_remove(fallingTiles, fallingNumberIndex)
                count = count - 1
            else
                -- Simulate
                particle[8] = systime
                particle[1] = particle[1] + particle[3] * ftime
                particle[5] = particle[5] + particle[6] * ftime
                renderNumber(particle[7], particle[1], particle[2], size, size, particle[5])
                fallingNumberIndex = fallingNumberIndex % count + 1
            end
        end
    end
    
    local cursorx, cursory
    local screenEntity
    hook.add("render", "", function()
        screenEntity = render.getScreenEntity()
        render.setRenderTargetTexture("main")
        render.drawTexturedRect(0, 0, 512, 512)
        
        cursorx, cursory = render.cursorPos()
        if cursorx and cursory then
            cursorx = cursorx * 2
            cursory = cursory * 2
            if cursorx >= xOffset and cursorx < xOffset + boardSize and
                cursory >= 0 and cursory < boardSize then
                -- Looking at board
                local xb = cursorx - xOffset
                local x1 = math_floor(xb / bigDiff) + 1
                local y1 = math_floor(cursory / bigDiff) + 1
                local x2 = math_floor((xb % bigDiff) / smallDiff) + 1
                local y2 = math_floor((cursory % bigDiff) / smallDiff) + 1
                
                --print(x1, ",", y1, " ", x2, ",", y2)
                
                local x = (x1 - 1) * bigDiff + (x2 - 1) * smallDiff - smallerDiff + xOffset
                local y = (y1 - 1) * bigDiff + (y2 - 1) * smallDiff
                
                local stateChoices = state[x1][y1][x2][y2]
                local counter = 0
                local found = false
                local count = 0
                
                for j = 1, 9 do
                    if stateChoices[j] then
                        count = count + 1
                        if count > 1 then
                            
                            for i = 1, 9 do
                                if stateChoices[i] then
                                    count = count + 1
                                    counter = counter + 1
                                    x = x + smallerDiff
                                    if counter == 4 then
                                        counter = 1
                                        x = x - smallerDiff * 3
                                        y = y + smallerDiff
                                    end
                                end
                                
                                if cursorx >= x and cursorx < x + smallerDiff and
                                    cursory >= y and cursory < y + smallerDiff then
                                    -- Highlight small number
                                    found = true
                                    render.setRGBA(255, 0, 0, 255)
                                    drawRectOutlineThickness(x * 0.5, y * 0.5, smallerDiff * 0.5, smallerDiff * 0.5, 1)
                                    break
                                end
                            end
                            
                            break
                        end
                    end
                end
                
                if count <= 1 or not found then
                    -- Highlight tile
                    render.setRGBA(255, 0, 0, 255)
                    drawRectOutlineThickness(
                        ((x1 - 1) * bigDiff + (x2 - 1) * smallDiff + xOffset) * 0.5,
                        ((y1 - 1) * bigDiff + (y2 - 1) * smallDiff) * 0.5,
                        smallDiff * 0.5, smallDiff * 0.5, 1)
                end
            else
                -- Not looking at board
                -- Check for buttons
                for k, v in ipairs(buttons) do
                    if cursorx >= v.x and cursorx < v.x + v.w and
                        cursory >= v.y and cursory < v.y + v.h then
                        -- Looking at button
                        render.setRGBA(255, 0, 0, 255)
                        drawRectOutlineThickness(v.x * 0.5, v.y * 0.5, v.w * 0.5, v.h * 0.5, 2)
                    end
                end
            end
        end
        
        drawFallingNumbers()
        --renderNumber(math_floor(((timer.curtime() * 2) % 9) + 1), 256, 256, 400, 400, timer.curtime() * 5)
    end)
    
    hook.add("KeyPress", "", function(ply, key)
        if ply ~= player() or
            key ~= IN_KEY.USE or
            player():getEyeTrace().Entity ~= screenEntity then return end
        -- Pressed use on the screen
        if cursorx and cursory then
            if cursorx >= xOffset and cursorx < xOffset + boardSize and
                cursory >= 0 and cursory < boardSize then
                -- Looking at board
                local xb = cursorx - xOffset
                local x1 = math_floor(xb / bigDiff) + 1
                local y1 = math_floor(cursory / bigDiff) + 1
                local x2 = math_floor((xb % bigDiff) / smallDiff) + 1
                local y2 = math_floor((cursory % bigDiff) / smallDiff) + 1
                
                local x = (x1 - 1) * bigDiff + (x2 - 1) * smallDiff - smallerDiff + xOffset
                local y = (y1 - 1) * bigDiff + (y2 - 1) * smallDiff
                
                local stateChoices = state[x1][y1][x2][y2]
                local count = 0
                local counter = 0
                for k, v in ipairs(stateChoices) do
                    if v then
                        count = count + 1
                        if count > 1 then
                            
                            for i = 1, 9 do
                                if stateChoices[i] then
                                    counter = counter + 1
                                    x = x + smallerDiff
                                    if counter == 4 then
                                        counter = 1
                                        x = x - smallerDiff * 3
                                        y = y + smallerDiff
                                    end
                                end
                    
                                if cursorx >= x and cursorx < x + smallerDiff and
                                    cursory >= y and cursory < y + smallerDiff then
                                    -- Select small number
                                    if #popQueue == 0 then
                                        selectNumber(x1, y1, x2, y2, i)
                                    end
                                    break
                                end
                            end
                            
                            break
                        end
                    end
                end
            else
                -- Not looking at board
                -- Check for buttons
                for k, v in ipairs(buttons) do
                    if cursorx >= v.x and cursorx < v.x + v.w and
                        cursory >= v.y and cursory < v.y + v.h then
                        -- Press button
                        v.run()
                    end
                end
            end
        end
    end)
    
    local hButtons = (1024 - boardSize) * 0.9
    local yButtons = (1024 - boardSize - hButtons) / 2 + boardSize
    local wButtons = 1024 / 3 * 0.9
    
    buttonFont = render.createFont("coolvetica", hButtons * 0.9, nil, true)
    
    buttons = {
        {
            x = 0,
            y = yButtons,
            w = wButtons,
            h = hButtons,
            text = "Step",
            run = function() solvingOnce = true end
        },
        {
            x = 1024 / 2 - wButtons / 2,
            y = yButtons,
            w = wButtons,
            h = hButtons,
            text = "Solve",
            run = function() solving = true end
        },
        {
            x = 1023 - wButtons,
            y = yButtons,
            w = wButtons,
            h = hButtons,
            text = "Reset",
            run = reset
        }
    }
end