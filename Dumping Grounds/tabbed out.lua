-- Puts a "tabbed out" ring around players who are tabbed out.

--@name Tabbed Out
--@author Jacbo
--@shared

if SERVER then
    local focus = {}
    net.receive("all focus", function(_, ply)
        try(function()
            net.start("all focus")
            net.writeUInt(#focus, 16)
            for _, t in pairs(focus) do
                net.writeEntity(t[1])
            end
            net.send(ply)
        end)
    end)
    net.receive("focus", function(_, ply)
        try(function()
            local hasFocus = net.readBool()
            local id = ply:getSteamID()
            if hasFocus then
                focus[id] = nil
            else
                focus[id] = {ply, false}
            end
            net.start("focus")
            net.writeEntity(ply)
            net.writeBool(hasFocus)
            net.send()
        end)
    end)
else--CLIENT
    --local playerStats = {}
    local maxCPU = 1 / 60
    local ringMesh
    local ringMat = material.create("VertexLitGeneric")
    local ringMatReady = false
    local radius = 35
    local height = 10
    local rings = {}
    local function makeHolo()
        local holo = holograms.create(player():getPos(), Angle(), "models/hunter/plates/plate.mdl")
        holo:setColor(Color(255,255,255,254))
        holo:setMesh(ringMesh)
        holo:setMeshMaterial(ringMat)
        try(function()
            holo:setRenderBounds(Vector(-radius, -radius, 0), Vector(radius, radius, height))
        end)
        holo:suppressEngineLighting(true)
        holo:setNoDraw(true)
        timer.simple(0.1, function()
            try(function()
                holo:setNoDraw(false)
            end)
        end)
        return holo
    end
    local function makeFuncs()
        net.receive("focus", function()
            try(function()
                local ply = net.readEntity()
                local hasFocus = net.readBool()
                local id = ply:getSteamID()
                if hasFocus then
                    --playerStats[id] = nil
                    if rings[id] ~= nil then
                        rings[id][1]:remove()
                        rings[id] = nil
                        end
                    else
                    --playerStats[id] = ply
                    rings[id] = {makeHolo(), ply, 0, 0}
                end
            end)
        end)
        net.receive("all focus", function()
            try(function()
                local count = net.readUInt(16)
                for i = 1, count do
                    try(function()
                        local ply = net.readEntity()
                        local hasFocus = net.readBool()
                        local id = ply:getSteamID()
                        if hasFocus then
                            --playerStats[id] = nil
                                if rings[id] ~= nil then
                                rings[id][1]:remove()
                                rings[id] = nil
                            end
                        else
                            --playerStats[id] = ply
                            rings[id] = {makeHolo(), ply, 0, 0}
                        end
                    end)
                end
            end)
        end)
        net.start("all focus")
        net.send()
    end
    local makeRing = coroutine.wrap(function()
        local steps = 50
        local lower = Vector(math.cos(0), math.sin(0), 0) * radius
        local lastUpper = Vector(math.cos(0), math.sin(0), height) * radius
        local lowv = ((1024 - 256) / 2 + 256 + 10) / 1023
        local upv = ((1024 - 256) / 2 - 10) / 1023
        local interval = math.pi * 2 / steps
        local normal = Vector(math.cos(interval / 2), math.sin(interval / 2), 0)
        local last = {
            lower = {u = 0, v = lowv, pos = Vector(math.cos(0), math.sin(0), 0) * radius, normal = normal},
            upper = {u = 0, v = upv, pos = Vector(math.cos(0) * radius, math.sin(0) * radius, height), normal = normal}
        }
        local textureScale = 2
        local tris = {}
        for i = 1, steps do
            local dir = Vector(math.cos(i * interval), math.sin(i * interval), 0)
            local u = i / steps * textureScale
            local lowerVert = {u = u, v = lowv, pos = dir * radius, normal = normal}
            local upperVert = {u = u, v = upv, pos = dir * radius + Vector(0,0,height), normal = normal}
            table.insert(tris, last.lower)
            table.insert(tris, lowerVert)
            table.insert(tris, upperVert)
            
            table.insert(tris, last.lower)
            table.insert(tris, upperVert)
            table.insert(tris, last.upper)
            
            last.lower = lowerVert
            last.upper = upperVert
        end
        local loadmesh = function() ringMesh = mesh.createFromTable(tris, true) return true end
        while loadmesh() ~= true do
            while quotaAverage() > maxCPU do
                coroutine.yield()
            end
        end
        return true
    end)
    
    local oldFocus = true
    local first = true
    
    timer.simple(1, function()
        ringMat:setTextureURL("$basetexture", "https://i.imgur.com/NLVjQpm.png", nil, function()
            ringMatReady = true
            ringMat:setInt("$flags", 8192)
        end)
        hook.add("think", "", function()
            local focus = game.hasFocus()
            if focus ~= oldFocus then
                net.start("focus")
                net.writeBool(focus)
                net.send()
                oldFocus = focus
            end
            if ringMesh == nil then
                makeRing()
            elseif ringMatReady then
                if first then
                    makeFuncs()
                    first = false
                end
                local angChange = timer.frametime() * 10
                local keys = table.getKeys(rings)
                local i = 1
                while i <= #keys do
                    if rings[keys[i]][2] ~= nil and rings[keys[i]][2]:isValid() then
                        local pos = rings[keys[i]][2]:getPos()
                        if rings[keys[i]][4] ~= pos then
                            rings[keys[i]][4] = pos
                            rings[keys[i]][1]:setPos(pos + Vector(0,0,10))
                        end
                        rings[keys[i]][3] = (rings[keys[i]][3] + angChange) % 360
                        rings[keys[i]][1]:setAngles(Angle(0, rings[keys[i]][3], 0))
                        i = i + 1
                    else
                        rings[keys[i]][1]:remove()
                        rings[table.remove(keys, i)] = nil
                    end
                end
            end
        end)
    end)
    --
end