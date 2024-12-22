-- Connect to screen

--@name Clock
--@author Jacbo
--@client

local fps = 1

local nextFrameTime = timer.systime()
render.createRenderTarget("screen")

local init = false
local font
local militaryTime = false
local mousex, mousey

local drawArc = function(x, y, radius, thickness, startAng, arcAng, interval)
    interval = arcAng/math.abs(math.floor(arcAng/interval))
    local x1 = x + radius
    local y1 = y + radius
    local innerRadius = radius-thickness
    local lastPoint = {x = x1 + radius * math.cos(startAng), y = y1 + radius * math.sin(startAng)}
    local lastInnerPoint = {x = x1 + innerRadius * math.cos(startAng), y = y1 + innerRadius * math.sin(startAng)}
    for i = startAng+interval, startAng+arcAng, interval do
        local point = {x = x1 + radius * math.cos(i), y = y1 + radius * math.sin(i)}
        local innerPoint = {x = x1 + innerRadius * math.cos(i), y = y1 + innerRadius * math.sin(i)}
        render.drawPoly({lastPoint,point,innerPoint,lastInnerPoint})
        lastPoint = point
        lastInnerPoint = innerPoint
    end
end

hook.add("renderoffscreen","",function()
    if not init then
        init = true
        font = render.createFont("coolvetica",100,1,1)
        render.setFont(font)
    end
    
    local time = timer.curtime()
    if time >= nextFrameTime then
        nextFrameTime = nextFrameTime + 1/fps
        render.selectRenderTarget("screen")
        render.clear()
        --Thu Jun 18 15:22:09 2020
        local date = os.date()
        local dateTable = string.explode(" ", date)
        local day = dateTable[1]
        local month = dateTable[2]
        local dayNum = dateTable[3]
        local timeStr = dateTable[4]
        local year = dateTable[5]
        local times = string.explode(":", timeStr)
        local hour = tonumber(times[1])
        if not militaryTime and hour > 12 then
            hour = hour - 12
            timeStr = hour .. string.sub(timeStr,string.find(timeStr,":",1,true),#timeStr)
        end
        local minute = tonumber(times[2])
        local second = tonumber(times[3])
        render.setColor(Color(255,255,255))
        local size = 800
        local thickness = 50
        local interval = math.rad(5)
        render.drawText(512,512-50,timeStr,1)
        drawArc(512-size/2,512-size/2,size/2,thickness,-math.pi/2,math.pi*2*second/60,interval)
        size = size-thickness*2
        drawArc(512-size/2,512-size/2,size/2,thickness,-math.pi/2,math.pi*2*minute/60,interval)
        size = size-thickness*2
        drawArc(512-size/2,512-size/2,size/2,thickness,-math.pi/2,math.pi*2*hour/(militaryTime and 24 or 12),interval)
    end
end)

hook.add("render","",function()
    render.setRenderTargetTexture("screen")
    render.drawTexturedRect(0,0,512,512)
    local x, y = render.cursorPos()
    if x and y then
        mousex = x
        mousey = y
    end
end)