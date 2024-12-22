-- Not very interesting
-- Connect to screen and put the screen flat on the ground (optional)

--@name Floor Guy
--@author Jacbo
--@client
--@include spawn_blocking.txt

require("spawn_blocking.txt")

corWrap(function()
    local box = hologram.create(Vector(), Angle(), "models/hunter/blocks/cube2x2x2.mdl", Vector(-1, 1, 1))
    box:setMaterial("models/mspropp/arcade_tilewall002a")
    local min, max = box:worldSpaceAABB()
    local center = (min + max) / 2
    local guy = hologram.create(Vector(), Angle(), player():getModel())
    guy:setAnimation("taunt_dance", 0)
    timer.create("", 9.03125, 0, function()
        guy:setAnimation("taunt_dance", 0)
    end)
    guy:setSkin(player():getSkin())
    local rise = 20
    
    
    
    --box:suppressEngineLighting(true)
    --guy:suppressEngineLighting(true)
    
    --local light = light.create(chip():getPos(), 500, 5, Color(255, 0, 0))
    --local screen
    
    hook.add("render", "", function()
        local screen = render.getScreenEntity()
        render.pushMatrix(Matrix(), true)
        
        rise = math.sin(timer.curtime()) * 47
        
        box:setAngles(screen:getAngles())
        box:setPos(screen:localToWorld(Vector(0, 0, rise + 1.25) - center))
        box:setClip(1, true, center + Vector(0,0,-rise), Vector(0,0,-1), box)
        box:draw()
        
        guy:setAngles(screen:getAngles())
        guy:setPos(screen:localToWorld(Vector(0, 0, -47.45 + rise + 1.25)))
        guy:draw()
        
        render.popMatrix()
    end)
    
    --[[hook.add("think", "", function()
        if screen then
            light:setPos(screen:localToWorld(Vector(0, 0, -47.45)))
            light:draw()
        end
    end)]]
end)