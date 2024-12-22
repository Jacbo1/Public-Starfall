-- This is an attempt to render a smoke effect on a screen.

--@name Smoke
--@author Jacbo
--@shared

if SERVER then
    local owner = owner()
    local pos = chip():getPos()
    local screen = find.closest(find.byClass("starfall_screen", function(ent)
        return ent:getOwner() == owner
    end), pos)
    if screen then
        screen:linkComponent(chip())
        if cb then
            cb(screen)
        end
    else
        hook.add("tick", "find screen", function()
            screen = find.closest(find.byClass("starfall_screen", function(ent)
                return ent:getOwner() == owner
            end), pos)
            if screen then
                screen:linkComponent(chip())
                if cb then
                    cb(screen)
                end
                hook.remove("tick", "find screen")
            end
        end)
    end
else -- CLIENT
    if player() ~= owner() then return end
    local particles = {}
    local nextSpawnTime = timer.curtime()
    
    local first = true
    local smokeMat
    
    hook.add("render", "", function()
        if first then
            first = false
            smokeMat = render.createMaterial("particle/particle_smokegrenade")
        end
        
        render.setMaterial(smokeMat)
        render.setRGBA(255, 255, 255, 2)
        local dt = timer.frametime()
        local time = timer.curtime()
        while time > nextSpawnTime do
            -- Spawn particle
            local x = math.sin(time * 0.1) * 256 + 256
            local ang = (math.sin(time) + 2) * math.pi / -4
            table.insert(particles, {
                velx = math.cos(ang) * 50 + math.rand(-5, 5),
                vely = math.sin(ang) * 50 + math.rand(-5, 5),
                x = x + math.rand(-10, 10),
                y = 512 + math.rand(-10, 10),
                spawntime = time,
                dietime = time + 10,
                rot = math.rand(0, 360),
                rotVel = math.rand(-1, 1),
                endsize = math.rand(50, 100)
            })
            nextSpawnTime = nextSpawnTime + 0.5 / 60
        end
        
        local i = 1
        while i < #particles do
            local p = particles[i]
            if time > p.dietime then
                -- Kill particle
                table.remove(particles, i)
                continue
            end
            
            p.velx = p.velx * (1 - dt * 0.1)
            p.vely = p.vely * (1 - dt * 0.1)
            --p.vely = p.vely + 200 * dt
            p.x = p.x + p.velx * dt
            p.y = p.y + p.vely * dt
            p.rot = p.rot + p.rotVel
            local size = math.remap(time, p.spawntime, p.dietime, 25, p.endsize)
            
            render.drawTexturedRectRotated(p.x, p.y, size, size, p.rot)
            i = i + 1
        end
    end)
end