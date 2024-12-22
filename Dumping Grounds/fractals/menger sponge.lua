--@name Menger Sponge Fractal
--@author Jacbo
--@client

if player() ~= owner() then return end

local maxCPU = 1/60
local maxDepth = 2
local rtDepth = 4
local denom = (1/3)^rtDepth
local denom2 = (2/3)^rtDepth

function spongify(x, y, size)
    if quotaAverage() > maxCPU then coroutine.yield() end
    render.drawRect(x + size/3, y + size/3, size/3, size/3)
    if size/3 >= 10 then
        for i = x, x + size - 1, size/3 do
            spongify(i, y, size/3)
            spongify(i, y + size*2/3, size/3)
        end
        spongify(x, y + size/3, size/3)
        spongify(x + size*2/3, y + size/3, size/3)
    end
    return true
end

local makeSponge = coroutine.wrap(function()
    render.setRGBA(255,255,255,255)
    render.drawRect(0,0,1024,1024)
    render.setRGBA(0,0,0,255)
    if spongify(0, 0, 1024, 1024) == true then
        return true
    end
end)

function drawSponge(x, y, size, depth, nodraw)
    if nodraw == 0 then
        if depth == maxDepth then
            render.drawTexturedRect(x, y, size, size)
        end
        depth = depth + 1
        nodraw = rtDepth + 1
    end
    if depth <= maxDepth then
        nodraw = nodraw - 1
        local size3 = size/3
        for i = x, x + size - 1, size3 do
            drawSponge(i, y, size3, depth, nodraw)
            drawSponge(i, y + size3*2, size3, depth, nodraw)
        end
        drawSponge(x, y + size3, size3, depth, nodraw)
        drawSponge(x + size3*2, y + size3, size3, depth, nodraw)
    end
end

render.createRenderTarget("")

hook.add("renderoffscreen", "", function()
    render.selectRenderTarget("")
    render.setRGBA(0,0,0,255)
    if makeSponge() == true then
        print("Done")
        hook.remove("renderoffscreen", "")
    end
end)

hook.add("render", "", function()
    render.setRenderTargetTexture("")
    --render.drawTexturedRect(0, 0, 512, 512)
    drawSponge(0, 0, 512, 1, 0)
end)