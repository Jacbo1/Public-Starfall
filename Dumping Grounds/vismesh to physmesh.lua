-- This can be bad if used on high poly models like some balls for example
-- Spawn on a prop and it makes a physical mesh out of the prop's visual one

--@name Vismesh to Physmesh
--@author Jacbo
--@shared

if SERVER then
    local ent = chip():isWeldedTo()
    local pos, ang = ent:getPos(), ent:getAngles()
    net.receive("ping", function(_, ply)
        if ply == owner() then
            net.start("send ent")
            net.writeEntity(ent)
            net.send(owner())
        end
    end)
    net.receive("send vismesh", function()
        print("Receiving mesh")
        net.readStream(function(data)
            print("Spawning prop")
            prop.createCustom(pos + Vector(0,0,100), ang, json.decode(data), true)
        end)
    end)
    --local v1, v2, v3 = Vector(10,0,0), Vector(0,10,0), Vector(0,-10,0)
    --prop.createCustom(chip():getPos() + Vector(0,0,10), Angle(), {{v1, v2, v3, v1 + Vector(0.415,0.415,0.415)}}, false)
    --prop.createCustom(chip():getPos() + Vector(0,0,10), Angle(), {{v1, v2, v3}}, true)
    --prop.createCustom(chip():getPos() + Vector(0,0,10), Angle(), {v1, v2, v3, Vector(0,0,10), Vector(10,10,10), Vector(-5)}, true)
else--CLIENT
    local maxCPU = 1/60
    if player() == owner() then
        net.start("ping")
        net.send()
        net.receive("send ent", function()
            local ent = net.readEntity()
            local model = ent:getModel()
            local vismesh = {}
            local processVisMesh = coroutine.wrap(function()
                for mat, tabl in pairs(mesh.getModelMeshes(model, 0, 0)) do
                    for i = 1, #tabl.triangles, 3 do
                        while quotaAverage() > maxCPU do coroutine.yield() end
                        table.insert(vismesh, {tabl.triangles[i].pos, tabl.triangles[i + 1].pos, tabl.triangles[i + 2].pos, tabl.triangles[i].pos + Vector(0.415)})
                    end
                end
                return true
            end)
            hook.add("think", "process vis mesh", function()
                if processVisMesh() == true then
                    print("Sending mesh")
                    hook.remove("think", "process vis mesh")
                    net.start("send vismesh")
                    net.writeStream(json.encode(vismesh))
                    net.send(nil, true)
                end
            end)
        end)
    end
end