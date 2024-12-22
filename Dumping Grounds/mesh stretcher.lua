-- Spawn this on a prop and watch the mesh get distorted. Affects the physics mesh too.

--@name Mesh Stretcher
--@author Jacbo
--@shared

if SERVER then
    local ent = chip():isWeldedTo()
    constraint.breakAll(chip())
    chip():setFrozen(true)
    chip():setPos(Vector())
    
    local boxSize = ent:obbSize()
    local center = ent:obbCenter()
    local cornerOffsets = {}
    local strength = 0.5
    for i = 1, 8 do
        table.insert(cornerOffsets, Vector(math.rand(-boxSize.x * strength, boxSize.x * strength), math.rand(-boxSize.y * strength, boxSize.y * strength), math.rand(-boxSize.z * strength, boxSize.z * strength)))
    end
    
    local doPhysMesh = true
    
    local physObject = ent:getPhysicsObject()
    local physMesh = physObject:getMeshConvexes()
    local plainMesh = {}
    local customProp
    if doPhysMesh then
        for v, k in pairs(physMesh) do
            local piece = {}
            for v1, k1 in pairs(k) do
                if not k1.pos then
                    continue
                end
                local posValue = (k1.pos - center) / boxSize + Vector(0.5)
                local newPos = k1.pos
                        + cornerOffsets[1] * ((1 - posValue.x) * (1 - posValue.y) * (1 - posValue.z))
                        + cornerOffsets[2] * ((1 - posValue.x) * (1 - posValue.y) * posValue.z)
                        + cornerOffsets[3] * ((1 - posValue.x) * posValue.y * (1 - posValue.z))
                        + cornerOffsets[4] * ((1 - posValue.x) * posValue.y * posValue.z)
                        + cornerOffsets[5] * (posValue.x * (1 - posValue.y) * (1 - posValue.z))
                        + cornerOffsets[6] * (posValue.x * (1 - posValue.y) * posValue.z)
                        + cornerOffsets[7] * (posValue.x * posValue.y * (1 - posValue.z))
                        + cornerOffsets[8] * (posValue.x * posValue.y * posValue.z)
                if not table.hasValue(piece,newPos) then
                    table.insert(piece, newPos)
                end
            end
            table.insert(plainMesh, piece)
        end
    end
    
    if doPhysMesh then
        customProp = prop.createCustom(ent:getPos(), ent:getAngles(), plainMesh, false)
        customProp:setMaterial("particle/warp1_warp")
        customProp:setMass(ent:getMass())
        customProp:setPhysMaterial(ent:getPhysMaterial())
    
        ent:setFrozen(1)
        ent:setNocollideAll(1)
        print("Changing physmesh")
    else
        print("Not changing physmesh")
    end
    
    local min, max = ent:getPhysicsObject():getAABB()
    min = min or Vector(0,0,0)
    max = max or Vector(0,0,0)
    local boxSize = max - min
    local holos = {}
    for i, mat in pairs(ent:getMaterials()) do
        local holo = holograms.create(ent:getPos(), ent:getAngles(), "models/hunter/plates/plate.mdl", Vector(1, 1, 1))
        if doPhysMesh then
            holo:setParent(customProp)
        else
            holo:setParent(ent)
        end
        table.insert(holos, holo:entIndex())
    end
    
    ent:setColor(Color(0,0,0,0))
    hook.add("Removed", "", function()
        ent:setColor(Color(255,255,255,255))
        hook.remove("Removed", "")
    end)
    net.receive("mesh stretcher", function(_, ply)
        timer.simple(2, function()
        net.start("mesh stretcher")
        net.writeTable(cornerOffsets)
        net.writeVector(boxSize)
        --net.writeUInt(ent:entIndex(), 13)
        net.writeEntity(ent)
        net.writeUInt(#holos, 8)
        for i, holoi in pairs(holos) do
            net.writeUInt(holoi, 13)
        end
        --net.writeFloat(boxSize.x)
        --net.writeFloat(boxSize.y)
        --net.writeFloat(boxSize.z)
        --net.writeEntity(holo)
        net.writeBool(doPhysMesh)
        if doPhysMesh then
            net.writeEntity(customProp)
        end
        net.send(ply)
        end)
    end)
    
    net.receive("done", function(_, ply)
        ent:setFrozen(true)
        ent:setPos(Vector(0,0,0))
    end)
else--Client
    local maxCpu = math.min(0.004, quotaMax() * 0.5)
    --[[local cornerOffsets = {
        Vector(0, 0, 0), -- -1 -1 -1
        Vector(0, 0, 0), -- -1 -1 1
        Vector(0, 0, 0), -- -1 1 -1
        Vector(0, 0, 0), -- -1 1 1
        Vector(0, 0, 0), -- 1 -1 -1
        Vector(0, 0, 0), -- 1 -1 1
        Vector(0, 0, 0), -- 1 1 -1
        Vector(0, 0, 0) -- 1 1 1
    }]]
    --[[local a = 47.45
    local cornerOffsets = {
        Vector(0, 0, 0), -- -1 -1 -1
        Vector(a, a, 0), -- -1 -1 1
        Vector(0, 0, 0), -- -1 1 -1
        Vector(a, -a, 0), -- -1 1 1
        Vector(0, 0, 0), -- 1 -1 -1
        Vector(-a, a, 0), -- 1 -1 1
        Vector(0, 0, 0), -- 1 1 -1
        Vector(-a, -a, 0) -- 1 1 1
    }]]
    net.start("mesh stretcher")
    net.send()
    net.receive("mesh stretcher", function()
        local cornerOffsets = net.readTable()
        local boxSize = net.readVector()
        --local ent = entity(net.readUInt(13))
        net.readEntity(function(ent)
        local center = ent:obbCenter()
        local holoCount = net.readUInt(8)
        local holos = {}
        for i = 1, holoCount do
            table.insert(holos, entity(net.readUInt(13)):toHologram())
        end
        local doPhysMesh = net.readBool()
        --local customProp
        --[[if doPhysMesh then
            customProp = net.readEntity()
        end
        --local boxSize = Vector(net.readFloat(), net.readFloat(), net.readFloat())
        --local boxSize = ent:obbSize()
        --for i = 1, 8 do cornerOffsets[i] = Vector(math.rand(-boxSize.x / 2, boxSize.x / 2), math.rand(-boxSize.y / 2, boxSize.y / 2), math.rand(-boxSize.z / 2, boxSize.z / 2)) end
        timer.simple(1, function()]]
        net.readEntity(function(customProp)
            local model = ent:getModel()
            local ready = true
            
            local maxValue = Vector(0,0,0)
            local minValue = Vector(1,1,1)
            local max = Vector(1,1,1):getLength()
            --Main loop
            local makeMesh = coroutine.wrap(function()
                 --Make model
                for mat, tabl in pairs(mesh.getModelMeshes(model, 0, 0)) do
                    local mins, maxs = Vector(math.huge), Vector(-math.huge)
                    while not ready do
                        coroutine.yield()
                    end
                    if quotaAverage() >= maxCpu then coroutine.yield() end
                    local meshTable = {}
                    for i, vertex in pairs(tabl.triangles) do
                        local posValue = (vertex.pos - center) / boxSize + Vector(0.5)
                        local newPos = vertex.pos
                            + cornerOffsets[1] * ((1 - posValue.x) * (1 - posValue.y) * (1 - posValue.z))
                            + cornerOffsets[2] * ((1 - posValue.x) * (1 - posValue.y) * posValue.z)
                            + cornerOffsets[3] * ((1 - posValue.x) * posValue.y * (1 - posValue.z))
                            + cornerOffsets[4] * ((1 - posValue.x) * posValue.y * posValue.z)
                            + cornerOffsets[5] * (posValue.x * (1 - posValue.y) * (1 - posValue.z))
                            + cornerOffsets[6] * (posValue.x * (1 - posValue.y) * posValue.z)
                            + cornerOffsets[7] * (posValue.x * posValue.y * (1 - posValue.z))
                            + cornerOffsets[8] * (posValue.x * posValue.y * posValue.z)
                        if newPos[1] < mins[1] then mins[1] = newPos[1] end
                        if newPos[2] < mins[2] then mins[2] = newPos[2] end
                        if newPos[3] < mins[3] then mins[3] = newPos[3] end
                        if newPos[1] > maxs[1] then maxs[1] = newPos[1] end
                        if newPos[2] > maxs[2] then maxs[2] = newPos[2] end
                        if newPos[3] > maxs[3] then maxs[3] = newPos[3] end
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
                                if holos[mat] then
                                    holos[mat]:setMesh(newMesh)
                                    holos[mat]:setMeshMaterial(texture)
                                    holos[mat]:setRenderBounds(mins, maxs)
                                    print(tabl.material)
                                end
                                hook.remove("think","loadingMesh")
                                ready = true
                                break
                            else
                                --break
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
                    net.start("done")
                    net.send()
                end
            end)
        end)
        end)
    end)
end