-- I was going to do something more with this but I'm leaving it in to give an idea of something to make.
-- Fake player physics in a fake environment controlled and rendered by your code.
-- Only thing actually in this at the moment is a white plane in a black void and you can walk around horizontally but can't jump or fall.

--@name VR
--@author Jacbo

local plyPos = Vector()
local size = 8
if SERVER then
    local urlInterval = 60
    local screens = find.byClass("starfall_screen", function(ent)
        if ent:getOwner() != owner() then
            return false
        end
        return true
    end)
    if #screens != 6 then
        print("Spawn 6 starfall screens")
        chip():remove()
    else
        local center = chip():getPos() + Vector(0,0,3 + 47.45 * size / 2)
        local origin = chip():getPos() + Vector(0,0,3)
        local pos, ang, ent = origin, Angle(0,90,0), screens[1]
        pos, ang = localToWorld(-ent:obbCenter(), Angle(0,0,0), pos, ang)
        ent:setPos(pos)
        ent:setAngles(ang)
        
        pos, ang, ent = origin + Vector(47.45, 0, 47.45) * size / 2, Angle(90,180,0), screens[2]
        pos, ang = localToWorld(-ent:obbCenter(), Angle(0,0,0), pos, ang)
        ent:setPos(pos)
        ent:setAngles(ang)
        
        pos, ang, ent = origin + Vector(0, 47.45, 47.45) * size / 2, Angle(0,0,90), screens[3]
        pos, ang = localToWorld(-ent:obbCenter(), Angle(0,0,0), pos, ang)
        ent:setPos(pos)
        ent:setAngles(ang)
        
        pos, ang, ent = origin + Vector(-47.45, 0, 47.45) * size / 2, Angle(90,0,0), screens[4]
        pos, ang = localToWorld(-ent:obbCenter(), Angle(0,0,0), pos, ang)
        ent:setPos(pos)
        ent:setAngles(ang)
        
        pos, ang, ent = origin + Vector(0, -47.45, 47.45) * size / 2, Angle(0,180,90), screens[5]
        pos, ang = localToWorld(-ent:obbCenter(), Angle(0,0,0), pos, ang)
        ent:setPos(pos)
        ent:setAngles(ang)
        
        pos, ang, ent = origin + Vector(0, 0, 47.45) * size, Angle(180,90,0), screens[6]
        pos, ang = localToWorld(-ent:obbCenter(), Angle(0,0,0), pos, ang)
        ent:setPos(pos)
        ent:setAngles(ang)
        
        for i = 1, 6 do
            screens[i]:linkComponent(chip())
            screens[i]:setFrozen(true)
            screens[i]:setColor(Color(255,255,255,1))
        end
    end
    
    local ground = chip():getPos() + Vector(0,0,5)
    hook.add("think", "", function()
        local v = owner():getPos()
        plyPos = plyPos + ground - v
        net.start("")
        --net.writeVector(plyPos)
        net.writeFloat(plyPos[1])
        net.writeFloat(plyPos[2])
        --net.writeDouble(timer.curtime())
        net.send()
        --owner():setPos(Vector(ground[1], ground[2], v[3]))
        owner():setPos(ground)
    end)
else --CLIENT
    --local oldTime = timer.curtime()
    local vel = Vector()
    local oldPos = Vector()
    net.receive("", function()
        local v = Vector(net.readFloat(), net.readFloat(), 0)
        --local t = net.readDouble()
        --vel = (v - oldPos) / (t - oldTime)
        vel = (v - oldPos) / game.getTickInterval()
        oldTime = t
        plyPos = v
        oldPos = v
    end)
    
    hook.add("think", "", function()
        plyPos = plyPos - vel * timer.frametime()
    end)
    
    local floorMat = material.create("UnlitGeneric")
    floorMat:setTexture("$basetexture", material.getTexture("models/mspropp/wood_floor_3", "$basetexture"))
    local length = 500
    local minU = 0
    local maxU = 25
    local minV = 0
    local maxV = 25
    hook.add("render", "", function()
        local eye = eyePos()
        local eyeHeight = eye - owner():getPos()
        local origin = eye + plyPos - eyeHeight
        render.pushMatrix(Matrix(), true)
        render.setMaterial(floorMat)
        render.draw3DQuadUV(
            {-length + origin[1], length + origin[2], origin[3], minU, minV},
            {length + origin[1], length + origin[2], origin[3], maxU, minV},
            {length + origin[1], -length + origin[2], origin[3], maxU, maxV},
            {-length + origin[1], -length + origin[2], origin[3], minU, maxV}
        )
        render.popMatrix()
    end)
end