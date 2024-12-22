-- Spawn a models/hunter/blocks/cube05x05x05.mdl and view it from the other side of a screen

--@name 3D to Screen 2D
--@author Jacbo
--@shared

if SERVER then

else--CLIENT
    local ent = find.byModel("models/hunter/blocks/cube05x05x05.mdl", function(e)
        return e:getOwner() == owner()
    end)[1]
    
    local function worldToScreen(screenInfo, screenOrigin, screenNormal, screenAng, pos)
        local hitPos = trace.intersectRayWithPlane(eyePos(), pos - eyePos(), screenOrigin, screenNormal)
        if not hitPos then return end
        hitPos = worldToLocal(hitPos - screenOrigin, screenAng, Vector(), Angle())
        local x = (hitPos[2] - screenInfo.x1) / (screenInfo.x2 - screenInfo.x1) * 511
        local y = 511 - (hitPos[3] - screenInfo.y1) / (screenInfo.y2 - screenInfo.y1) * 511
        return Vector(x, y)
    end
    
    hook.add("render", "", function()
        
        --93.2
        local screen = render.getScreenEntity()
        local info = render.getScreenInfo(screen)
        local screenOrigin = screen:localToWorld(info.offset)
        local screenAng = screen:localToWorldAngles(info.rot)
        local screenNormal = screenAng:getUp()
        
        info.x1 = -93.2 / 2
        info.x2 = 93.2 / 2
        info.y1 = -93.2 / 2
        info.y2 = 93.2 / 2
        
        local center = Vector()
        local halfSize = Vector(47.45 / 4)
        local corners = {
            -halfSize,                    -- 1
            halfSize * Vector(-1, -1, 1), -- 2
            halfSize * Vector(-1, 1, -1), -- 3
            halfSize * Vector(-1, 1, 1),  -- 4
            halfSize * Vector(1, -1, -1), -- 5
            halfSize * Vector(1, -1, 1),  -- 6
            halfSize * Vector(1, 1, -1),  -- 7
            halfSize                      -- 8
        }
        
        local connections = {
            { 2, 3, 5 },
            { 4, 6 },
            { 4, 7 },
            { 8 },
            { 7 },
            { 8, 5 },
            { 8 },
            {}
        }
        
        for i = 1, 8 do
            corners[i] = worldToScreen(info, screenOrigin, screenNormal, screenAng, ent:localToWorld(corners[i] + center)) or Vector()
        end
        
        for i = 1, 8 do
            local x = corners[i][1]
            local y = corners[i][2]
            --render.drawRect(x - 1, y - 1, 2, 2)
            for _, j in ipairs(connections[i]) do
                render.drawLine(x, y, corners[j][1], corners[j][2])
            end
        end
--[[info:
. x2 = 48
. RS = 0.182
. rot = Angle(0, 90, 180)
. Name = Panel 2x2
. offset = Vector(0, 0, 2)
. y2 = 48
. y1 = -48
. RatioX = 1
. z = 0
. x1 = -48
]]
    end)
end