--@name Procedural Texture Drawer
--@author Jacbo
--@client
--@include perlin.txt
--@include procedural_texture_lib.txt

--if player() ~= owner() then return end

require("perlin.txt")
require("procedural_texture_lib.txt")

procText.randomizeSeeds()

local maxQuota = math.min(0.003, quotaMax() * 0.75)

if player() == owner() then
    maxQuota = math.min(0.01, quotaMax() * 0.75)
end

local drawWhiteNoise = coroutine.wrap(function()
    for x = 0, 1023 do
        for y = 0, 1023 do
            while quotaAverage() >= maxQuota do coroutine.yield() end
            local color = procText.whiteNoise(x, y) * 255
            render.setRGBA(color, color, color, 255)
            render.drawRect(x, y, 1, 1)
        end
    end
    return true
end)

local drawBrick = coroutine.wrap(function()
    local pixelSize = 2
    local brickWidth = 150
    local brickHeight = 50
    local borderThickness = 8
    local borderValue = 0
    local minBrickValue = 0.5
    local maxBrickValue = 1
    local rowShift = 0.5
    local randomRowShift = false
    for y = 0, 1023, pixelSize do
        for x = 0, 1023, pixelSize do
            while quotaAverage() >= maxQuota do coroutine.yield() end
            --local color = procText.brick(x, y, brickWidth, brickHeight, rowShift, randomRowShift, borderThickness, borderValue, minBrickValue, maxBrickValue) * 255
            local value = procText.brick(x, y, brickWidth, brickHeight, rowShift, randomRowShift, borderThickness, borderValue, minBrickValue, maxBrickValue)
            local color
            if value == 0 then
                color = Color(200,200,200)
            else
                color = value * Color(191, 82, 46)
            end
            
            --render.setRGBA(color, color, color, 255)
            render.setColor(color)
            render.drawRect(x, y, pixelSize, pixelSize)
        end
    end
    return true
end)

local sunDir = Vector(-1,2,3.75):getNormalized()
local dotStrength = 1

local drawPerlin = coroutine.wrap(function()
    local sizeScale = 1/50
    local pixelSize = 4
    local scale = 0.01
    for x = 0, 1023, pixelSize do
        for y = 0, 1023, pixelSize do
            while quotaAverage() >= maxQuota do coroutine.yield() end
            --local color = (perlin:noise(x * scale, y * scale) + 1) * 127.5
            local c1 = Vector(sizeScale, sizeScale, perlin:noise((x+1) * scale, (y+1) * scale))
            local c2 = Vector(-sizeScale, sizeScale, perlin:noise((x-1) * scale, (y+1) * scale))
            local c3 = Vector(sizeScale, -sizeScale, perlin:noise((x+1) * scale, (y-1) * scale))
            local c4 = Vector(-sizeScale, -sizeScale, perlin:noise((x-1) * scale, (y-1) * scale))
            --[[local normal1 = (c2 - c1):cross(c3 - c1)
            normal1:normalize()
            local normal2 = (c3 - c1):cross(c4 - c1)
            normal2:normalize()
            local normal = (normal1 + normal2) * 0.5]]
            local normal = (c1 - c4):cross(c2 - c3)
            normal:normalize()
            --local color = (normal + Vector(1)) * 127.5
            local color = ((normal:dot(sunDir) + 1) * 0.5 * dotStrength + 1 - dotStrength) * 255
            render.setRGBA(color, color, color, 255)
            --render.setRGBA(color[1], color[2], color[3], 255)
            render.drawRect(x, y, pixelSize, pixelSize)
        end
    end
    return true
end)

local drawWave = coroutine.wrap(function()
    local pixelSize = 1
    local waveScale = 0.1
    for x = 1, 1023, pixelSize do
        local color = procText.sinWave(x * waveScale, 5) * 255
        render.setRGBA(color, color, color, 255)
        render.drawRect(x, 0, pixelSize, 1024)
    end
    return true
end)

render.createRenderTarget("")

hook.add("renderoffscreen", "", function()
    render.selectRenderTarget("")
    if drawPerlin() == true then
        hook.remove("renderoffscreen", "")
    end
end)

hook.add("render", "", function()
    render.setRenderTargetTexture("")
    render.drawTexturedRect(0, 0, 512, 512)
end)