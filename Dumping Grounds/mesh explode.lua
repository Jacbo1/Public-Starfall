-- Spawn this on a prop and watch the mesh get spiky as each vertex is offset by a random amount.
-- Works on vehicles I'm pretty sure.

--@name Mesh Explode
--@author Jacbo
--@shared

if SERVER then
    local ent = chip():isWeldedTo()
    
    local strength = 1
    
    local min, max = ent:getPhysicsObject():getAABB()
    min = min or Vector(0,0,0)
    max = max or Vector(0,0,0)
    local boxSize = max - min
    local holos = {}
    for i, mat in pairs(ent:getMaterials()) do
        local holo = holograms.create(ent:getPos(), ent:getAngles(), "models/hunter/plates/plate.mdl", Vector(1, 1, 1))
        holo:setParent(ent)
        table.insert(holos, holo:entIndex())
    end
    
    ent:setColor(Color(0,0,0,0))
    hook.add("Removed", "", function()
        ent:setColor(Color(255,255,255,255))
        hook.remove("Removed", "")
    end)
    net.receive("mesh stretcher", function(_, ply)
        net.start("mesh stretcher")
        net.writeFloat(strength)
        net.writeUInt(ent:entIndex(), 13)
        net.writeUInt(#holos, 8)
        for i, holoi in pairs(holos) do
            net.writeUInt(holoi, 13)
        end
        net.send(ply)
    end)
else--Client
    local maxCpu = math.min(0.004, quotaMax() * 0.8)
    net.start("mesh stretcher")
    net.send()
    net.receive("mesh stretcher", function()
        local strength = net.readFloat(strength)
        local ent = entity(net.readUInt(13))
        local boxSize = ent:obbSize()
        local center = ent:obbCenter()
        local holoCount = net.readUInt(8)
        local holos = {}
        for i = 1, holoCount do
            table.insert(holos, entity(net.readUInt(13)):toHologram())
        end
        
        local maxStretch = (boxSize / 2):getLength() * strength
        
        timer.simple(1, function()
            local model = ent:getModel()
            local ready = true
            
            local maxValue = Vector(0,0,0)
            local minValue = Vector(1,1,1)
            local max = Vector(1,1,1):getLength()
            --Main loop
            local makeMesh = coroutine.wrap(function()
                 --Make model
                local vertices = {}
                for mat, tabl in pairs(mesh.getModelMeshes(model, 0, 0)) do
                    local mins, maxs = Vector(math.huge), Vector(-math.huge)
                    while not ready do
                        coroutine.yield()
                    end
                    if quotaAverage() >= maxCpu then coroutine.yield() end
                    local meshTable = {}
                    for i, vertex in pairs(tabl.triangles) do
                        local vstring = vertex.pos[1] .. "," .. vertex.pos[2] .. "," .. vertex.pos[3]
                        local newPos = vertices[vstring]
                        if not newPos then
                            local dir = vertex.pos - center
                            newPos = vertex.pos + (vertex.pos - center):getNormalized() * math.rand(0, maxStretch)
                            vertices[vstring] = newPos
                            if newPos[1] < mins[1] then mins[1] = newPos[1] end
                            if newPos[2] < mins[2] then mins[2] = newPos[2] end
                            if newPos[3] < mins[3] then mins[3] = newPos[3] end
                            if newPos[1] > maxs[1] then maxs[1] = newPos[1] end
                            if newPos[2] > maxs[2] then maxs[2] = newPos[2] end
                            if newPos[3] > maxs[3] then maxs[3] = newPos[3] end
                        end
                        table.insert(meshTable, {pos = newPos, tangent = vertex.tangent, u = vertex.u, v = vertex.v, normal = vertex.normal})
                        --table.insert(meshTable, {pos = newPos, tangent = vertex.tangent, u = math.rand(0,1), v = math.rand(0,1), normal = vertex.normal})
                        if quotaAverage() >= maxCpu then coroutine.yield() end
                    end
                    --Make mesh
                    local texture = material.create("VertexLitGeneric")
                    texture:setTexture("$basetexture", tabl.material)
                    local newMesh
                    ready = false
                    local loadmesh = coroutine.wrap(function() newMesh = mesh.createFromTable(meshTable, true) return true end)
                    if quotaAverage() >= maxCpu then coroutine.yield() end
                    hook.add("think","loadingMesh",function()
                        while quotaUsed() < maxCpu do
                            if loadmesh() == true then
                                holos[mat]:setMesh(newMesh)
                                holos[mat]:setMeshMaterial(texture)
                                holos[mat]:setRenderBounds(mins, maxs)
                                hook.remove("think","loadingMesh")
                                print(tabl.material)
                                ready = true
                                break
                            end
                        end
                    end)
                end
                return true
            end)
            --
            hook.add("think", "", function()
                if makeMesh() == true then
                    hook.remove("think", "")
                    print("Done")
                end
            end)
        end)
    end)
end