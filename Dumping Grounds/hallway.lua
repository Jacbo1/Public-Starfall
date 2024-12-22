-- Spawn 6 4x4 plate screens then spawn this chip

--@name Hallway
--@author Jacbo

local size = 4 -- Screen plate size
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
else --CLIENT
    local huSize = size * 47.45
    local center = chip():getPos() + Vector(0,0,3 + 47.45 * size / 2)
    
    --local floorMat = material.load("models/mspropp/wood_floor_3")
    local floorMat = material.create("UnlitGeneric")
    --floorMat:setTexture("$basetexture", material.getTexture("models/mspropp/wood_floor_3", "$basetexture"))
    floorMat:setTexture("$basetexture", material.getTexture("models/props_c17/furniturefabric001a", "$basetexture"))
    --floorMat:setTexture("$basetexture", material.getTexture("models/eli/eli_tex4z", "$basetexture"))
    local wallMat = material.create("UnlitGeneric")
    wallMat:setTexture("$basetexture", material.getTexture("models/props_skybox/computerwall007", "$basetexture"))
    --wallMat:setTexture("$basetexture", material.getTexture("models/kleiner/walter_face", "$basetexture"))
    local ceilingMat = material.create("UnlitGeneric")
    --ceilingMat:setTexture("$basetexture", material.getTexture("models/mspropp/labceil02b", "$basetexture"))
    ceilingMat:setTexture("$basetexture", material.getTexture("models/props/CS_militia/milceil001", "$basetexture"))
    --ceilingMat:setTexture("$basetexture", material.getTexture("models/mossman/mossman_face", "$basetexture"))
    local lengthMult = 8096
    local length = huSize * lengthMult * 0.5
    local width2 = huSize * 0.5
    local maxU = size * lengthMult
    local width = width2 * math.sqrt(3)
    
    local cos = 0
    local sin = 0
    
    hook.add("think", "", function()
        local ang = timer.systime()
        cos = math.cos(ang)
        sin = math.sin(ang)
    end)

    hook.add("render", "", function()
            local scroll = (100 * math.cos(timer.systime() / 8)) % 1
            local maxU = maxU + scroll
            local minU = scroll
            local minV = 0--scroll
            local maxV = size-- + scroll
            --local screen = render.getScreenEntity()
            render.pushMatrix(Matrix(), true)
            render.setMaterial(floorMat)
            render.draw3DQuadUV(
                {-length + center[1], width2 + center[2], -width2 + center[3], minU, 0},
                {length + center[1], width2 + center[2], -width2 + center[3], maxU, 0},
                {length + center[1], -width2 + center[2], -width2 + center[3], maxU, size},
                {-length + center[1], -width2 + center[2], -width2 + center[3], minU, size}
            )
            
            --x = x * cos - y * sin,
            --y = x * sin + y * cos
            render.draw3DQuadUV(
                {-length + center[1], width*cos+width*sin + center[2], width*sin-width*cos + center[3], minU, 0},
                {length + center[1], width*cos+width*sin + center[2], width*sin-width*cos + center[3], maxU, 0},
                {length + center[1], -width*cos+width*sin + center[2], -width*sin-width*cos + center[3], maxU, size},
                {-length + center[1], -width*cos+width*sin + center[2], -width*sin-width*cos + center[3], minU, size}
            )
            --[[render.setMaterial(images[2])
            --00,10,11,01
            render.draw3DQuadUV(
                {-length + center[1], -width + center[2], width + center[3], minU, minV},
                {-length + center[1], length + center[2], length + center[3], maxU, minV},
                {-length + center[1], length + center[2], -length + center[3], maxU, maxV},
                {-length + center[1], -length + center[2], -length + center[3], minU, maxV}
            )]]
            render.setMaterial(wallMat)
            --11,01,00,10
            --[[render.draw3DQuadUV(
                {-length + center[1], -width + center[2], -width + center[3], minU, maxV},
                {length + center[1], -width + center[2], -width + center[3], maxU, maxV},
                {length + center[1], -width + center[2], width + center[3], maxU, minV},
                {-length + center[1], -width + center[2], width + center[3], minU, minV}
            )]]
            render.draw3DQuadUV(
                {-length + center[1], -width*cos+width*sin + center[2], -width*sin-width*cos + center[3], minU, maxV},
                {length + center[1], -width*cos+width*sin + center[2], -width*sin-width*cos + center[3], maxU, maxV},
                {length + center[1], -width*cos-width*sin + center[2], -width*sin+width*cos + center[3], maxU, minV},
                {-length + center[1], -width*cos-width*sin + center[2], -width*sin+width*cos + center[3], minU, minV}
            )
            --[[render.setMaterial(images[4])
            render.draw3DQuadUV(
                {length + center[1], -length + center[2], -length + center[3], maxU, maxV},
                {length + center[1], length + center[2], -length + center[3], minU, maxV},
                {length + center[1], length + center[2], length + center[3], minU, minV},
                {length + center[1], -length + center[2], length + center[3], maxU, minV}
            )
            render.setMaterial(images[5])]]
            --[[render.draw3DQuadUV(
                {-length + center[1], width + center[2], width + center[3], minU, minV},
                {length + center[1], width + center[2], width + center[3], maxU, minV},
                {length + center[1], width + center[2], -width + center[3], maxU, maxV},
                {-length + center[1], width + center[2], -width + center[3], minU, maxV}
            )]]
            render.draw3DQuadUV(
                {-length + center[1], width*cos-width*sin + center[2], width*sin+width*cos + center[3], minU, minV},
                {length + center[1], width*cos-width*sin + center[2], width*sin+width*cos + center[3], maxU, minV},
                {length + center[1], width*cos+width*sin + center[2], width*sin-width*cos + center[3], maxU, maxV},
                {-length + center[1], width*cos+width*sin + center[2], width*sin-width*cos + center[3], minU, maxV}
            )
            render.setMaterial(ceilingMat)
            --[[render.draw3DQuadUV(
                {-length + center[1], -width + center[2], width + center[3], minU, 0},
                {length + center[1], -width + center[2], width + center[3], maxU, 0},
                {length + center[1], width + center[2], width + center[3], maxU, size},
                {-length + center[1], width + center[2], width + center[3], minU, size}
            )]]
            render.draw3DQuadUV(
                {-length + center[1], -width*cos-width*sin + center[2], -width*sin+width*cos + center[3], minU, 0},
                {length + center[1], -width*cos-width*sin + center[2], -width*sin+width*cos + center[3], maxU, 0},
                {length + center[1], width*cos-width*sin + center[2], width*sin+width*cos + center[3], maxU, size},
                {-length + center[1], width*cos-width*sin + center[2], width*sin+width*cos + center[3], minU, size}
            )
            render.popMatrix()
        end)
end