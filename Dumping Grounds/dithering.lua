-- Connect to screen

--@name Dithering
--@author Jacbo
--@client

local maxCPU = math.min(0.002, quotaMax() * 0.75)
local cornerColors = {}
for i = 1, 4 do
    local color = Color(math.rand(0, 360), 1, 1):hsvToRGB()
    table.insert(cornerColors, Vector(color[1], color[2], color[3]))
end

render.createRenderTarget("")

local size = 8

local draw = coroutine.wrap(function()
    local delta = math.floor(1024 / size)
    local maxCoord = 1024 - size
    for x = 0, maxCoord, size do
        for y = 0, maxCoord, size do
            while quotaAverage() >= maxCPU do
                coroutine.yield()
            end
            local lerpTop = math.lerpVector(x / maxCoord, cornerColors[1], cornerColors[2])
            local lerpBottom = math.lerpVector(x / maxCoord, cornerColors[3], cornerColors[4])
            local lerp = math.lerpVector(y / maxCoord, lerpTop, lerpBottom)
            render.setRGBA(lerp[1], lerp[2], lerp[3], 255)
            render.drawRect(x, y, size, size)
        end
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