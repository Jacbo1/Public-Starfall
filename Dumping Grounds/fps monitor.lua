-- Charts your FPS

--@name FPS Monitor
--@author Jacbo
--@shared

local maxFPS = 0
local duration = 30

if SERVER then
    --[[local lastTime = timer.systime()
    hook.add("think", "fps monitor", function()
        net.start("fps monitor")
        net.writeFloat(timer.frametime())
        local time = timer.systime()
        net.writeFloat(1023 * (time - lastTime) / duration)
        lastTime = time
        net.send()
    end)]]
    --[[local oldSystime = timer.systime()
    local oldCurtime = timer.curtime()
    local lastTime = oldSystime
    hook.add("think", "fps monitor", function()
        net.start("fps monitor")
        local curSystime = timer.systime()
        local curCurtime = timer.curtime()
        --net.writeFloat(curSystime - oldSystime - curCurtime + oldCurtime + maxInterval)
        net.writeFloat(curSystime - oldSystime)
        oldSystime = curSystime
        oldCurtime = curCurtime
        net.writeFloat(1023 * (curSystime - lastTime) / duration)
        lastTime = curSystime
        net.send()
    end)]]
else
    render.createRenderTarget("screen")
    local queue = {}
    local oldPos = {0,0}
    local curFPS = 0
    local changed = false
    
    --[[net.receive("fps monitor", function()
        local interval = net.readFloat()
        table.insert(queue, interval)
        table.insert(queue, net.readFloat())
        curFPS = math.round(1 / interval)
    end)]]
    
    local lastTime = timer.systime()
    local first = true
    
    hook.add("think", "fps monitor", function()
        local fps = 1 / timer.frametime()
        if first then
            first = false
        elseif fps > maxFPS then
            maxFPS = fps
        end
        curFPS = math.round(fps)
        table.insert(queue, fps)
        local time = timer.systime()
        table.insert(queue, 1023 * (time - lastTime) / duration)
        lastTime = time
    end)
    
    hook.add("renderoffscreen","",function()
        if #queue != 0 then
            changed = true
            render.selectRenderTarget("screen")
            while #queue != 0 do
                local fps = table.remove(queue, 1)
                local width = table.remove(queue, 1)
                local newPos = {oldPos[1] + width, 1023 * (1 - fps / maxFPS)}
                local wrap = false
                if newPos[1] > 1023 then
                    newPos[1] = newPos[1] - 1023
                    wrap = true
                end
                render.setRGBA(0,0,0,255)
                if wrap then
                    render.drawRect(oldPos[1] + 1, 0, math.max(1023 - oldPos[1], 1), 1024)
                    render.drawRect(0, 0, math.max(newPos[1] + 1, 1), 1024)
                else
                    render.drawRect(oldPos[1] + 1, 0, newPos[1] - oldPos[1], 1024)
                end
                if newPos[2] == oldPos[2] then
                    render.setRGBA(255,255,0,255)
                elseif newPos[2] > oldPos[2] then
                    render.setRGBA(255,0,0,255)
                else
                    render.setRGBA(0,255,0,255)
                end
                if wrap then
                    render.drawLine(oldPos[1], oldPos[2], newPos[1] + 1023, newPos[2])
                    render.drawLine(oldPos[1] - 1023, oldPos[2], newPos[1], newPos[2])
                else
                    render.drawLine(oldPos[1], oldPos[2], newPos[1], newPos[2])
                end
                oldPos[1] = newPos[1]
                oldPos[2] = newPos[2]
            end
        end
    end)
    
    local font = render.createFont("lucida console",25,1,1)
    hook.add("render","",function()
        --if changed then
            changed = false
            render.setRenderTargetTexture("screen")
            render.drawTexturedRect(0,0,512,512)
            render.setFont(font)
            render.setRGBA(255,255,255,255)
            render.drawLine(oldPos[1] / 2, 0, oldPos[1] / 2, 511)
            render.drawSimpleText(0,0, "FPS: " .. curFPS, 0, 0)
        --end
    end)
end