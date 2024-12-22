-- Puts a "tabbed out" ring around players who are tabbed out.

--@name Tabbed Out 2
--@author Jacbo
--@shared
--@include safeNet.txt

require("safeNet.txt")
local net = safeNet
local afkTimeout = 120
if SERVER then
    local plys = {}
    
    local function doTimer(name, delay, cb)
        if timer.exists(name) then timer.adjust(name, delay)
        else timer.create(name, delay, 1, cb) end
    end
    
    local function updatePlayer(id, tabbed, afk, timing)
        local set = plys[id]
        if not set then
            plys[id] = {}
            set = plys[id]
        end
        if tabbed ~= nil then set[1] = tabbed end
        if afk ~= nil then set[2] = afk end
        if timing ~= nil then set[3] = timing end
        if not set[1] and not set[2] and not set[3] then
            plys[id] = nil
        end
    end
    
    net.receive("tabbed", function(_, ply)
        local id = ply:getSteamID()
        local tabbed = net.readBool()
        updatePlayer(id, tabbed)
        net.start("tabbed")
        net.writeString(id)
        net.writeBool(tabbed)
        net.send()
    end)
    
    local function afk(id, isAFK)
        if isAFK then
            if not plys[id] or not plys[id][2] then
                --[[net.start("afk")
                net.writeString(id)
                net.writeBool(true)
                net.send()]]
            end
        elseif not plys[id] or (plys[id] and plys[id][2]) then
            --[[net.start("afk")
            net.writeString(id)
            net.writeBool(false)
            net.send()]]
        end
    end
    
    net.receive("afk", function(_, ply)
        local id = ply:getSteamID()
        afk(id, false)
        --[[doTimer(id .. " afk", afkTimeout, function()
            afk(id, true)
            updatePlayer(id, nil, true)
        end)]]
    end)
    
    hook.add("KeyPress", "", function(ply)
        local id = ply:getSteamID()
        afk(id, false)
        updatePlayer(id, nil, false)
        --[[doTimer(id .. " afk", afkTimeout, function()
            afk(id, true)
            updatePlayer(id, nil, true)
        end)]]
    end)
    
    --[[hook.add("KeyRelease", "", function(ply)
        local id = ply:getSteamID()
        afk(id, false)
        updatePlayer(id, nil, false)
        doTimer(id .. " afk", afkTimeout, function()
            afk(id, true)
            updatePlayer(id, nil, true)
        end)
    end)]]
    
    local players = find.allPlayers()
    for _, ply in ipairs(players) do
        local id = ply:getSteamID()
        --[[doTimer(id .. " afk", afkTimeout, function()
            afk(id, true)
            updatePlayer(id, nil, true)
        end)]]
    end
    
    hook.add("PlayerDisconnected", "", function(ply)
        --local id = ply:getSteamID()
        --plys[id] = nil
        players = find.allPlayers()
        --timer.remove(id .. " afk")
    end)
    
    hook.add("PlayerInitialSpawn", "", function(ply)
        players = find.allPlayers()
        local id = ply:getSteamID()
        --[[doTimer(id .. " afk", afkTimeout, function()
            afk(id, true)
            updatePlayer(id, nil, true)
        end)]]
    end)
    
    timer.create("find players", 10, 0, function()
        players = find.allPlayers()
    end)
    
    timer.create("timing out", 1, 0, function()
        local i = 1
        while i < #players do
            local ply = players[i]
            if not ply or not ply:isValid() or not ply:isPlayer() then
                table.remove(players, i)
                continue
            end
            local id = ply:getSteamID()
            local set = plys[id]
            if not set then
                plys[id] = {}
                set = plys[id]
            end
            if ply:isTimingOut() then
                if not set[2] then
                    set[2] = true
                    net.start("timing")
                    net.writeString(id)
                    net.writeBool(true)
                    net.send()
                end
            elseif set[2] then
                set[2] = false
                net.start("timing")
                net.writeString(id)
                net.writeBool(false)
                net.send()
            end
            i = i + 1
        end
    end)
else--CLIENT
    local ringMats = {}
    local meshReady = false
    local timeout = 10
    
    local radius = 35
    local height = 10
    local rings = {}
    local ringMesh
    local function makeHolo()
        local holo = holograms.create(player():getPos(), Angle(), "models/hunter/plates/plate.mdl")
        holo:setColor(Color(255,255,255,254))
        holo:setMesh(ringMesh)
        holo:setMeshMaterial(ringMats[1])
        try(function()
            holo:setRenderBounds(Vector(-radius, -radius, 0), Vector(radius, radius, height))
        end)
        holo:suppressEngineLighting(true)
        return holo
    end
    
    --{{holo, tabbed, afk, timing, matID, ply, ang}}
    local plys = {}
    local holoQueue = {}
    --{{id, tabbed, afk, timing}}
    local plyQueue = {}
    
    local function doTimer(name, delay, cb)
        if timer.exists(name) then timer.adjust(name, delay)
        else timer.create(name, delay, 1, cb) end
    end
    
    local function removePlayer(id)
        timer.remove(id)
        timer.remove(id .. " mat")
        for i, set2 in ipairs(plyQueue) do
            if set2[1] == id then
                table.remove(plyQueue, i)
                break
            end
        end
        if plys[id] and plys[id][1] then
            plys[id][1]:remove()
        end
        plys[id] = nil
    end
    
    local function getMat(set)
        local mat = set[5]
        if set[2] then
            mat = mat - 1
            if mat <= 0 then return ringMats[1] end
        end
        if set[3] then
            mat = mat - 1
            if mat <= 0 then return ringMats[2] end
        end
        return ringMats[3]
    end
    
    local function createPlayers()
        if not meshReady then return end
        local i = 1
        while plyQueue[i] and holograms.canSpawn() do
            local set = plyQueue[i]
            local id = set[1]
            local ply = find.allPlayers(function(ent)
                return ent:getSteamID() == id
            end)[1]
            if ply and ply:isValid() and ply:isPlayer() then
                timer.remove(id)
                local holo = makeHolo()
                local t = {holo, set[2], set[3], set[4], 1, ply, 0}
                holo:setMeshMaterial(getMat(t))
                plys[id] = t
                timer.create(id .. " mat", 1, 0, function()
                    local set = plys[id]
                    set[5] = set[5] + 1
                    if set[5] > (set[2] and 1 or 0) + (set[3] and 1 or 0) + (set[4] and 1 or 0) then
                        set[5] = 1
                    end
                    set[1]:setMeshMaterial(getMat(set))
                end)
                table.remove(plyQueue, i)
            else
                i = i + 1
            end
        end
    end
    
    local function updatePlayer(id, tabbed, afk, timing)
        if plys[id] then
            local set = plys[id]
            if tabbed ~= nil then set[2] = tabbed end
            if afk ~= nil then set[3] = afk end
            if timing ~= nil then set[4] = timing end
            if not set[2] and not set[3] and not set[4] then
                removePlayer(id)
                return
            end
            if set[5] > (set[2] and 1 or 0) + (set[3] and 1 or 0) + (set[4] and 1 or 0) then
                set[5] = 1
            end
            set[1]:setMeshMaterial(getMat(set))
            return
        end
        for _, set in ipairs(plyQueue) do
            if set[1] == id then
                if tabbed ~= nil then set[2] = tabbed end
                if afk ~= nil then set[3] = afk end
                if timing ~= nil then set[4] = timing end
                if not set[2] and not set[3] and not set[4] then
                    removePlayer(id)
                    return
                end
                doTimer(id, timeout, function() removePlayer(id) end)
                return
            end
        end
        if tabbed == nil then tabbed = false end
        if afk == nil then afk = false end
        if timing == nil then timing = false end
        if not tabbed and not afk and not timing then return end
        table.insert(plyQueue, {id, tabbed, afk, timing})
        doTimer(id, timeout, function() removePlayer(id) end)
        createPlayers()
    end
    
    net.receive("tabbed", function()
        updatePlayer(net.readString(), net.readBool())
    end)
    
    net.receive("afk", function()
        updatePlayer(net.readString(), nil, net.readBool())
    end)
    
    net.receive("timing", function()
        updatePlayer(net.readString(), nil, nil, net.readBool())
    end)
    
    local netAFK = false
    local tabbedOut = false
    hook.add("think", "", function()
        createPlayers()
        local tabbed = not game.hasFocus()
        if tabbed ~= tabbedOut then
            tabbedOut = tabbed
            net.start("tabbed")
            net.writeBool(tabbed)
            net.send()
        end
        
        if netAFK then
            netAFK = false
            net.start("afk")
            net.send()
        end
        
        -- Move holos
        local keys = table.getKeys(plys)
        local i = 1
        local angChange = timer.frametime() * 10
        while keys[i] do
            local set = plys[keys[i]]
            local ply = set[6]
            if not ply or not ply:isValid() or not ply:isPlayer() then
                removePlayer(table.remove(keys, i))
                continue
            end
            local holo = set[1]
            set[7] = set[7] + angChange
            holo:setAngles(Angle(0, set[7], 0))
            holo:setPos(ply:getPos() + Vector(0, 0, 10))
            i = i + 1
        end
    end)
    
    hook.add("mousewheeled", "", function() netAFK = true end)
    hook.add("mousemoved", "", function() netAFK = true end)
    
    for i = 1, 3 do
        local mat = material.create("VertexLitGeneric")
        mat:setInt("$flags", 8192)
        table.insert(ringMats, mat)
    end
    
    render.createRenderTarget("tabbed out")
    render.createRenderTarget("afk")
    render.createRenderTarget("timing out")
    ringMats[1]:setTextureRenderTarget("$basetexture", "tabbed out")
    ringMats[2]:setTextureRenderTarget("$basetexture", "afk")
    ringMats[3]:setTextureRenderTarget("$basetexture", "timing out")
    
    hook.add("renderoffscreen", "make mats", function()
        local font = render.createFont("roboto", 100)
        render.selectRenderTarget("tabbed out")
        render.clear(Color(0,0,0,0))
        render.setRGBA(190, 190, 190, 180)
        render.drawRect(0, (1024 - 256) * 0.5, 1024, 256)
        render.setRGBA(255, 255, 255, 180)
        render.drawRect(0, (1024 - 256) * 0.5 - 10, 1024, 10)
        render.drawRect(0, (1024 - 256) * 0.5 + 256, 1024, 10)
        render.setRGBA(255, 255, 255, 255)
        render.setFont(font)
        render.drawSimpleText(512, 512, "TABBED OUT", 1, 1)
        
        render.selectRenderTarget("afk")
        render.clear(Color(0,0,0,0))
        render.setRGBA(190, 190, 190, 180)
        render.drawRect(0, (1024 - 256) * 0.5, 1024, 256)
        render.setRGBA(255, 255, 255, 180)
        render.drawRect(0, (1024 - 256) * 0.5 - 10, 1024, 10)
        render.drawRect(0, (1024 - 256) * 0.5 + 256, 1024, 10)
        render.setRGBA(255, 255, 255, 255)
        render.setFont(font)
        render.drawSimpleText(512, 512, "AFK", 1, 1)
        
        render.selectRenderTarget("timing out")
        render.clear(Color(0,0,0,0))
        render.setRGBA(255, 0, 0, 180)
        render.drawRect(0, (1024 - 256) * 0.5, 1024, 256)
        render.setRGBA(255, 255, 255, 180)
        render.drawRect(0, (1024 - 256) * 0.5 - 10, 1024, 10)
        render.drawRect(0, (1024 - 256) * 0.5 + 256, 1024, 10)
        render.setRGBA(255, 255, 255, 255)
        render.setFont(font)
        render.drawSimpleText(512, 512, "TIMING OUT", 1, 1)
        
        hook.remove("renderoffscreen", "make mats")
    end)
    
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
            while quotaAverage() > 0.002 do
                coroutine.yield()
            end
        end
        meshReady = true
        return true
    end)
    
    hook.add("think", "make ring", function()
        if makeRing() == true then
            hook.remove("think", "make ring")
        end
    end)
end