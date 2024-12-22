-- This is an interpreter for the esolang "AsciiDots". This video explains it well: https://www.youtube.com/watch?v=2BvBk-WHHZQ
-- Connect to screen
-- Read Dumping Grounds\asciidots\files\README.md and don't forget about the files

--@name AsciiDots
--@author Jacbo
--@shared
--@include funcs.txt
--@include better_coroutines.txt
--@include asciidots/asciidots_movements.txt

local file = "asciidots/counter.txt"

require("funcs.txt")
local bcor = require("better_coroutines.txt")

if SERVER then
    funcs.linkToClosestScreen()
elseif player() == owner() then--CLIENT
    --render.createFont(string font, number or nil size, number or nil weight, boolean or nil antialias, boolean or nil additive, boolean or nil shadow, boolean or nil outline, boolean or nil blur, boolean or nil extended)
    local maxQuota = math.min(0.004, quotaMax() * 0.75)
    local gridZoom = 10
    local gridOffset = {0, 0}
    local gridSize = {492, 350}
    local gridPos = {10, 10}
    local grid = {{}}
    local gridMax = {0,0}
    local gridMin = {0,0}
    local shrinkingGrid = {false, false, false, false}
    local fonts = {}
    local needsToAutoZoom = false
    local needsToSetFontRT = false
    local minZoom = 9.6/(0.9*2)
    local pi = math.pi
    local halfPi = pi * 0.5
    local pi2 = pi * 2
    local cos = math.cos
    local sin = math.sin
    local needsToRedrawGrid = true
    local lastTimeStep = timer.curtime()
    --local consoleSize = {492, 132}
    local consoleSize = {492, 125}
    local consolePos = {10, 370}
    local consoleFontSize = 30
    local consoleOutput = {{Color(0,0,0), ""}}
    local consoleMaxLines = math.ceil(consoleSize[2] * 2 * math.max(consoleSize[1], consoleSize[2]) / 512 / consoleFontSize + 1)
    local needToDrawConsole = true
    local consoleTextOffset = math.max(consoleSize[1], consoleSize[2]) * 0.01
    local highlightCells = {}
    
    local trackWidthMult = 0.25
    local killOnError = false
    local tickInterval = 0.05
    local dotID = 0
    --{dot = {id, val, x, y, dir, offsetx, offsety}}
    local dots = {}
    
    --1 = x-, 2 = y-, 3 = x+, 4 = y+
    local movements = require("asciidots/asciidots_movements.txt")
    
    render.createRenderTarget("grid")
    render.createRenderTarget("circle")
    render.createRenderTarget("console")
    --render.createRenderTarget("curve")
    
    local function getGrid(x, y)
        local col = grid[x]
        if col then
            return col[y]
        end
        return nil
    end
    
    local function updateFont()
        local size = math.round(gridZoom * 0.9)
        local font = fonts[size]
        if not font then
            font = render.createFont("consolas", size)
            fonts[size] = font
        end
        render.setFont(font)
        needsToSetFontRT = true
    end
    
    local function updateFontRT(size)
        if not size then
            size = math.round(gridZoom * 0.9 * 2)
        end
        local font = fonts[size]
        if not font then
            font = render.createFont("consolas", size)
            fonts[size] = font
        end
        render.setFont(font)
    end
    
    local function drawConsole()
        --Draws console to screen
        render.setRenderTargetTexture("console")
        local size = math.max(consoleSize[1], consoleSize[2])
        render.drawTexturedRect(consolePos[1], consolePos[2] - size + consoleSize[2], size, size)
    end
    
    local function drawToConsole()
        --Draws text to console
        render.selectRenderTarget("console")
        render.clear(Color(255,255,255))
        updateFontRT(consoleFontSize)
        needToDrawConsole = false
        local ystart
        if #consoleOutput >= consoleMaxLines then
            ystart = 1024 - consoleTextOffset - consoleMaxLines * consoleFontSize
        else
            ystart = 1024 - consoleTextOffset - consoleSize[2] * 2
        end
        for i, line in ipairs(consoleOutput) do
            --local y = 1024 - consoleTextOffset - (i - 2 + consoleMaxLines - #consoleOutput) * consoleFontSize
            local y = ystart + (#consoleOutput - i + 1) * consoleFontSize
            render.setColor(line[1])
            render.drawSimpleText(consoleTextOffset, y, line[2], 0, 4)
        end
    end
    
    local function printToConsole(text, color, newLine)
        if newLine == nil and color ~= nil and type(color) ~= "Color" then
            newLine = color
            color = Color(0,0,0)
        end
        if newLine ~= false then newLine = true end
        consoleOutput[1][1] = color or Color(0,0,0)
        consoleOutput[1][2] = consoleOutput[1][2] .. (text or "nil")
        if newLine then
            table.insert(consoleOutput, 1, {Color(0,0,0), ""})
        end
        if #consoleOutput > consoleMaxLines then
            table.remove(consoleOutput)
        end
        needToDrawConsole = true
    end
    
    --[[for i = 1, 20 do
        printToConsole(i)
    end]]
    
    local function autoZoom(x, y)
        local xcells, ycells
        if x and y then
            xcells = math.max(gridMax[1], x) - math.min(gridMin[1], x)
            ycells = math.max(gridMax[2], y) - math.min(gridMin[2], y)
        else
            xcells = gridMax[1] - gridMin[1] + 1
            ycells = gridMax[2] - gridMin[2] + 1
        end
        gridOffset[1] = gridMin[1]
        gridOffset[2] = gridMin[2]
        local newZoom = math.max(math.min(gridSize[1] / xcells, gridSize[2] / ycells), minZoom)
        if gridZoom ~= newZoom then
            gridZoom = newZoom
            updateFont()
            needsToRedrawGrid = true
        end
    end
    
    local function fullShrink()
        shrinkingGrid[1] = true
        shrinkingGrid[2] = true
        shrinkingGrid[3] = true
        shrinkingGrid[4] = true
    end
    
    local findMinx = bcor.wrap(function()
        local oldx
        while gridMin[1] < gridMax[1] do
            local x = gridMin[1]
            local col = grid[x]
            if col then
                for y = gridMin[2], gridMax[2] do
                    if col[y] then
                        return true
                    end
                    if quotaAverage() > maxQuota then
                        oldx = gridMin[1]
                        while quotaAverage() > maxQuota do coroutine.yield() end
                        if oldx ~= gridMin[1] then
                            gridMin[1] = gridMin[1] - 1
                            break
                        end
                    end
                end
            end
            gridMin[1] = gridMin[1] + 1
        end
        return true
    end)
    
    local findMiny = bcor.wrap(function()
        local oldy
        while gridMin[2] < gridMax[2] do
            local y = gridMin[2]
            for x = gridMin[1], gridMax[1] do
                if getGrid(x, y) then
                    return true
                end
                if quotaAverage() > maxQuota then
                    oldy = gridMin[2]
                    while quotaAverage() > maxQuota do coroutine.yield() end
                    if oldy ~= gridMin[2] then
                        gridMin[2] = gridMin[2] - 1
                        break
                    end
                end
            end
            gridMin[2] = gridMin[2] + 1
        end
        return true
    end)
    
    local findMaxx = bcor.wrap(function()
        local oldx
        while gridMin[1] < gridMax[1] do
            local x = gridMax[1]
            local col = grid[x]
            if col then
                for y = gridMin[2], gridMax[2] do
                    if col[y] then
                        return true
                    end
                    if quotaAverage() > maxQuota then
                        oldx = gridMax[1]
                        while quotaAverage() > maxQuota do coroutine.yield() end
                        if oldx ~= gridMax[1] then
                            gridMax[1] = gridMax[1] + 1
                            break
                        end
                    end
                end
            end
            gridMax[1] = gridMax[1] - 1
        end
        return true
    end)
    
    local findMaxy = bcor.wrap(function()
        local oldy
        while gridMin[2] < gridMax[2] do
            local y = gridMax[2]
            for x = gridMin[1], gridMax[1] do
                if getGrid(x, y) then
                    return true
                end
                if quotaAverage() > maxQuota then
                    oldy = gridMax[2]
                    while quotaAverage() > maxQuota do coroutine.yield() end
                    if oldy ~= gridMax[2] then
                        gridMax[2] = gridMax[2] + 1
                        break
                    end
                end
            end
            gridMax[2] = gridMax[2] - 1
        end
        return true
    end)
    
    local function addCell(x, y, char)
        if not grid[x] then
            grid[x] = {}
        end
        grid[x][y] = char
        if x <= gridMin[1] then
            shrinkingGrid[1] = false
            findMinx:restart()
            gridMin[1] = x
        end
        if y <= gridMin[2] then
            shrinkingGrid[2] = false
            findMiny:restart()
            gridMin[2] = y
        end
        if x >= gridMax[1] then
            shrinkingGrid[3] = false
            findMaxx:restart()
            gridMax[1] = x
        end
        if y >= gridMax[2] then
            shrinkingGrid[4] = false
            findMaxy:restart()
            gridMax[2] = y
        end
        --[[gridMax[1] = math.max(gridMax[1], x)
        gridMax[2] = math.max(gridMax[2], y)
        gridMin[1] = math.min(gridMin[1], x)
        gridMin[2] = math.min(gridMin[2], x)]]
        needsToAutoZoom = true
    end

    hook.add("think", "", function()
        if shrinkingGrid[1] then
            if findMinx() == true then
                shrinkingGrid[1] = false
            end
        elseif shrinkingGrid[2] then
            if findMiny() == true then
                shrinkingGrid[2] = false
            end
        elseif shrinkingGrid[3] then
            if findMaxx() == true then
                shrinkingGrid[3] = false
            end
        elseif shrinkingGrid[4] then
            if findMaxy() == true then
                shrinkingGrid[4] = false
            end
        else
            needsToAutoZoom = true
        end
    end)
    
    local function removeCell(x, y, cb)
        if grid[x] then
            grid[x][y] = nil
            if x == gridMin[1] then
                shrinkingGrid[1] = true
            end
            if y == gridMin[2] then
                shrinkingGrid[2] = true
            end
            if x == gridMax[1] then
                shrinkingGrid[3] = true
            end
            if y == gridMax[2] then
                shrinkingGrid[4] = true
            end
        end
    end
    
    local function drawUI()
        render.setRGBA(140,140,140,255)
        render.drawRect(0, 0, 512, gridPos[2])
        render.drawRect(0, gridPos[2], gridPos[1], 512 - gridPos[2])
        render.drawRect(gridPos[1] + gridSize[1], gridPos[2], 512 - gridPos[1], 512 - gridPos[2])
        render.drawRect(0, gridPos[2] + gridSize[2], 512, 10)
        render.drawRect(0, consolePos[2] + consoleSize[2], 512, 512 - consolePos[2] - consoleSize[2])
        render.setRGBA(255,255,255,255)
        render.drawRectOutline(0,0,512,512)
        render.setRGBA(100,100,100,255)
        render.drawRectOutline(gridPos[1], gridPos[2], gridSize[1], gridSize[2])
        render.drawRectOutline(consolePos[1], consolePos[2], consoleSize[1], consoleSize[2])
    end
        
    local function drawGrid()
        for _, cell in ipairs(highlightCells) do
            render.setRGBA(255,0,0,255)
            render.drawRect((cell[1] - gridOffset[1]) * gridZoom + gridPos[1], (cell[2] - gridOffset[2]) * gridZoom + gridPos[2], gridZoom, gridZoom)
        end
        render.setRGBA(100,100,100,255)
        local x1 = gridPos[1]
        local x2 = gridPos[1] + gridSize[1] - 1
        local y1 = gridPos[2]
        local y2 = gridPos[2] + gridSize[2] - 1
        for x = gridPos[1] - gridOffset[1] % 1 * gridZoom, gridPos[1] + gridSize[1] - 1, gridZoom do
            render.drawLine(x, y1, x, y2)
        end
        for y = gridPos[2] - gridOffset[2] % 1 * gridZoom, gridPos[2] + gridSize[2] - 1, gridZoom do
            render.drawLine(x1, y, x2, y)
        end
        render.setRGBA(255,255,255,255)
    end
    
    local function drawGridText()
        render.selectRenderTarget("grid")
        render.clear(Color(0,0,0,0))
        local doubleGridZoom = gridZoom * 2
        local xadd = gridZoom + gridPos[1] * 2
        local yadd = gridZoom + gridPos[2] * 2
        for x = gridMin[1], gridMax[1] do
            local col = grid[x]
            if col then
                for y = gridMin[2], gridMax[2] do
                    local char = col[y]
                    if char then
                        render.drawSimpleText((x - gridOffset[1]) * doubleGridZoom + xadd, (y - gridOffset[2]) * doubleGridZoom + yadd, char, 1, 1)
                    end
                end
            end
        end
    end
    
    local function load(fileName)
        local data = file.read(fileName)
        if data then
            local x = 1
            local y = 1
            for i = 1, #data do
                local char = string.getChar(data, i)
                if char == "\n" then
                    x = 1
                    y = y + 1
                else
                    addCell(x, y, char)
                    x = x + 1
                end
            end
            needsToAutoZoom = true
        else
            --File not found
            print("Error: file not found")
        end
    end

    local init = true

    hook.add("renderoffscreen", "", function()
        if init then
            init = false
            render.selectRenderTarget("circle")
            render.clear(Color(0,0,0,0))
            funcs.drawCircle(0,0,512,360)
            render.selectRenderTarget("console")
            updateFontRT(consoleFontSize)
            --[[render.selectRenderTarget("curve")
            render.clear(Color(0,0,0,0))
            local radius = 512 + 256 * trackWidthMult
            funcs.drawArc(-radius, -radius, radius, 512 * trackWidthMult, 0, 90*pi/180, 5*pi/180)]]
        end
        if needToDrawConsole then
            drawToConsole()
        end
        if needsToRedrawGrid then
            needsToRedrawGrid = false
            if needsToSetFontRT then
                needsToSetFontRT = false
                updateFontRT()
            end
            --drawGrid()
            render.setRGBA(0,0,0,255)
            drawGridText()
        end
    end)
    
    local j = 34

    hook.add("render", "", function()
        if needsToAutoZoom then
            needsToAutoZoom = false
            autoZoom()
        end
        maxQuota = math.min(0.004, quotaMax() * 0.75)
        drawConsole()
        render.setRGBA(255,255,255,255)
        render.drawRect(gridPos[1], gridPos[2], gridSize[1], gridSize[2])
        drawGrid()
        drawUI()
        if #dots ~= 0 then
            --Draw dots
            local dotSize = gridZoom * 0.5
            local halfDotSize = dotSize * 0.5
            local halfGridZoom = gridZoom * 0.5
            render.setRenderTargetTexture("circle")
            render.setRGBA(0,0,255,255)
            local lerp = math.min(1, (timer.curtime() - lastTimeStep) / tickInterval)
            for _, dot in ipairs(dots) do
                local offsetx, offsety = dot.offset(lerp)
                render.drawTexturedRect(
                    (dot.x + offsetx - gridOffset[1]) * gridZoom - halfDotSize + gridPos[1],
                    (dot.y + offsety - gridOffset[2]) * gridZoom - halfDotSize + gridPos[2],
                    dotSize,
                    dotSize
                )
            end
            render.setRGBA(255,255,255,255)
        end
        render.setRenderTargetTexture("grid")
        render.drawTexturedRect(0, 0, 512, 512)
    end)
    
    local function createDot(x, y, dir, val, offsetFunc)
        table.insert(dots, {
            id = dotID,
            val = val or 0,
            x = x,
            y = y,
            dir = dir,
            offset = offsetFunc or function() return 0.5, 0.5 end,
            isSettingVal = false,
            isSettingID = false,
            newID = 0,
            isCreatingPrint = false,
            printValue = nil,
            printNewLine = true,
            printToAscii = false,
            printingString = false,
            justStartedWaiting = false
        })
        dotID = dotID + 1
    end
    
    local function stopProgram()
        hook.remove("think", "run")
        dots = {}
    end
    
    local function printError(message, killProgram, x, y)
        if x and y then
            table.insert(highlightCells, {x, y})
        end
        printToConsole(message or "Error", Color(255,0,0))
        if killProgram == true or killProgram == nil then
            printToConsole("Program terminated", Color(255,0,0))
            stopProgram()
        end
    end
    
    local function dotCanMoveHere(char, dir)
        if char then
            local set = movements[char]
            if set then
                return set[2][dir]
            end
        end
        return nil
    end
    
    local function startProgram()
        --Initialize program
        local dotMoveSet = movements["."][1]
        local crossMoveSet = movements.crossing
        local curveMoveSet = movements.curves
    
        highlightCells = {}
        printToConsole("Started program...", Color(15, 209, 37))
        lastTimeStep = timer.curtime()
        
        local warps = {}
        
        local opSymbols = {
            ["*"] = function(a, b) return a * b end,
            ["/"] = function(a, b) return a / b end,
            ["+"] = function(a, b) return a + b end,
            ["-"] = function(a, b) return a - b end,
            ["%"] = function(a, b) return a % b end,
            ["^"] = function(a, b) return a ^ b end,
            ["&"] = function(a, b) return (a ~= 0 and b ~= 0) and 1 or 0 end, --and
            ["o"] = function(a, b) return (a ~= 0 or b ~= 0) and 1 or 0 end, --or
            ["x"] = function(a, b) return ((a ~= 0 and b == 0) or (a == 0 and b ~= 0)) and 1 or 0 end, --xor
            [">"] = function(a, b) return a > b and 1 or 0 end,
            ["G"] = function(a, b) return a >= b and 1 or 0 end,
            ["<"] = function(a, b) return a < b and 1 or 0 end,
            ["L"] = function(a, b) return a <= b and 1 or 0 end,
            ["="] = function(a, b) return a == b and 1 or 0 end,
            ["!"] = function(a, b) return a ~= b and 1 or 0 end
        }
        --{[x][y] = {char, {horizontalDot}, {verticalDot}, {dir}, exitVertically, function}}
        local operations = {}
        local function getOperation(x, y)
            local col = operations[x]
            if col then
                return col[y]
            end
        end
        --Find . and operations
        for x=gridMin[1], gridMax[1] do
            local col = grid[x]
            if col then
                local opCol0 = operations[x - 1]
                local opCol1 = operations[x]
                local opCol2 = operations[x + 1]
                for y=gridMin[2], gridMax[2] do
                    local char = col[y]
                    if char then
                        if char == "." then
                            --Place dot(s) here
                            local char2 = getGrid(x-1, y)
                            if char2 and dotCanMoveHere(char2, 1) then
                                createDot(x, y, 1, 0, dotMoveSet[1])
                            end
                            char2 = getGrid(x, y-1)
                            if char2 and dotCanMoveHere(char2, 2) then
                                createDot(x, y, 2, 0, dotMoveSet[2])
                            end
                            char2 = getGrid(x+1, y)
                            if char2 and dotCanMoveHere(char2, 3) then
                                createDot(x, y, 3, 0, dotMoveSet[3])
                            end
                            char2 = getGrid(x, y+1)
                            if char2 and dotCanMoveHere(char2, 4) then
                                createDot(x, y, 4, 0, dotMoveSet[4])
                            end
                        elseif char == "%" and getGrid(x+1, y) == "$" then
                            --Define a warp
                            local char2 = getGrid(x+2, y)
                            if char2 then
                                warps[char2] = {{x+2, y}}
                            end
                        elseif char == "~" then
                            if not opCol1 then
                                operations[x] = {}
                                opCol1 = operations[x]
                            end
                            if getGrid(x, y+1) == "!" then
                                opCol1[y] = {"!~", {}, {}, {}}
                                if not opCol1[y+1] then
                                    opCol1[y+1] = {"dir", 2, 2}
                                end
                            else
                                opCol1[y] = {"~", {}, {}, {}}
                            end
                        else
                            local isOp = false
                            local op = opSymbols[char]
                            if op then
                                local left = getGrid(x-1, y)
                                local right = getGrid(x+1, y)
                                if (left == "[" and right == "]") or (left == "{" and right == "}") then
                                    --Init ops
                                    if not opCol0 then
                                        operations[x - 1] = {}
                                        opCol0 = operations[x - 1]
                                    end
                                    if not opCol1 then
                                        operations[x] = {}
                                        opCol1 = operations[x]
                                    end
                                    if not opCol2 then
                                        operations[x + 1] = {}
                                        opCol2 = operations[x + 1]
                                    end
                                    opCol0[y] = {"hor"}
                                    opCol2[y] = {"hor"}
                                    if left == "[" then
                                        opCol1[y] = {char, {}, {}, {}, true, function(a, b) return op(b, a) end}
                                    else
                                        opCol1[y] = {char, {}, {}, {}, false, op}
                                    end
                                    isOp = true
                                end
                            end
                            
                            local warp = warps[char]
                            if not isOp and warp then
                                if #warp <= 2 then
                                    if warp[1][1] == x and warp[1][2] == y then
                                        print("a")
                                        table.remove(warp, 1)
                                    elseif #warp < 2 then
                                        table.insert(warp, {x, y})
                                    else
                                        printError("Error: Cannot create more than 2 warps: " .. x .. "," .. y, killOnError, x, y)
                                    end
                                else
                                    printError("Error: Cannot create more than 2 warps: " .. x .. "," .. y, killOnError, x, y)
                                end
                            end
                        end
                    end
                end
            end
        end
        
        for key, warp in pairs(warps) do
            if #warp ~= 2 then
                warps[key] = nil
            end
        end
        
        local numbers = {["0"] = 0, ["1"] = 1, ["2"] = 2, ["3"] = 3, ["4"] = 4, ["5"] = 5, ["6"] = 6, ["7"] = 7, ["8"] = 8, ["9"] = 9}
        local entryDirStrings = {"from the right", "from below", "from the left", "from above"}
        local entryOffsets = {{1, 0.5}, {0.5, 1}, {0, 0.5}, {0.5, 0}}
        local exitOffsets = {{0, 0.5}, {0.5, 0}, {1, 0.5}, {0.5, 1}}
        local tick = 0
        --{{{x,y}, val, dir, dot}}
        --local inputQueue = {}
        --{{inputs}
        --local inputResultQueue = {}
        
        hook.add("think", "run", function()
            --Run program
            while timer.curtime() - tickInterval + timer.frametime() >= lastTimeStep do
                lastTimeStep = lastTimeStep + tickInterval
                tick = tick + 1
                local i = 1
                local count = #dots
                while i <= count do
                    local dot = dots[i]
                    if dot.dontMoveYet == tick then
                        dot.dontMoveYet = nil
                        i = i + 1
                        continue
                    end
                    local dx, dy
                    local dir = dot.dir
                    if dir == -1 then
                        --Wait
                        dot.offset = function() return 0.5, 0.5 end
                        dot.justStartedWaiting = false
                        i = i + 1
                        continue
                    elseif dir == 0 then
                        --Delete dot
                        table.remove(dots, i)
                        count = count - 1
                        continue
                    elseif dir == 1 then
                        dx = -1
                        dy = 0
                    elseif dir == 2 then
                        dx = 0
                        dy = -1
                    elseif dir == 3 then
                        dx = 1
                        dy = 0
                    elseif dir == 4 then
                        dx = 0
                        dy = 1
                    end
                    local x = dot.x + dx
                    local y = dot.y + dy
                    dot.x = x
                    dot.y = y
                    local char = getGrid(x, y)
                    if char and char ~= "." then
                        if (char == ":" and (dot.isSettingID and dot.id or dot.val) == 0) or (char == ";" and (dot.isSettingID and dot.id or dot.val) == 1) then
                            dot.dir = 0
                            dot.offset = movements.ends[dir]
                            i = i + 1
                            continue
                        end
                    
                        local opCol = operations[x]
                        local op = nil
                        if opCol then op = opCol[y] end
                        
                        
                        if dot.isSettingVal then
                            --Set value
                            local num = numbers[char]
                            if num then
                                if dot.val then
                                    dot.val = dot.val * 10 + num
                                else
                                    dot.val = num
                                end
                                i = i + 1
                                continue
                            else
                                dot.isSettingVal = false
                            end
                        end
                        
                        if dot.isSettingID then
                            --Set ID
                            local num = numbers[char]
                            if num then
                                if dot.newID then
                                    dot.newID = dot.newID * 10 + num
                                else
                                    dot.newID = num
                                end
                                i = i + 1
                                continue
                            else
                                if not(not dot.newID and op and char ~= "~" and not(char == "!" and op[1] == "dir")) then
                                    dot.isSettingID = false
                                    if not dot.newID then
                                        printError("Error: Dot cannot have a nil ID: " .. x .. "," .. y, killOnError, x, y)
                                    end
                                    dot.id = dot.newID
                                end
                            end
                        end
                        
                        if dot.isCreatingPrint then
                            --Create print
                            if dot.printToAscii then
                                local num = numbers[char]
                                if num then
                                    if dot.printValue == nil then
                                        dot.printValue = num
                                    else
                                        dot.printValue = dot.printValue * 10 + num
                                    end
                                    i = i + 1
                                    continue
                                elseif dot.printValue == nil then
                                    if char == "#" then
                                        try(function()
                                            printToConsole(string.char(dot.val), dot.printNewLine)
                                        end, function()
                                            printError("Error: Cannot convert \'" .. (dot.val or "nil") .. "\' to character: " .. x .. "," .. y, killOnError, x, y)
                                        end)
                                    elseif char == "@" then
                                        try(function()
                                            printToConsole(string.char(dot.id), dot.printNewLine)
                                        end, function()
                                            printError("Error: Cannot convert \'" .. (dot.id or "nil") .. "\' to character: " .. x .. "," .. y, killOnError, x, y)
                                        end)
                                    else
                                        printError("Error: Cannot convert nil to character: " .. x .. "," .. y, killOnError, x, y)
                                    end
                                    dot.isCreatingPrint = false
                                else
                                    try(function()
                                        printToConsole(string.char(dot.printValue), dot.printNewLine)
                                    end, function()
                                        printError("Error: Cannot convert \'" .. (dot.printValue or "nil") .. "\' to character: " .. x .. "," .. y, killOnError, x, y)
                                    end)
                                    dot.isCreatingPrint = false
                                end
                            end
                            if dot.printingString then
                                if char == "\"" or char == "\'" then
                                    printToConsole(dot.printValue, dot.printNewLine)
                                    dot.isCreatingPrint = false
                                end
                                dot.printValue = dot.printValue .. char
                                i = i + 1
                                continue
                            end
                            if dot.printValue == nil then
                                --Cell right after print (unless no new line)
                                if char == "#" then
                                    --Print dot value
                                    printToConsole(dot.val, dot.printNewLine)
                                    dot.isCreatingPrint = false
                                    i = i + 1
                                    continue
                                elseif char == "@" then
                                    --Print dot id
                                    printToConsole(dot.id, dot.printNewLine)
                                    dot.isCreatingPrint = false
                                    i = i + 1
                                    continue
                                elseif char == "_" then
                                    --No new line
                                    dot.printNewLine = false
                                    i = i + 1
                                    continue
                                elseif char == "a" then
                                    --Convert the number to its ascii char
                                    dot.printToAscii = true
                                    i = i + 1
                                    continue
                                elseif char == "\"" or char == "\'" then
                                    --Print string
                                    dot.printValue = ""
                                    if dot.printingString then
                                        --Empty string
                                        if dot.printNewLine then
                                            printToConsole("", dot.printNewLine)
                                        end
                                        dot.isCreatingPrint = false
                                    else
                                        dot.printingString = true
                                    end
                                    i = i + 1
                                    continue
                                end
                            end
                        end
                        
                        --Operations
                        if op then
                            local opChar = op[1]
                            if opChar == "hor" then
                                --Horizontal movement
                                if dir == 2 or dir == 4 then
                                    printError("Error: Dot cannot enter \'" .. char .. "\' " .. (entryDirStrings[dir] or "nil") .. ": " .. x .. "," .. y, killOnError, x, y)
                                    table.remove(dots, i)
                                    count = count - 1
                                    continue
                                end
                                dot.offset = curveMoveSet[dir][dir]
                            elseif opChar == "dir" then
                                --Simple direction
                                if dir == op[2] then
                                    dot.offset = curveMoveSet[dir][op[3]]
                                    dot.dir = op[3]
                                else
                                    printError("Error: Dot cannot enter \'" .. char .. "\' " .. (entryDirStrings[dir] or "nil") .. ": " .. x .. "," .. y, killOnError, x, y)
                                    table.remove(dots, i)
                                    count = count - 1
                                    continue
                                end
                            elseif opChar == "~" or opChar == "!~" then
                                --If statement
                                if dir == 4 then
                                    printError("Error: Dots cannot enter \'~\' from the top: " .. x .. "," .. y, killOnError, x, y)
                                    table.remove(dots, i)
                                    count = count - 1
                                    continue
                                end
                                local hdots = op[2]
                                local vdots = op[3]
                                local hdirs = op[4]
                                if dir == 2 then
                                    table.insert(vdots, dot)
                                else
                                    table.insert(hdots, dot)
                                    table.insert(hdirs, dir)
                                end
                                dot.justStartedWaiting = true
                                dot.offset = movements.ends[dir]
                                dot.dir = -1
                                
                                if #hdots ~= 0 and #vdots ~= 0 then
                                    --Can perform operation
                                    local hdot = hdots[1]
                                    local vdot = vdots[1]
                                    local hdir = hdirs[1]
                                    
                                    local isTrue = false
                                    local exitDir = hdir
                                    if opChar == "~" then
                                        if vdot.val ~= 0 then
                                            isTrue = true
                                            exitDir = 2
                                        end
                                    elseif vdot.val == 0 then
                                        isTrue = true
                                        exitDir = 2
                                    end
                                    
                                    vdot.dir = 0
                                    hdot.dir = exitDir
                                    if hdot.justStartedWaiting then
                                        hdot.offset = curveMoveSet[hdir][exitDir]
                                    else
                                        hdot.dontMoveYet = tick
                                        hdot.offset = dotMoveSet[exitDir]
                                    end
                                    
                                    table.remove(hdots, 1)
                                    table.remove(vdots, 1)
                                    table.remove(hdirs, 1)
                                end
                            else
                                --Operation
                                local hdots = op[2]
                                local vdots = op[3]
                                local dirs = op[4]
                                local exitsVertically = op[5]
                                if dir == 2 or dir == 4 then
                                    --Moving vertically
                                    table.insert(vdots, dot)
                                    if exitsVertically then
                                        table.insert(dirs, dir)
                                    end
                                else
                                    --Moving horizontally
                                    table.insert(hdots, dot)
                                    if not exitsVertically then
                                        table.insert(dirs, dir)
                                    end
                                end
                                dot.justStartedWaiting = true
                                dot.offset = movements.ends[dir]
                                dot.dir = -1
                                
                                if #hdots ~= 0 and #vdots ~= 0 then
                                    --Can perform operation
                                    local hdot = hdots[1]
                                    local vdot = vdots[1]
                                    local dir2 = dirs[1]
                                    local passingDot
                                    local dyingDot
                                    
                                    if exitsVertically then
                                        passingDot = vdot
                                        dyingDot = hdot
                                    else
                                        passingDot = hdot
                                        dyingDot = vdot
                                    end
                                    local result = op[6]((hdot.isSettingID and hdot.id or hdot.val), (vdot.isSettingID and vdot.id or vdot.val))
                                    if passingDot.isSettingID then
                                        passingDot.id = result
                                    else
                                        passingDot.val = result
                                    end
                                    hdot.isSettingID = false
                                    vdot.isSettingID = false
                                    passingDot.dir = dir2
                                    if passingDot.justStartedWaiting then
                                        passingDot.offset = curveMoveSet[dir2][dir2]
                                    else
                                        passingDot.dontMoveYet = tick
                                        passingDot.offset = dotMoveSet[dir2]
                                    end
                                    dyingDot.dir = 0
                                    
                                    table.remove(hdots, 1)
                                    table.remove(vdots, 1)
                                    table.remove(dirs, 1)
                                end
                            end
                            
                            i = i + 1
                            continue
                        end
                        
                        if char == "F" then
                            --Floor
                            dot.val = math.floor(dot.val)
                        elseif char == "C" then
                            --Ceil
                            dot.val = math.ceil(dot.val)
                        elseif char == "R" then
                            --Round
                            dot.val = math.round(dot.val)
                        elseif char == "*" then
                            --Clone
                            local original = true
                            local moveSet = movements.curves[dir]
                            if dir ~= 3 then
                                local char2 = getGrid(x-1, y)
                                if char2 and dotCanMoveHere(char2, 1) then
                                    if original then
                                        original = false
                                        dot.dir = 1
                                        dot.offset = moveSet[1]
                                    else
                                        createDot(x, y, 1, dot.val, moveSet[1])
                                    end
                                end
                            end
                            if dir ~= 4 then
                                local char2 = getGrid(x, y-1)
                                if char2 and dotCanMoveHere(char2, 2) then
                                    if original then
                                        original = false
                                        dot.dir = 2
                                        dot.offset = moveSet[2]
                                    else
                                        createDot(x, y, 2, dot.val, moveSet[2])
                                    end
                                end
                            end
                            if dir ~= 1 then
                                local char2 = getGrid(x+1, y)
                                if char2 and dotCanMoveHere(char2, 3) then
                                    if original then
                                        original = false
                                        dot.dir = 3
                                        dot.offset = moveSet[3]
                                    else
                                        createDot(x, y, 3, dot.val, moveSet[3])
                                    end
                                end
                            end
                            if dir ~= 2 then
                                local char2 = getGrid(x, y+1)
                                if char2 and dotCanMoveHere(char2, 4) then
                                    if original then
                                        original = false
                                        dot.dir = 4
                                        dot.offset = moveSet[4]
                                    else
                                        createDot(x, y, 4, dot.val, moveSet[4])
                                    end
                                end
                            end
                            if not original then
                                i = i + 1
                                continue
                            end
                            printError("Error: \'*\' with no exit path at " .. x .. "," .. y, killOnError, x, y)
                            table.remove(dots, i)
                            count = count - 1
                            continue
                        elseif char == "#" then
                            dot.val = nil
                            dot.isSettingVal = true
                        elseif char == "@" then
                            dot.newID = nil
                            dot.isSettingID = true
                        elseif char == "$" then
                            dot.printValue = nil
                            dot.isCreatingPrint = true
                            dot.printingString = false
                            dot.printNewLine = true
                            dot.printToAscii = false
                        end
                        
                        local moveSet = movements[char]
                        if moveSet then
                            local newDir = moveSet[2][dir]
                            if newDir then
                                dot.dir = newDir
                                dot.offset = moveSet[1][dir]
                                i = i + 1
                                continue
                            end
                        end
                        
                        --Warps
                        local warp = warps[char]
                        if warp then
                            local warped = false
                            if warp[1][1] == x and warp[1][2] == y then
                                --Warp to second
                                dot.x = warp[2][1]
                                dot.y = warp[2][2]
                                warped = true
                            elseif warp[2][1] == x and warp[2][2] == y then
                                --Warp to first
                                dot.x = warp[1][1]
                                dot.y = warp[1][2]
                                warped = true
                            end
                            if warped then
                                offset1 = entryOffsets[dir]
                                offset2 = exitOffsets[dir]
                                local x1 = offset1[1] + x - dot.x
                                local y1 = offset1[2] + y - dot.y
                                local x2 = offset2[1]
                                local y2 = offset2[2]
                                dot.offset = function(lerp) return math.lerp(lerp, x1, x2), math.lerp(lerp, y1, y2) end
                                i = i + 1
                                continue
                            end
                        end
                    end
                    table.insert(highlightCells, {x, y})
                    printError("Error: Invalid char \'" .. (char or "nil") .. "\' at " .. x .. "," .. y, killOnError, x, y)
                    table.remove(dots, i)
                    count = count - 1
                end
            end
            if #dots == 0 then
                stopProgram()
                printToConsole("Program ended", Color(255,0,0))
            end
        end)
    end
    
    load(file)
    
    startProgram()
    
    --{dot = {id, val, x, y, dir, offsetx, offsety}}
    fullShrink()
ends