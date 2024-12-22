--@name Vector Field Grapher
--@author Jacbo
--@shared
--@include funcs.txt

if SERVER then
    require("funcs.txt")
    funcs.linkToClosestScreen()
--elseif player() == owner() then
else

require("funcs.txt")

local abs = math.abs
local function field(x, y)
    local x1 = (x/512-1)
    local y1 = -(y/512-1)
    --[[return (-y-0.1*x)*1024+512,
        (x-0.4*y)*1024+512]]
    return x + (-x1*0.5)*10,
        y + (-0.4*y1*y1)*10 - 2
    --[[return x -x1*30 + x1*(1-abs(y1))*49,
        y -8*y1*y1 - 20]]
end
--640
local trails = {}
local d = 10
for x = 0, 1023, d do
    table.insert(trails, {
        x = x,
        y = 1023,
        oldx = x,
        oldy = 1023,
        color = Color(x*310 / 1023, 1, 1):hsvToRGB()
    })
end

render.createRenderTarget("")

local init = false

hook.add("renderoffscreen", "", function()
    render.selectRenderTarget("")
    --[[if not init then
        render.drawLine(0, 512+128, 1023, 512+128)
    end]]
    local setColor = render.setColor
    local drawLine = render.drawLine
    for _, trail in ipairs(trails) do
        trail.oldx = trail.x
        trail.oldy = trail.y
        trail.x, trail.y = field(trail.x, trail.y)
        setColor(trail.color)
        drawLine(trail.oldx, trail.oldy, trail.x, trail.y)
    end
end)

hook.add("render", "", function()
    render.setRenderTargetTexture("")
    render.drawTexturedRect(0, 0, 512, 512)
end)
end