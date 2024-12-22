-- Spawn this on a prop and watch it explode into its individual polygons

--@name Triangle Explode
--@author Jacbo
--@shared

if SERVER then
    local ent = chip():isWeldedTo()
    net.receive("", function(_, ply)
        net.start("")
        net.writeEntity(ent)
        net.send(ply)
    end)
else --CLIENT
--elseif player() == owner() then --CLIENT
    local maxCPU = 0.005
    local maxHolos = 200
    net.start("")
    net.send()
    net.receive("", function()
        net.readEntity(function(entity)
        entity:setColor(Color(0,0,0,0))
        local pos = entity:getPos()
        local ang = entity:getAngles()
        local ent_mesh = mesh.getModelMeshes(entity:getModel(), 0, 0)
        local holo_count = 0
        for mat, tabl in pairs(ent_mesh) do
            holo_count = math.min(maxHolos, holo_count + math.floor(#tabl.triangles / 3))
        end
        local holos = {}
        hook.add("think", "spawn holos", function()
            while holograms.canSpawn() and #holos < holo_count do
                table.insert(holos, {
                    0,
                    Vector(math.rand(-50,50), math.rand(-50,50), math.rand(-50,50)),
                    Angle(math.rand(-50,50), math.rand(-50,50), math.rand(-50,50)),
                    holograms.create(pos, ang, "models/hunter/plates/plate.mdl")
                })
            end
            if #holos >= holo_count then
                hook.remove("think", "spawn holos")
            end
        end)
        local materials = entity:getMaterials()
        local ent_mat = entity:getMaterial()
        local holo_index = 1
        local yield = 1
        local spawn = coroutine.wrap(function()
            if ent_mat == "" then
                for mat, tabl in pairs(ent_mesh) do
                    local usemat = material.create("VertexLitGeneric")
                    --usemat:setTexture("$basetexture", materials[mat])
                    usemat:setTexture("$basetexture", tabl.material)
                    for i = 1, #tabl.triangles - 2, 3 do
                        yield = yield - 1
                        --[[if yield == 0 then
                            yield = 100
                            coroutine.yield()
                        end]]
                        local meshTable = {}
                        for j = i, i + 2 do
                            local vertex = tabl.triangles[j]
                            table.insert(meshTable, {pos = vertex.pos, tangent = vertex.tangent, u = vertex.u, v = vertex.v, normal = vertex.normal})
                        end
                        local newMesh
                        local loadmesh = coroutine.wrap(function() newMesh = mesh.createFromTable(meshTable, true) return true end)
                        while loadmesh() != true do
                            while quotaAverage() >= maxCPU do
                                coroutine.yield()
                            end
                        end
                        while #holos < holo_index do
                            coroutine.yield()
                        end
                        holos[holo_index][4]:setMesh(newMesh)
                        holos[holo_index][4]:setMeshMaterial(usemat)
                        holo_index = holo_index + 1
                        if holo_index > maxHolos then break end
                    end
                    if holo_index > maxHolos then break end
                end
            end
            return true
        end)
        local spawned = false
        hook.add("think", "loop", function()
            if spawned then
                --entity:remove()
                entity:setNoDraw(true)
                local time = timer.curtime()
                local runs = #holos
                while runs != 0 and quotaAverage() < maxCPU do
                    runs = runs - 1
                    holo_index = holo_index % #holos + 1
                    if holos[holo_index][1] == 0 then
                        holos[holo_index][1] = time
                    else
                        local ftime = time - holos[holo_index][1]
                        holos[holo_index][1] = time
                        holos[holo_index][4]:setPos(holos[holo_index][4]:getPos() + holos[holo_index][2] * ftime)
                        holos[holo_index][4]:setAngles(holos[holo_index][4]:getAngles() + holos[holo_index][3] * ftime)
                    end
                end
            elseif spawn() == true then
                print("Spawned")
                spawned = true
            end
        end)
        end)
    end)
end