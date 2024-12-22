-- Use v3, it's better.

--@name Missing Model Yoinker
--@author Jacbo
--@shared
--@include safeNet.txt
--@include spawn_blocking.txt

require("safeNet.txt")
local net = safeNet
require("spawn_blocking.txt")

if SERVER then
    local funcs = {}
    local counter = 0
    net.receive("find", function(_, ply)
        local id = net.readString()
        local model = net.readData2()
        counter = counter + 1
        local func = coroutine.wrap(function(model, sendName, ply, id)
            coroutine.yield()
            local finished = false
            local plys = find.allPlayers()
            local players = {}
            for i = 1, #plys do
                if plys[i] ~= ply then
                    table.insert(players, math.random(1, #players), plys[i])
                end
            end
            --for counter2, player in ipairs(find.allPlayers()) do
            for counter2, player in ipairs(players) do
                if player and player:isValid() and player ~= ply then
                    local wait = true
                    local found = false
                    local response = false
                    net.receive(id .. "found" .. counter2, function(len)
                        print("Sent " .. model)
                        found = true
                        timer.remove(id .. "timeout")
                        net.start("found" .. id)
                        net.writeBool(true)
                        net.writeReceived()
                        net.send(ply)
                        finished = true
                        wait = false
                    end)
                    
                    net.receive(id .. "response" .. counter2, function()
                        response = net.readBool()
                        if response then
                            print("Found " .. model)
                            timer.adjust(id .. "timeout", 300)
                        else
                            wait = false
                        end
                    end)
                    
                    net.start("find")
                    net.writeString(tostring(id))
                    net.writeString(tostring(counter2))
                    net.writeData2(model)
                    net.send(player)
                    
                    timer.create(id .. "timeout", 10, 1, function() wait = false end)
                    
                    while wait do
                        coroutine.yield()
                        if found or (not player or not player:isValid()) then
                            break
                        end
                    end
                    timer.remove(id .. "timeout")
                    net.receive(id .. "found" .. counter2)
                    net.receive(id .. "response" .. counter2)
                    if finished then return true end
                end
            end
            net.start("found" .. id)
            net.writeBool(false)
            net.send(ply)
            return true
        end)
        func(model, sendName, ply, id)
        table.insert(funcs, {false, func})
    end)
    
    hook.add("think", "1", function()
        local i = 1
        local count = #funcs
        while i <= count do
            local tbl = funcs[i]
            if not tbl[1] then
                local func = tbl[2]
                if func() == true then
                    table.remove(funcs, i)
                    count = count - 1
                else
                    i = i + 1
                end
            end
        end
    end)
else--CLIENT
    if player() == owner() then
        -- Owner
        local function processVisMesh(meshTable, maxQuota, cb)
            local name = "loading vis mesh" .. math.rand(0, 1)
            local vismesh
            local loadmesh = coroutine.wrap(function() vismesh = mesh.createFromTable(meshTable, true) return true end)
            hook.add("think", name, function()
                while quotaAverage() < maxQuota do
                    if loadmesh() == true then
                        hook.remove("think", name)
                        cb(vismesh)
                        break
                    end
                end
            end)
        end
        
        local maxQuota = math.min(0.004, quotaMax() * 0.75)
        local meshes = {}
        local errorEnts = {}
        local funcs = {}
        local counter = 1
        local replacedEnts = {}
        timer.create("find errors", 3, 0, function()
            --Find errors
            local errors = find.all(function(ent)
                if ent:isWeapon() then return false end
                if ent:getMaterials()[1] ~= "models/error/new light1" then
                    return false
                end
                local model = ent:getModel()
                --if ent:getClass() ~= "gmod_wire_hologram" then return false end
                if model == "models/error.mdl" then
                    return false
                end
                return not table.hasValue(errorEnts, ent)
            end)
            
            table.add(errorEnts, errors)
            for _, err in ipairs(errors) do
                counter = counter + 1
                local func = coroutine.wrap(function(ent, id)
                    coroutine.yield()
                    local wait = true
                    net.receive("found" .. id, function(len)
                        if net.readBool() then
                            -- Found model
                            if ent and ent:isValid() then
                                print("Received")
                                local min = net.readVector()
                                local max = net.readVector()
                                net.readTable(function(meshtbl)
                                    try(function()
                                        for _, submesh in ipairs(meshtbl) do
                                            processVisMesh(submesh, maxQuota, function(msh)
                                                local holo = holograms.create(ent:getPos(), ent:getAngles(), "models/hunter/plates/plate.mdl")
                                                holo:setParent(ent)
                                                holo:setMesh(msh)
                                                holo:setRenderBounds(min, max)
                                                holo:setMaterial("models/debug/debugwhite")
                                            end)
                                        end
                                        ent:setColor(Color(0,0,0,0))
                                        table.insert(replacedEnts, ent)
                                    end)
                                    wait = false
                                end, maxQuota)
                            end
                        else
                            table.removeByValue(errorEnts, ent)
                            wait = false
                        end
                    end)
                    
                    if ent and ent:isValid() then
                        print("Requesting " .. ent:getModel())
                        net.start("find")
                        net.writeString(tostring(id))
                        net.writeData2(ent:getModel())
                        net.send()
                    end
                    
                    while wait do
                        coroutine.yield()
                        if not ent or not ent:isValid() then
                            table.removeByValue(errorEnts, ent)
                            break
                        end
                    end
                    net.receive("found" .. id)
                    return true
                end)
                func(err, counter)
                table.insert(funcs, {false, func})
            end
        end)
        
        hook.add("think", "2", function()
            local i = 1
            local count = #funcs
            while i <= count do
                local tbl = funcs[i]
                if not tbl[1] then
                    tbl[1] = true
                    local func = tbl[2]
                    if func() == true then
                        print("Removed")
                        table.remove(funcs, i)
                        count = count - 1
                    else
                        tbl[1] = false
                        i = i + 1
                    end
                end
            end
        end)
        
        hook.add("Removed", "", function()
            for _, ent in ipairs(replacedEnts) do
                if ent and ent:isValid() then
                    try(function()
                        ent:setColor(Color(255,255,255))
                    end)
                end
            end
        end)
    else
        -- Not owner
        local maxQuota = math.min(0.002, quotaMax() * 0.75)
        local counter = 0
        local math_min = math.min
        local math_max = math.max
        local table_insert = table.insert
        
        local queue = {}
        
        net.receive("find", function()
            local sendID1 = net.readString()
            local sendID2 = net.readString()
            local model = net.readData2()
            local meshtbl = mesh.getModelMeshes(model)
            
            while quotaAverage() >= maxQuota do coroutine.yield() end
            
            local foundModel = #meshtbl > 0
            net.start(sendID1 .. "response" .. sendID2)
            net.writeBool(foundModel)
            net.send()
            
            if foundModel then
                local process = coroutine.wrap(function(meshtbl)
                    coroutine.yield()
                    local min = Vector(math.huge)
                    local max = Vector(-math.huge)
                    local newtbl = {}
                    for _, sub in pairs(meshtbl) do
                        local tbl = {}
                        for _, vert in pairs(sub.triangles) do
                            while quotaAverage() >= maxQuota do
                                coroutine.yield()
                            end
                            local pos = vert.pos
                            min = Vector(math_min(min[1], pos[1]), math_min(min[2], pos[2]), math_min(min[3], pos[3]))
                            max = Vector(math_max(max[1], pos[1]), math_max(max[2], pos[2]), math_max(max[3], pos[3]))
                            table_insert(tbl, {
                                normal = vert.normal,
                                pos = pos,
                                tangent = vert.tangent
                            })
                        end
                        table_insert(newtbl, tbl)
                    end
                    return newtbl, min, max
                end)
                
                process(meshtbl)
                
                table_insert(queue, {true, sendID1, sendID2, process})
                
                --[[counter = counter + 1
                local id = counter
                hook.add("think", "process" .. counter, function()
                    local tbl, min, max = process()
                    if tbl then
                        hook.remove("think", "process" .. counter)
                        
                        local stream = net.stringstream()
                        stream:writeVector(min)
                        stream:writeVector(max)
                        stream:writeInt8(1)
                        stream:writeType(tbl, function()
                            net.start(sendID1 .. "found" .. sendID2)
                            net.writeStringStream(stream)
                            net.send()
                        end, maxQuota)
                    end
                end)]]
            end
        end)
        
        hook.add("think", "queue", function()
            local item = queue[1]
            if item then
                if item[1] then
                    local tbl, min, max = item[4]()
                    if tbl then
                        item[1] = false
                        
                        local stream = net.stringstream()
                        stream:writeVector(min)
                        stream:writeVector(max)
                        stream:writeInt8(1)
                        stream:writeType(tbl, function()
                            net.start(item[2] .. "found" .. item[3])
                            net.writeStringStream(stream)
                            net.send()
                            table.remove(queue, 1)
                        end, maxQuota)
                    end
                end
            end
        end)
    end
end