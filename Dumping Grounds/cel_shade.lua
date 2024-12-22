-- Gives props you spawn this on a cel shading effect
-- Might need High lighting or graphics settings

--@name Cel Shade
--@author
--@shared

if SERVER then
    --[[local ent = chip():isWeldedTo()
    net.receive("init", function(_, ply)
        net.start("init")
        net.writeEntity(ent)
        net.send(ply)
    end)]]
    timer.simple(1, function()
        constraint.breakAll(chip(), "weld")
    end)
else -- CLIENT
    --net.receive("init", function()
        --net.readEntity(function(ent)
            --local skin = 6
            for i = 1, 6 do
            local ent = trace.line(chip():getPos(), chip():getPos() - chip():getUp() * 100, chip()).Entity
            --local og = ent:getMaterials()[1]
            local og = ent:getMaterials()[i+1]
            local mat = material.create("VertexLitGeneric")
            mat:setTexture("$basetexture", material.getTexture(og, "$basetexture"))
            --mat:setTexture("$basetexture", material.getTexture("models/debug/debugwhite", "$basetexture"))
            --mat:setTexture("$bumpmap", material.getTexture("models/debug/debugwhite", "$bumpmap"))
            local bump = material.getTexture(og, "$bumpmap")
            if bump ~= "error" then
                mat:setTexture("$bumpmap", bump)
            end
            mat:setInt("$phong", 1)
            mat:setFloat("$phongboost", 0)
            mat:setTextureURL("$lightwarptexture", "https://i.imgur.com/llNfLZi.png", function(_, _, width, height, layout)
            --mat:setTextureURL("$lightwarptexture", "https://dl.dropboxusercontent.com/s/7obk2874d9xk68m/reverse.png", function(_, _, width, height, layout)
                layout(0, 0, 1024, 1024)
            end, function()
                --[[local owner = owner()
                local ents = find.byClass("prop_physics", function(ent)
                    return ent:getOwner() == owner
                end)
                local s = "!" .. mat:getName()
                for k, ent in ipairs(ents) do]]
                    --ent:setMaterial("!" .. mat:getName())
                    ent:setSubMaterial(i, "!" .. mat:getName())
                --end
            end)
        end
        --[[end)
    end)
    
    timer.simple(2, function()
        net.start("init")
        net.send()
    end)]]
end