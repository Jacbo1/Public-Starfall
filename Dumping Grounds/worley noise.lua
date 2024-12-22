-- Connect to screen

--@name Worley Noise
--@author Jacbo
--@client

local maxCPU = math.min(0.004, quotaMax() * 0.75)
local c1 = Vector()
local c2 = Vector(204, 0, 255)
local c3 = Vector(0, 212, 212)
local rows = 10
local cols = 10
local cellw = 1024 / cols
local cellh = 1024 / rows
local points = {}
for x = 0, cols - 1 do
    local t = {}
    for y = 0, rows - 1 do
        table.insert(t, {
            math.rand(0, cellw) + x * cellw,
            math.rand(0, cellh) + y * cellh
        })
    end
    table.insert(points, t)
end

render.createRenderTarget("")

local floor = math.floor
local max = math.max
local min = math.min
local sqrt = math.sqrt
local lerpVector = math.lerpVector
local setRGBA = render.setRGBA
local drawRect = render.drawRect
local draw = coroutine.wrap(function()
    local maxDist = sqrt(cellw * cellw + cellh * cellh)
    local maxDist2 = 0
    local denom = 1 / 1023
    for i = 1, 2 do
        for y = 0, 1023 do
            for x = 0, 1023 do
                while quotaAverage() >= maxCPU do coroutine.yield() end
                local minDist = 999999
                local cellx = floor(x / cellw)
                local celly = floor(y / cellh)
                for x1 = max(1, cellx), min(cols, cellx + 2) do
                    for y1 = max(1, celly), min(rows, celly + 2) do
                        local x2 = points[x1][y1][1]
                        local y2 = points[x1][y1][2]
                        minDist = min(minDist, (x2 - x)^2 + (y2 - y)^2)
                    end
                end
                minDist = sqrt(minDist)
                maxDist2 = minDist
                col1 = lerpVector(y * denom, c2, c3)
                col2 = lerpVector(min(1, minDist / maxDist), c1, col1)
                setRGBA(col2.x, col2.y, col2.z, 255)
                drawRect(x, y, 1, 1)
            end
        end
        maxDist = maxDist2
    end
    return true
end)

hook.add("renderoffscreen", "", function()
    render.selectRenderTarget("")
    if draw() == true then
        hook.remove("renderoffscreen", "")
    end
end)

hook.add("render", "", function()
    render.setRenderTargetTexture("")
    render.drawTexturedRect(0, 0, 512, 512)
end)