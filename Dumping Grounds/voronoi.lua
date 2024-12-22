-- Connect to screen

--@name Voronoi
--@author Jacbo
--@client

render.createRenderTarget("screen")

local gridCount = 8

local points = {}
local gridSize = 1024 / gridCount
local maxCpu = math.min(quotaMax() * 0.9, 0.004)
local changed = true
local startX = 1024
local startY = 1024
for x = 1, gridCount do
    local column = {}
    for y = 1, gridCount do
        table.insert(column, {
            x = (math.rand(0, 1) + x - 1) * gridSize,
            y = (math.rand(0, 1) + y - 1) * gridSize,
            --color = Color(math.rand(0, 360), 0.7, 0.7):hsvToRGB()
            color = Color(0, math.rand(0,1), 1):hsvToRGB(),
            power = math.rand(0.5, 1)
        })
    end
    table.insert(points, column)
end
local x = 0
local y = 0
local power = 2
local rendering = false
local firstChange = false
local bigX = 0
local bigY = 0
local search = 1
local cursorx = 0
local cursory = 0
local using = false
local startedUsingOnSlider = false
local onScreen = false

local minPower = 0
local maxPower = 5
local powerSnap = 0.1
local init = false

local slider = {x = 10, y = 512 - 10 - 80, width = 150, height = 80, min = minPower, max = maxPower, step = powerSnap, raw = power, rounded = power, thickness = 4, fontName = "coolvetica", fontSize = 20, text = "Exponent: ", font = nil}

hook.add("renderoffscreen","",function()
    if not init then
        init = true
        slider.font = render.createFont(slider.fontName, slider.fontSize, 1, 1)
    end
    if changed then
        changed = false
        rendering = true
        startX = x
        startY = y
        firstChange = true
    end
    local xmin = bigX * gridSize
    local xmax
    local ymax
    if bigX == gridCount - 1 then
        xmax = 1024
    else
        xmax = (bigX + 1) * gridSize
    end
    if bigY == gridCount - 1 then
        ymax = 1024
    else
        ymax = (bigY + 1) * gridSize
    end
    if rendering then
        render.selectRenderTarget("screen")
        while firstChange or (x != startX or y != startY) and quotaAverage() <= maxCpu do
            local closestPoint
            local minDist = math.huge
            for gridx = math.max(1, bigX - search + 1), math.min(gridCount, bigX + 1 + search) do
                for gridy = math.max(1, bigY - search + 1), math.min(gridCount, bigY + 1 + search) do
                    local point = points[gridx][gridy]
                    --local dist = math.abs(x - point.x) ^ power + math.abs(y - point.y) ^ power
                    local dist = math.abs(x - point.x) ^ power + math.abs(y - point.y) ^ power
                    if dist < minDist then
                        minDist = dist
                        closestPoint = point
                    end
                end
            end
            render.setColor(closestPoint.color)
            render.drawRect(x, y, 2, 2)
            if firstChange and x == startX and y == startY then
                firstChange = false
            end
            x = x + 2
            if x >= xmax then
                x = xmin
                y = y + 2
                if y >= ymax then
                    bigY = bigY + 1
                    if bigY >= gridCount then
                        bigY = 0
                        bigX = (bigX + 1) % gridCount
                    end
                    y = bigY * gridSize
                    xmin = bigX * gridSize
                    if bigX == gridCount - 1 then
                        xmax = 1024
                    else
                        xmax = (bigX + 1) * gridSize
                    end
                    if bigY == gridCount - 1 then
                        ymax = 1024
                    else
                        ymax = (bigY + 1) * gridSize
                    end
                    x = xmin
                end
            end
        end
        
        if x == startX and y == startY and not firstChange then
            rendering = false
        end
    end
end)

hook.add("render","",function()
    render.setRenderTargetTexture("screen")
    render.drawTexturedRect(0,0,512,512)
    local x1, y1 = render.cursorPos(player(), render.getScreenEntity())
    if x1 and y1 then
        onScreen = true
        cursorx = x1
        cursory = y1
        use = player():keyDown(IN_KEY.USE)
        local overSlider = false
        if use then
            overSlider = cursorx >= slider.x and cursorx < slider.x + slider.width and cursory >= slider.y + slider.fontSize and cursory < slider.y + slider.height
            if not using then
                if overSlider then
                    startedUsingOnSlider = true
                else
                    startedUsingOnSlider = false
                end
            end
            if overSlider or startedUsingOnSlider then
                slider.raw = slider.min + (slider.max - slider.min) * (1 - (slider.x + slider.width - slider.thickness * 1.5 - cursorx) / (slider.width - slider.thickness * 3))
                local rounded = math.clamp(math.round(slider.raw / slider.step) * slider.step, slider.min, slider.max)
                if rounded != slider.rounded then
                    slider.rounded = rounded
                    changed = true
                    power = slider.rounded
                end
            end
        end
        using = use
    else
        onScreen = false
        using = false
    end
    --Draw slider
    render.setRGBA(0,0,0,100)
    render.drawRect(slider.x, slider.y, slider.width, slider.height)
    render.setRGBA(255,255,255,255)
    render.drawRect(slider.x, slider.y + slider.fontSize, slider.thickness, slider.height - slider.fontSize)
    render.drawRect(slider.x + slider.width - slider.thickness, slider.y + slider.fontSize, slider.thickness, slider.height - slider.fontSize)
    render.drawRect(slider.x, slider.y + slider.fontSize + (slider.height - slider.fontSize - slider.thickness) / 2, slider.width, slider.thickness)
    render.drawRect(slider.x + (slider.width - slider.thickness * 3) * (1 - (slider.max - slider.rounded) / (slider.max - slider.min)) + slider.thickness, slider.y + slider.fontSize, slider.thickness, slider.height - slider.fontSize)
    if slider.font then
        render.setRGBA(255,255,255,255)
        render.setFont(slider.font)
        render.drawText(slider.x, slider.y, slider.text .. slider.rounded)
    end
    --Draw cursor
    if onScreen then
        render.setRGBA(255,255,255,255)
        render.setMaterial()
        render.drawPoly({
            {x = cursorx - 5, y = cursory},
            {x = cursorx, y = cursory - 5},
            {x = cursorx + 5, y = cursory},
            {x = cursorx, y = cursory + 5}
        })
    end
end)