-- Use the missing model yoinker. This is older and just puts a box the size of the missing model's hull.

--@name Anti-error hull
--@author Jacbo
--@shared
--@include better_coroutines.txt
--@include funcs.txt

local funcs = require("funcs.txt")
local corlib = require("better_coroutines.txt")

if SERVER then
    local missing = {}
    local players = {}
    
    net.receive("ping", function(_, ply)
        table.insert(players, ply)
    end)
    
    hook.add("PlayerDisconnected", "", function(ply)
        table.removeByValue(players, ply)
    end)
    
    net.receive("missing", function(_, ply)
        local ents = net.readTable()
        local result = {}
        for _, ent in ipairs(ents) do
            try(function()
                if ent and ent:isValid() then
                    if ent:getMaterials()[1] == "models/error/new light1" then
                        table.insert(missing, {ent, ply})
                    else
                        result[ent:getModel()] = {ent:obbSize(), ent:obbCenter()}
                    end
                end
            end)
        end
        
        net.start("found")
        net.writeTable(result)
        net.send(ply)
    end)
    
    --Ask clients
    local plyIndex = 1
    local ready = true
    hook.add("tick", "send missing", function()
        if ready then
            --Send
            if #missing ~= 0 then
                if missing[1][1] and missing[1][1]:isValid() and missing[1][2] and missing[1][2]:isValid() then
                    if plyIndex > #players then
                        plyIndex = 1
                        table.remove(missing, 1)
                        return
                    end
                    if players[plyIndex] and players[plyIndex]:isValid() then
                        if players[plyIndex] ~= missing[1][2] then
                            try(function()
                                --print("Sending")
                                net.start("check this")
                                net.writeEntity(missing[1][1])
                                net.send(players[plyIndex])
                                --print("Sending to " .. players[plyIndex]:getName())
                                ready = false
                                timer.create("timeout", 5, 1, function()
                                    ready = true
                                    net.start("ping")
                                    net.send(table.remove(players, plyIndex))
                                end, function(err)
                                    print(err)
                                end)
                            end)
                        end
                    else
                        table.remove(players, plyIndex)
                        return
                    end
                else
                    table.remove(missing, 1)
                    return
                end
            end
        end
    end)
    
    net.receive("what was found", function(_, ply)
        timer.remove("timeout")
        local result = net.readTable()
        if result == {} then
            --Not found
            plyIndex = plyIndex + 1
            --print("Not found")
        else
            --Found
            plyIndex = 1
            if missing[1][2] and missing[1][2]:isValid() then
                net.start("found")
                net.writeTable(result)
                net.send(missing[1][2])
                table.remove(missing, 1)
                --print("Found")
            end
        end
        ready = true
    end)
else--CLIENT
    net.start("ping")
    net.send()
    net.receive("ping", function()
        net.start("ping")
        net.send()
    end)
    
    local quotaMax = math.min(0.001, quotaMax() * 0.75)
    if player() == owner() then
    
    local holos = {}
    local holoQueue = {}
    --{size, offset, parent}
    hook.add("tick", "make holos", function()
        if #holoQueue ~= 0 and holograms.canSpawn() then
            try(function()
                local data = table.remove(holoQueue, 1)
                if data[3] and data[3]:isValid() then
                    --models/holograms/cube.mdl
                    local holo = holograms.create(data[3]:localToWorld(data[2]), data[3]:getAngles(), "models/holograms/cube.mdl", data[1] / 12)
                    --holo:setMaterial("models/wireframe")
                    --holo:setColor(Color(0,180,0))
                    holo:setColor(Color(255,255,255,100))
                    holo:setParent(data[3])
                    data[3]:setColor(Color(0,0,0,0))
                    table.insert(holos, {holo, data[3]})
                end
            end)
        end
    end)
    
    --size, offset
    local modelSizes = {}
    local errorEnts = {}
    local entQueue = {}
    timer.create("find errors", 3, 0, function()
        --Find errors
        local newErrorEnts = find.all(function(ent)
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
        
        --Find new models
        local newModels = {}
        for i = 1, #newErrorEnts do
            local ent = newErrorEnts[i]
            local model = ent:getModel()
            if modelSizes[model] then
                table.insert(holoQueue, {modelSizes[model][1], modelSizes[model][2], ent})
            else
                table.insert(entQueue, ent)
                if not table.hasValue(newModels, model) then
                    table.insert(newModels, ent)
                end
            end
        end
        
        --Network errors
        if #newModels ~= 0 then
            --printTable(newModels)
            
            net.start("missing")
            net.writeTable(newModels)
            net.send()
        end
        
        table.add(errorEnts, newErrorEnts)
        --table.add(entQueue, newErrorEnts)
    end)
    
    net.receive("found", function()
        for key, data in pairs(net.readTable()) do
            modelSizes[key] = funcs.copy(data)
        end
    end)
    
    --Delete invalid ents
    local index = 1
    local index2 = 1
    local index3 = 1
    hook.add("think", "remove invalid", function()
        --Holos
        if #holos ~= 0 then
            if holos[index3][2] and holos[index3][2]:isValid() then
                index3 = index3 % #holos + 1
            else
                holos[index3][1]:remove()
                table.remove(holos, index3)
                if index3 > #holos then
                    index3 = 1
                end
            end
        end
        
        --Ent queue
        if #entQueue ~= 0 then
            if entQueue[index2] and entQueue[index2]:isValid() then
                local model = entQueue[index2]:getModel()
                if modelSizes[model] then
                    table.insert(holoQueue, {modelSizes[model][1], modelSizes[model][2], entQueue[index2]})
                    table.remove(entQueue, index2)
                    if index2 > #entQueue then
                        index2 = 1
                    end
                else
                    index2 = index2 % #entQueue + 1
                end
            else
                table.remove(entQueue, index2)
                if index2 > #entQueue then
                    index2 = 1
                end
            end
        end
        
        --Filter
        if #errorEnts ~= 0 then
            if errorEnts[index] and errorEnts[index]:isValid() then
                index = index % #errorEnts + 1
            else
                table.remove(errorEnts, index)
                if index > #errorEnts then
                    index = 1
                end
            end
        end
    end)
    
    hook.add("Removed", "", function()
        for _, t in ipairs(holos) do
            local ent = t[2]
            if ent and ent:isValid() then
                try(function()
                    ent:setColor(Color(255,255,255))
                end)
            end
        end
    end)
    end
    
    net.receive("check this", function()
        local ent = net.readEntity()
        local result = {}
        if ent and ent:isValid() then
            if ent:getMaterials()[1] ~= "models/error/new light1" then
                result[ent:getModel()] = {ent:obbSize(), ent:obbCenter()}
            end
        end
        net.start("what was found")
        net.writeTable(result)
        net.send()
    end)
end