-- Downloads (yoinks) models your client is missing from the server or other clients. Also grabs the physics mesh.
-- Requires you to setup autoinjector files. Iirc this is the best version and works very well.
-- READ libs\autoinjector files\README.md

--@name Missing Model Yoinker 3
--@author Jacbo
--@include safeNet.txt
--@include cor_wrap.txt
--@include spawn_blocking.txt
--@include libs/autoinjector.txt

local net = require "safeNet.txt"
require "cor_wrap.txt"
require "libs/autoinjector.txt"

if SERVER then
    local maxQuota = math.min(0.0005, quotaMax() - 0.0005)
    local table_insert = table.insert
    
    net.receive("phys", function()
        local models = {}
        for i = 1, net.readUInt8() do
            table_insert(models, net.readString())
        end
        
        for _, model in ipairs(models) do
            local ent
            try(function()
                ent = prop.create(Vector(), Angle(), model, true)
            end)
            if not ent or not ent:isValid() or ent:getOwner() ~= owner() then continue end
            ent:setNoDraw(true)
            
            local physobj = ent:getPhysicsObject()
            if not physobj or not physobj:isValid() then
                ent:remove()
                continue
            end
            
            local tbl = {}
            local convexes = physobj:getMeshConvexes()
            for _, convex in ipairs(convexes) do
                while cpuUsed() > maxQuota do coroutine.yield() end
                local tbl2 = {}
                for _, vertex in ipairs(convex) do
                    table_insert(tbl2, vertex.pos)
                end
                table_insert(tbl, tbl2)
            end
            
            ent:remove()
            
            local stream = net.stringstream()
            stream:writeString(model)
            stream:writeUInt8(1)
            stream:writeType(tbl, function()
                net.start("phys")
                net.writeStringStream(stream)
                net.send(owner())
            end, maxQuota, false, false)
        end
    end)
    
    net.receive("find", function()
        local models = {}
        for i = 1, net.readUInt8() do
            table_insert(models, net.readString())
        end
           
        for _, model in ipairs(models) do 
            local check
            check = function()
                -- Ask clients if they have this model
                net.start("check")
                net.writeString(model)
                net.send()
                
                -- Ask again if none respond
                timer.create(model, 30, 0, check)
            
                net.receive(model, function(_, ply)
                    -- A client found the model
                    print("Found " .. model)
                    
                    net.receive(model)
                    
                    -- Ask that client to send the mesh
                    net.start("mesh")
                    net.writeString(model)
                    net.send(ply)
                    
                    -- Restart if they don't respond
                    timer.create(model, 120, 0, check)
                    net.receive("pump " .. model, function()
                        timer.create(model, 120, 0, check)
                    end)
                    
                    net.receive("mesh " .. model, function()
                        -- Received mesh
                        print("Sending " .. model)
                        net.receive(model)
                        net.receive("mesh " .. model)
                        net.receive("pump " .. model)
                        timer.remove(model)
                        
                        -- Send to owner
                        net.start("found")
                        net.writeString(model)
                        net.writeReceived()
                        net.send(owner(), nil, true)
                    end)
                end)
            end
            
            check()
        end
    end)
else -- CLIENT
    local maxQuota = math.min(0.002, quotaMax() - 0.0005)
    
    if player() == owner() then
        -- OWNER CLIENT
        if injectLua("physObjs", chip().enableCustomCollisions) then return end
        
        require "spawn_blocking.txt"
        
        maxQuota = math.min(0.002, quotaMax() * 0.75)
        
        local queuedEnts = {}
        local queuedModels = {}
        local models = {}
        local foundEnts = {}
        
        local foundEntsPhys = {}
        local queuedEntsPhys = {}
        local queuedPhys = {}
        local physObjs = {}
        
        hook.add("EntityRemoved", "", function(ent)
            if foundEnts[ent] then
                -- This ent has holos on it so delete them
                for _, holo in ipairs(foundEnts[ent]) do
                    holo:remove()
                end
                foundEnts[ent] = nil
                return
            end
            
            if ent == chip() then
                -- Make the replaced ents visible again
                for ent, _ in pairs(foundEnts) do
                    ent:setNoDraw(false)
                end
                return
            end
            
            if ent then
                queuedEnts[ent] = nil
            end
        end)
        
        local function setMesh(model, ent)
            if ent then
                local data = models[model]
                local meshes = data.meshes
                local min = data.min
                local max = data.max
                if ent:isValid() then
                    ent:setNoDraw(true)
                    foundEnts[ent] = { }
                    for _, submesh in ipairs(meshes) do
                        local holo = holograms.create(ent:getPos(), ent:getAngles(), "models/hunter/plates/plate.mdl")
                        table.insert(foundEnts[ent], holo)
                        holo:setMesh(submesh)
                        holo:setRenderBounds(min, max)
                        holo:setMaterial("models/debug/debugwhite")
                        holo:setParent(ent)
                    end
                end
                queuedEnts[ent] = nil
                return
            end
            
            for _, ent in ipairs(queuedModels[model]) do
                if ent then
                    setMesh(model, ent)
                end
            end
            
            queuedModels[model] = nil
        end
        
        local function setPhysObj(model, ent)
            if ent then
                ent:physicsInitMultiConvex(physObjs[model])
                ent:enableCustomCollisions(true)
                queuedEntsPhys[ent] = nil
                foundEntsPhys[ent] = true
                return
            end
            
            local tbl = physObjs[model]
            for _, ent in ipairs(queuedPhys[model]) do
                if ent and ent:isValid() then
                    setPhysObj(model, ent)
                end
            end
            
            queuedPhys[model] = nil
        end
        
        local function checkEnts(errors)
            local send = {}
            local sendPhys = {}
            
            -- Loop through found errors
            for _, ent in ipairs(errors) do
                local model = ent:getModel()
                
                -- Physics object
                if not foundEntsPhys[ent] then
                    if physObjs[model] then
                        setPhysObj(model, ent)
                        goto CHECK_MESH
                    end
                    
                    queuedEntsPhys[ent] = true
                    if queuedPhys[model] then
                        table.insert(queuedPhys[model], ent)
                        goto CHECK_MESH
                    end
                    
                    table.insert(sendPhys, model)
                    queuedPhys[model] = { ent }
                end
                
                ::CHECK_MESH::
                -- Mesh
                if foundEnts[ent] then continue end
                if models[model] then
                    -- We already received this mesh
                    foundEnts[ent] = true
                    corWrap(setMesh, model, ent)
                    continue
                end
                
                queuedEnts[ent] = true
                
                if queuedModels[model] then
                    -- This mesh is already queued
                    table.insert(queuedModels[model], ent)
                    continue
                end
                
                -- Request new mesh
                table.insert(send, model)
                queuedModels[model] = { ent }
            end
            
            if not table.isEmpty(send) then
                net.start("find")
                net.writeUInt8(#send)
                for _, model in ipairs(send) do
                    print("Requesting " .. model)
                    net.writeString(model)
                end
                net.send()
            end
            
            if not table.isEmpty(sendPhys) then
                net.start("phys")
                net.writeUInt8(#sendPhys)
                for _, model in ipairs(sendPhys) do
                    net.writeString(model)
                end
                net.send()
            end
        end
        
        --[[checkEnts(find.all(function(ent)
                if ent:isWeapon() then return false end
                if ent:getMaterials()[1] ~= "models/error/new light1" then
                    return false
                end
                local model = ent:getModel()
                if model == "models/error.mdl" then
                    return false
                end
                return (not foundEnts[ent] and not queuedEnts[ent]) or (not foundEntsPhys[ent] and not queuedEntsPhys[ent])
            end))]]
        
        timer.create("find errors", 3, 0, function()
            -- Find error models
            checkEnts(find.all(function(ent)
                if ent:isWeapon() then return false end
                if ent:getMaterials()[1] ~= "models/error/new light1" then
                    return false
                end
                local model = ent:getModel()
                if model == "models/error.mdl" then
                    return false
                end
                return (not foundEnts[ent] and not queuedEnts[ent]) or (not foundEntsPhys[ent] and not queuedEntsPhys[ent])
            end))
        end)
            
        --[[hook.add("NetworkEntityCreated", "", function(ent)
            if ent:isWeapon() then return false end
            if ent:getMaterials()[1] ~= "models/error/new light1" then return end
            local model = ent:getModel()
            if model == "models/error.mdl" then return end
            if (not foundEnts[ent] and not queuedEnts[ent]) or (not foundEntsPhys[ent] and not queuedEntsPhys[ent]) then
                checkEnts({ent})
            end
        end)]]
        
        local function processVisMesh(meshTable, maxQuota)
            local name = "loading vis mesh" .. math.rand(0, 1)
            local vismesh
            local loadmesh = coroutine.wrap(function() vismesh = mesh.createFromTable(meshTable, true) return true end)
            
            while true do
                while cpuUsed() < maxQuota do
                    if loadmesh() == true then
                        hook.remove("think", name)
                        return vismesh
                    end
                end
                coroutine.yield()
            end
        end
        
        net.receive("phys", function()
            local model = net.readString()
            net.readType(function(tbl)
                physObjs[model] = tbl
                setPhysObj(model)
            end)
        end)
        
        net.receive("found", function(length)
            local stream = net.stringstream(net.readData(length))
            local model = stream:readString()
            print("Received " .. model)
            local entExists = false
            if queuedModels[model] then
                for _, ent in ipairs(queuedModels[model]) do
                    if ent and ent:isValid() then
                        entExists = true
                        break
                    end
                end
            end
            
            if not entExists then
                return
            end
            
            local min = stream:readVector()
            local max = stream:readVector()
            
            stream:readType(function(meshTable)
                -- Construct mesh
                corWrap(function()
                    local t = {
                        meshes = {},
                        min = min,
                        max = max
                    }
                    
                    print("Processing " .. model)
                    for _, submesh in ipairs(meshTable) do
                        table.insert(t.meshes, processVisMesh(submesh, maxQuota))
                    end
                    print("Processed " .. model)
                    
                    models[model] = t
                    setMesh(model)
                end)
            end, maxQuota)
        end)
    else
        -- NON-OWNER CLIENT
        
        local checkQueue = {}
        net.receive("check", function()
            -- Check if this client has the model
            table.insert(checkQueue, net.readString())
            --[[local model = net.readString()
            if not table.isEmpty(mesh.getModelMeshes(model)) then
                -- Add a random delay to help distribute across other clients
                timer.simple(math.rand(0, 1), function()
                    net.start(model)
                    net.send()
                end)
            end]]
        end)
        
        timer.create("check", 1, 0, function()
            if #checkQueue == 0 then return end
            local model = table.remove(checkQueue, 1)
            if not table.isEmpty(mesh.getModelMeshes(model)) then
                -- Add a random delay to help distribute across other clients
                timer.simple(math.rand(0, 1), function()
                    net.start(model)
                    net.send()
                end)
            end
        end)
        
        local math_min = math.min
        local math_max = math.max
        local table_insert = table.insert
        
        local running = false
        net.receive("mesh", function()
            local model = net.readString()
            
            -- Pump messages so the server doesn't time us out
            local function pump()
                net.start("pump " .. model)
                net.send()
            end
            
            timer.create("pump " .. model, 60, 0, pump)
            
            -- Wait until no other meshes are being processed
            while running do
                coroutine.yield()
            end
            running = true
            
            local meshtbl = mesh.getModelMeshes(model)
            
            -- Extract the important stuff
            local minx, miny, minz = math.huge, math.huge, math.huge
            local maxx, maxy, maxz = -math.huge, -math.huge, -math.huge
            local newtbl = {}
            for _, sub in pairs(meshtbl) do
                local tbl = {}
                for _, vert in pairs(sub.triangles) do
                    while cpuUsed() >= maxQuota do
                        coroutine.yield()
                    end
                    local pos = vert.pos
                    
                    -- Set min and max bounds
                    minx = math_min(minx, pos[1])
                    miny = math_min(miny, pos[2])
                    minz = math_min(minz, pos[3])
                    maxx = math_max(maxx, pos[1])
                    maxy = math_max(maxy, pos[2])
                    maxz = math_max(maxz, pos[3])
                    
                    table_insert(tbl, {
                        normal = vert.normal,
                        pos = pos,
                        tangent = vert.tangent
                    })
                end
                table_insert(newtbl, tbl)
            end
            
            -- Send the mesh table back
            local stream = net.stringstream()
            stream:writeVector(Vector(minx, miny, minz))
            stream:writeVector(Vector(maxx, maxy, maxz))
            stream:writeType(newtbl, function()
                timer.remove("pump " .. model)
                pump()
                net.start("mesh " .. model)
                net.writeStringStream(stream)
                net.send(nil, nil, true)
                running = false
            end, maxQuota)
        end)
    end
end