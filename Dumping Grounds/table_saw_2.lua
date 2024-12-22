-- Better version but requires "Proper Clipping" addon: https://steamcommunity.com/sharedfiles/filedetails/?id=2256491552
-- Cuts props in half that pass over the saw blade.

--@name Table Saw 2
--@author Jacbo
--@shared
--@include spawn_blocking.txt

if SERVER then
    require("spawn_blocking.txt")

    local maxCPU = quotaMax() * 0.25
    
    local function cutProp(ent, origin, normal)
        if ent:physicsClipsLeft() then
            local vel = ent:getVelocity()
            local angvel = ent:getAngleVelocity()
            
            local originL = ent:worldToLocal(origin)
            local normalL = ent:worldToLocalVector(normal)
            
            local copy
            
            try(function()
                local clipsCopy = table.copy(ent:getClipping())
                ent:addClip(originL, normalL, true, true)
                
                copy = prop.create(ent:getPos(), ent:getAngles(), ent:getModel())
                copy:setVelocity(ent:getVelocity())
                copy:setAngleVelocity(ent:getAngleVelocity())
                copy:setMaterial(ent:getMaterial())
                copy:setColor(ent:getColor())
                copy:setSkin(ent:getSkin())
                copy:setPhysMaterial(ent:getPhysMaterial())
            
                for k, v in pairs(ent:getMaterials()) do
                    copy:setSubMaterial(k, v)
                end
                
                copy:addClip(originL, -normalL, true, true)
                
                for _, clip in ipairs(clipsCopy) do
                    copy:addClip(clip.origin, clip.normal, true, true)
                end
            end, function()
                copy:remove()
                try(function()
                    ent:remove()
                end)
            end)
            
            return ent, copy
        end
        return ent
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
    local cutCooldownProps = {}
    local cutCooldown = 3
    
    local main = coroutine.wrap(function()
        while true do
            while #propsToCut == 0 or not prop.canSpawn() do
                coroutine.yield()
            end
            if propsToCut[1].ent != nil and propsToCut[1].ent:isValid() then
                try(function()
                    local prop1, prop2 = cutProp(propsToCut[1].ent, propsToCut[1].origin, propsToCut[1].normal)
                    if prop1 and prop1:isValid() then
                        table.insert(movingProps, prop1)
                        table.insert(cutCooldownProps, {prop1, timer.curtime() + cutCooldown})
                    end
                    if prop2 and prop2:isValid() then
                        table.insert(movingProps, prop2)
                        table.insert(cutCooldownProps, {prop2, timer.curtime() + cutCooldown})
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
        local i = 1
        local time = timer.curtime()
        while i <= #cutCooldownProps do
            if time > cutCooldownProps[i][2] then
                table.remove(cutCooldownProps, i)
            else
                i = i + 1
            end
        end
        
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
        if trc.Entity != nil and trc.Entity:isValid() and trc.Entity:getClass() == "prop_physics" then
            local found = false
            for _, tbl in ipairs(cutCooldownProps) do
                if tbl[1] == trc.Entity then
                    found = true
                    break
                end
            end
            if not found then
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