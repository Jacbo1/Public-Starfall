-- Connect to screen and wait
-- Phong looks incorrect. Either misconfigured or bugged.

--@name Lighting
--@author Jacbo
--@client
--@include procedural_textures/perlin.txt

require("procedural_textures/perlin.txt")

local maxCPU = math.min(0.002, quotaMax() * 0.75)
if player() == owner() then
    maxCPU = math.min(0.03, quotaMax() * 0.75)
end

local lights = {
    {
        pos = Vector(512 + 256 * math.cos(0),512 + 256 * math.sin(0), 10),
        brightness = 0.5,
        color = Vector(255, 0, 0)
    },
    {
        pos = Vector(512 + 256 * math.cos(math.pi * 2 / 3),512 + 256 * math.sin(math.pi * 2 / 3), 10),
        brightness = 0.5,
        color = Vector(0, 255, 0)
    },
    {
        pos = Vector(512 + 256 * math.cos(math.pi * 4 / 3),512 + 256 * math.sin(math.pi * 4 / 3), 10),
        brightness = 0.5,
        color = Vector(0, 0, 255)
    }
}

for k, light in ipairs(lights) do
    lights[k].const = light.color * light.brightness * 219.51097961044988183998
end

local sunDir = Vector(3, 1.2, 4):getNormalized()
local globalColor = Vector(0.25)
local ogColor = Vector(200)
local camHeight = 1
local phongBoost = 0.1
local phongExponent = 20
local fresnel = Vector(0.5, 0.8, 1)

render.createRenderTarget("")

local draw = coroutine.wrap(function()
    local noise = {}
    for x = -1, 1024 do
        local t = {}
        for y = -1, 1024 do
            while quotaAverage() > maxCPU do coroutine.yield() end
            t[y] = perlin:noise(x * 0.25, y * 0.25)
        end
        noise[x] = t
    end
    
    local camPos = Vector(512, 512, camHeight)
    
    for x = 0, 1023 do
        for y = 0, 1023 do
            while quotaAverage() > maxCPU do coroutine.yield() end
            local pixelCoord = Vector(x, y, 0)
            local camDir = (pixelCoord - camPos):getNormalized()
            
            local normal = Vector(
                noise[x + 1][y] - noise[x - 1][y],
                noise[x][y - 1] - noise[x][y + 1],
                1):getNormalized()
                
            local color = Vector()
            local sunDot = normal:dot(sunDir)
            if sunDot > 0 then
                color = ogColor * sunDot * globalColor
            end
            
            -- Calculate light
            for _, light in ipairs(lights) do
                local lightDir = light.pos - pixelCoord
                local lightDist = lightDir:getLength()
                lightDir = lightDir / lightDist
                local lightColor = light.const / lightDist
                local dot = normal:dot(lightDir)
                
                -- Phong
                if dot > 0 then
                    color = color + lightColor * dot
                    local fresnelDot = 1 - dot
                    fresnelDot = fresnelDot * fresnelDot
                    local fresnelMult
                    if fresnelDot > 0.5 then
                        fresnelMult = fresnel[2] + (fresnel[3] - fresnel[2]) * (fresnelDot * 2 - 1)
                    else
                        fresnelMult = fresnel[1] + (fresnel[2] - fresnel[1]) * fresnelDot * 2
                    end
                    
                    local mult = phongBoost * 40 * fresnelMult
                    local reflectDir = -lightDir + 2 * dot * normal
                    local specAngle = math.max(-reflectDir:dot(camDir), 0)
                    local specular = specAngle ^ (phongExponent * 0.25)
                    color = color + specular * mult * lightColor
                end
            end
            
            render.setRGBA(color[1], color[2], color[3], 255)
            render.drawRect(x, y, 1, 1)
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