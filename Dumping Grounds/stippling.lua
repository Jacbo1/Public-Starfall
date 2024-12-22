--@name Dithering
--@author Jacbo
--@client
--@include procedural_textures/perlin.txt
--include better_coroutines.txt

require("procedural_textures/perlin.txt")
--local corLib = require("better_coroutines.txt")

local maxCPU = math.min(0.005, quotaMax() * 0.75)
if player() == owner() then
    maxCPU = math.min(0.015, quotaMax() * 0.75)
end
--local maxCPU = math.min(0.0003, quotaMax() * 0.75)
local color1 = Color(math.rand(0, 360), 1, 1):hsvToRGB()
local color2 = Color(math.rand(0, 360), 1, 1):hsvToRGB()

render.createRenderTarget("")

local dithering = {
    {{false, false, false, false},
     {false, false, false, false},
     {false, false, false, false},
     {false, false, false, false}},
    
    {{false, false, false, true},
     {false, false, false, false},
     {false, false, false, false},
     {false, false, false, false}},
    
    {{false, true, false, false},
     {false, false, false, false},
     {false, false, false, true},
     {false, false, false, false}},
    
    {{false, false, false, true},
     {false, true, false, false},
     {false, false, false, true},
     {false, false, false, false}},
    
    {{false, true, false, true},
     {false, false, false, false},
     {false, true, false, true},
     {false, false, false, false}},
    
    {{false, true, false, true},
     {false, false, true, false},
     {false, true, false, true},
     {false, false, false, false}},
    
    {{false, true, false, true},
     {true, false, false, false},
     {false, true, false, true},
     {false, false, true, false}},
    
    {{false, true, false, true},
     {false, false, true, false},
     {false, true, false, true},
     {true, false, true, false}},
    
    {{false, true, false, true},
     {true, false, true, false},
     {false, true, false, true},
     {true, false, true, false}},
    
    {{false, true, false, true},
     {true, false, true, false},
     {false, true, false, true},
     {true, false, true, true}},
    
    {{false, true, false, true},
     {true, false, true, true},
     {false, true, false, true},
     {true, true, true, false}},
    
    {{false, true, false, true},
     {true, true, true, true},
     {false, true, false, true},
     {true, false, true, true}},
    
    {{false, true, false, true},
     {true, true, true, true},
     {false, true, false, true},
     {true, true, true, true}},
    
    {{false, true, false, true},
     {true, true, true, true},
     {false, true, true, true},
     {true, true, true, true}},
    
    {{false, true, true, true},
     {true, true, true, true},
     {true, true, false, true},
     {true, true, true, true}},
    
    {{true, true, true, true},
     {true, true, true, true},
     {false, true, true, true},
     {true, true, true, true}},
    
    {{true, true, true, true},
     {true, true, true, true},
     {true, true, true, true},
     {true, true, true, true}}
}

local size = 8
local z = 0

local draw = coroutine.wrap(function()
    --z = z + 1
    local delta = math.floor(1024 / size)
    local maxCoord = 1024 - size
    --local ditheringMult = 1 / (maxCoord / #dithering)
    local ditheringMult = 1 / (1 / #dithering)
    
    render.setColor(color1)
    render.drawRect(0, 0, 1024, 1024)
    render.setColor(color2)
    
    local lastColor = nil
    
    local perlinScale = 1/100
    
    for x = 0, maxCoord, size do
        for y = 0, maxCoord, size do
            while cpuUsed() >= maxCPU do
                coroutine.yield()
                render.setColor(color2)
            end
            
            local mask = dithering[math.floor(y * ditheringMult + 1)]
            
            -- Perlin
            local perl = perlin:noise(x * perlinScale, y * perlinScale) * 0.5 + 0.5
            local mask = dithering[math.floor(perl * ditheringMult + 1)]
            
            local x1 = (x / size) % 4 + 1
            local y1 = (y / size) % 4 + 1
            if mask[x1][y1] then
                render.drawRect(x, y, size, size)
            end
            --[[if mask[x1][y1] then
                if lastColor ~= true then
                    lastColor = true
                    render.setColor(color2)
                end
            elseif lastColor ~= false then
                lastColor = false
                render.setColor(color1)
            end
            render.drawRect(x, y, size, size)]]
        end
    end
    return true
end)

hook.add("renderoffscreen", "", function()
    render.selectRenderTarget("")
    if draw() == true then
        hook.remove("renderoffscreen", "")
    end
    --draw()
end)

hook.add("render", "", function()
    render.setRenderTargetTexture("")
    render.drawTexturedRect(0, 0, 512, 512)
end)