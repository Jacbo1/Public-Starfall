-- Cuts props in half that pass over the saw blade. Yes it actually cuts the physics mesh.
-- None of the code that clips the mesh is mine. It came from an addon, I think "Proper Clipping" https://steamcommunity.com/sharedfiles/filedetails/?id=2256491552
-- I think the visuals might sometimes be incorrect with this after cutting.

--@name Table Saw
--@author Jacbo
--@shared

if SERVER then
    local maxCPU = quotaMax() * 0.25
    
    function getPhysObjData(ent, physobj)
        return {
            damping = {physobj:getDamping()},
            mass = physobj:getMass(),
            mat = physobj:getMaterial()
        }
    end
    
    function applyPhysObjData(physobj, physdata, keepmass)
        physobj:setDamping(unpack(physdata.damping))
        physobj:setMaterial(physdata.mat)
        physobj:setMass(physdata.mass)
    end
    
    local function abovePlane(point, plane, plane_dir)
        return plane_dir:dot(point - plane) > 0
    end

    local function intersection3D(line_start, line_end, plane, plane_dir)
        local line = line_end - line_start
        local dot = plane_dir:dot(line)
        if math.abs(dot) < 1e-6 then return end
        return line_start + line * (-plane_dir:dot(line_start - plane) / dot)
    end

    local function clipPlane3D(poly, plane, plane_dir)
        local n = {}

        local last = poly[#poly]
        for _, cur in ipairs(poly) do
            while quotaAverage() > maxCPU do coroutine.yield() end
            local a = abovePlane(last, plane, plane_dir)
            local b = abovePlane(cur, plane, plane_dir)

            if a and b then
                table.insert(n, cur)
            elseif a or b then
                local point = intersection3D(last, cur, plane, plane_dir)
                -- Check since if the point lies on the plane it will return nil
                if point then
                    table.insert(n, point)
                end
    
                if b then
                    table.insert(n, cur)
                end
            end
        
            last = cur
        end

        local i = 1
        while i <= #n do
            local j = i + 1
            while j <= #n do
                while quotaAverage() > maxCPU do coroutine.yield() end
                if n[i]:getDistance(n[j]) < 0.5 then
                    table.remove(n, j)
                else
                    j = j + 1
                end
            end
            i = i + 1
        end

        return n
    end
    
    function clipPhysics(ent, norm, dist, origin)
        local physobj = ent:getPhysicsObject()

        if not isValid(physobj) then return end

        local meshes = physobj:getMeshConvexes()
        if not meshes then return end
        
        -- Store properties to copy over to the new physobj
        local data = getPhysObjData(ent, physobj)
    
        -- Cull stuff
        if type(dist) ~= "table" then
            norm = {norm}
            dist = {dist}
        end

        local new = {}
        for _, convex in ipairs(meshes) do
            local vertices = {}
            for _, vertex in ipairs(convex) do
                while quotaAverage() > maxCPU do coroutine.yield() end
                vertices[#vertices + 1] = vertex.pos
            end

            new[#new + 1] = vertices
        end

        for i = 1, #norm do
            local norm = norm[i]
            local pos = norm * dist[i] + origin

            local new2 = {}
            for _, vertices in ipairs(new) do
                vertices = clipPlane3D(vertices, pos, norm)
                if next(vertices) then
                    new2[#new2 + 1] = vertices
                end
            end

            new = new2
        end

        -- Apply stored properties to the new physobj
        applyPhysObjData(physobj, data, keepmass)
        
        return new
    end
    
    local function copyEntSettings(from, to)
        to:setColor(from:getColor())
        --to:setSkin(from:getSkin())
        to:setMaterial(from:getMaterial())
        --[[for v, k in pairs(from:getMaterials()) do
            to:setSubMaterial(v, k)
        end]]
    end
    
    local function cutProp(ent, origin, normal)
        local vel = ent:getVelocity()
        local angvel = ent:getAngleVelocity()
        local pos = ent:getPos()
        local ang = ent:getAngles()
        local originL, normalL = worldToLocal(origin, normal:getAngle(), pos, ang)
        normalL = normalL:getForward()
        local physobj1 = clipPhysics(ent, normalL, 0, originL)
        local physobj2 = clipPhysics(ent, -normalL, 0, originL)
        if physobj1 == nil or physobj2 == nil then
            return false
        end
        local frozen = ent:isFrozen()
        local model = ent:getModel()
        local mat = ent:getMaterial()
        local mats = ent:getMaterials()
        local mass = ent:getMass()
        ent:setFrozen(true)
        ent:setSolid(false)
        while quotaAverage() > maxCPU do coroutine.yield() end
        local prop1 = prop.createCustom(pos, ang, physobj1, true)
        while quotaAverage() > maxCPU do coroutine.yield() end
        local prop2 = prop.createCustom(pos, ang, physobj2, true)
        while quotaAverage() > maxCPU do coroutine.yield() end
        --[[while prop1 == nil or prop2 == nil or not prop1:isValid() or not prop2:isValid() do
            coroutine.yield()
        end]]
        local matCount = #ent:getMaterials()
        local center = ent:obbCenter()
        prop1:setNoDraw(true)
        prop2:setNoDraw(true)
        local holo1 = holograms.create(pos, ang, model)
        local holo2 = holograms.create(pos, ang, model)
        local _, flipAng = localToWorld(Vector(), Angle(0, 180, 0), Vector(), ang)
        --local flipPos = localToWorld(-center, Angle(), pos, ang)
        local holo3 = holograms.create(pos, flipAng, model, Vector(-1,1,1))
        local holo4 = holograms.create(pos, flipAng, model, Vector(-1,1,1))
        copyEntSettings(ent, holo1)
        copyEntSettings(ent, holo2)
        copyEntSettings(ent, holo3)
        copyEntSettings(ent, holo4)
        ent:remove()
        holo1:setParent(prop1)
        holo3:setParent(prop1)
        holo2:setParent(prop2)
        holo4:setParent(prop2)
        holo1:setClip(1, true, originL, normalL, prop1)
        holo3:setClip(1, true, originL, normalL, prop1)
        holo2:setClip(1, true, originL, -normalL, prop2)
        holo4:setClip(1, true, originL, -normalL, prop2)
        prop1:setFrozen(frozen)
        prop2:setFrozen(frozen)
        prop1:setMass(mass)
        prop2:setMass(mass)
        prop1:setVelocity(vel)
        prop2:setVelocity(vel)
        prop1:setAngleVelocity(angvel)
        prop2:setAngleVelocity(angvel)
        --[[while holo1 == nil or holo2 == nil or not holo1:isValid() or not holo2:isValid() do
            coroutine.yield()
        end]]
        --[[timer.simple(0.1, function()
            net.start("holos")
            net.writeUInt(holo1:entIndex(), 13)
            net.writeUInt(holo2:entIndex(), 13)
            net.send()
        end)]]
        --[[local wait = true
        timer.simple(0.1, function()
            wait = false
        end)
        while wait do
            coroutine.yield()
        end]]
        return prop1, prop2
    end
    
    local propsToCut = {}
    local tble = prop.create(chip():getPos(), chip():getAngles(), "models/props/cs_militia/table_shed.mdl", true)
    local saw = holograms.create(chip():getPos(), chip():getAngles(), "models/props_junk/sawblade001a.mdl")
    local sawAngInt = 0
    local entQueue = {tble}
    local movingProps = {tble}
    local holo = holograms.create(Vector(), Angle(), "models/holograms/cube.mdl")
    local soundTable = {}
    local invalidObjects = {}
    
    local main = coroutine.wrap(function()
        while true do
            while #propsToCut == 0 or not prop.canSpawn() do
                coroutine.yield()
            end
            if propsToCut[1].ent != nil and propsToCut[1].ent:isValid() then
                try(function()
                    local prop1, prop2 = cutProp(propsToCut[1].ent, propsToCut[1].origin, propsToCut[1].normal)
                    if prop1 != false then
                        while prop1 == nil or prop2 == nil or not prop1:isValid() or not prop2:isValid() do
                            print("waiting")
                            coroutine.yield()
                        end
                        table.insert(movingProps, prop1)
                        table.insert(movingProps, prop2)
                    end
                end, function(err)
                    try(function()
                        printTable(err)
                    end)
                    table.insert(invalidObjects, propsToCut[1].ent)
                end)
            end
            table.remove(propsToCut, 1)
            table.remove(entQueue, 2)
        end
    end)
    
    local restartingSawSound = timer.curtime() + 2
    local sawSound = sounds.create(tble, "ambient/sawblade.wav")
    
    hook.add("think", "", function()
        --saw:setPos(
        sawAngInt = sawAngInt + timer.frametime() * 4500
        local tblAng = tble:getAngles()
        local tblPos = tble:obbCenterW()
        local sawPos, sawAng = localToWorld(Vector(0,0,17), Angle(sawAngInt, 90, 90), tblPos, tblAng)
        saw:setPos(sawPos)
        saw:setAngles(sawAng)
        local trc = trace.traceHull(sawPos, sawPos + tble:getUp() * 5, Vector(-5), Vector(5), function(ent)
            if table.hasValue(invalidObjects, ent) or table.hasValue(entQueue, ent) then
                return false
            end
            return true
        end)
        local time = timer.curtime()
        if trc.Entity != nil and trc.Entity:isValid() and trc.Entity:getClass() == "prop_physics" then
            --Cut prop
            table.insert(entQueue, trc.Entity)
            table.insert(propsToCut, {
                ent = trc.Entity,
                origin = sawPos,
                normal = tble:getForward()
            })
            if sounds.canCreate() then
                local sound = sounds.create(tble, "ambient/sawblade_impact" .. math.random(1,2) .. ".wav")
                sound:play()
                table.insert(soundTable, {
                    time = time,
                    sound = sound
                })
            end
        end
        local i = 1
        while i <= #soundTable do
            if time - 5 > soundTable[i].time then
                soundTable[i].sound:destroy()
                table.remove(soundTable, i)
            else
                i = i + 1
            end
        end
        if restartingSawSound != 0 and time > restartingSawSound then
            restartingSawSound = 0
            if sounds.canCreate() then
                sawSound:destroy()
                sawSound = sounds.create(tble, "ambient/sawblade.wav")
                sawSound:play()
                sawSound:setVolume(0.15)
            else
                hook.add("think", "restart saw sound", function()
                    if sounds.canCreate() then
                        sawSound:destroy()
                        sawSound = sounds.create(tble, "ambient/sawblade.wav")
                        sawSound:play()
                        sawSound:setVolume(0.15)
                        hook.remove("think", "restart saw sound")
                    end
                end)
            end
        end
        main()
    end)
    
    hook.add("think", "move", function()
        local tblAng = tble:getAngles()
        local tblPos = tble:obbCenterW()
        local sawPos = localToWorld(Vector(0,0,17), Angle(), tblPos, tblAng)
        local start = sawPos + tble:getRight() * 40 + tble:getUp() * 5
        local stop = start - tble:getRight() * 80
        local trc = trace.traceHull(start, stop, Vector(-5), Vector(5), function(ent)
            if table.hasValue(invalidObjects, ent) or table.hasValue(movingProps, ent) then
                return false
            end
            return true
        end)
        if trc.Entity != nil and trc.Entity:isValid() and trc.Entity:getClass() == "prop_physics" then
            table.insert(movingProps, trc.Entity)
        end
        if #movingProps != 1 then
            local propsHit = {}
            trc = trace.traceHull(start, stop, Vector(-5), Vector(5), function(ent)
                if ent != tble and table.hasValue(movingProps, ent) then
                    table.insert(propsHit, ent)
                end
                return false
            end)
            local speed = 75
            --local targetVel = tble:getRight() * timer.frametime() * speed
            local targetVel = tble:getRight() * speed
            local i = 2
            while i <= #movingProps do
                if movingProps[i] == nil or not movingProps[i]:isValid() then
                    table.remove(movingProps, i)
                    continue
                end
                if table.hasValue(propsHit, movingProps[i]) then
                    --movingProps[i]:setVelocity(vel)
                    local vel = worldToLocal(movingProps[i]:getVelocity(), Angle(), Vector(), tblAng)
                    vel[1] = -vel[1]
                    vel[2] = speed - vel[2]
                    local pos = worldToLocal(movingProps[i]:obbCenterW(), Angle(), tblPos, tblAng)
                    --vel[1] = vel[1] - pos[1] * 10
                    vel[3] = math.min(0, -vel[3])
                    try(function()
                        movingProps[i]:applyForceCenter(vel * movingProps[i]:getMass())
                    end, function()
                        table.insert(invalidObjects, table.remove(movingProps, i))
                        i = i - 1
                    end)
                    --movingProps[i]:setPos(movingProps[i]:getPos() + vel)
                else
                    table.remove(movingProps, i)
                    continue
                end
                i = i + 1
            end
        end
    end)
    --models/props/cs_militia/table_shed.mdl
    restartingSawSound = timer.curtime() + 1
    net.receive("saw", function(_, ply)
        restartingSawSound = timer.curtime() + 1
    end)
else --CLIENT
    local hookIndex = 0
    net.start("saw")
    net.send()
    net.receive("holos", function()
        local holo1 = entity(net.readUInt(13)):toHologram()
        local holo2 = entity(net.readUInt(13)):toHologram()
        hookIndex = hookIndex + 1
        local myIndex = hookIndex
        hook.add("think", "wait for holos " .. myIndex, function()
            if holo1 != nil and holo2 != nil and holo1:isValid() and holo2:isValid() then
                holo1 = holo1:toHologram()
                holo2 = holo2:toHologram()
                hook.remove("think", "wait for holos " .. myIndex)
                local mat = holo1:getMaterial()
                if mat == "" then
                    local mats = holo1:getMaterials()
                    for v, k in pairs(mats) do
                        local usemat = material.create("VertexLitGeneric")
                        --usemat:setTexture("$basetexture", material.getTexture(k, "$basetexture"))
                        usemat:setTexture("$basetexture", material.getTexture("hunter/myplastic", "$basetexture"))
                        --usemat:setTexture("$bumpmap", material.getTexture(k, "$bumpmap"))
                        --local usemat = material.load(k)
                        --printTable(usemat)
                        usemat:setInt("$flags", 8192)
                        --printTable(usemat:getKeyValues())
                        --holo1:setSubMaterial(v, "!" .. usemat:getName())
                        --holo2:setSubMaterial(v, "!" .. usemat:getName())
                        holo1:setMaterial("!" .. usemat:getName())
                    end
                end
            end
        end)
    end)
end