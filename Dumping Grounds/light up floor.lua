-- Spawns tiles that light up when touched or damaged

--@name Light up floor
--@author Jacbo
--@include spawn_blocking.txt
--@include better_coroutines.txt

if SERVER then
    require("spawn_blocking.txt")
    local cor = require("better_coroutines.txt")
    local ents = {}
    local coloredEnts = {}
    local fadeSpeed = 1 / 5
    local hueSpeed = 15
    local curtime = timer.curtime
    local math_max = math.max
    
    -- Handle color fading
    local fadeColors = cor.wrap(function()
        local keys = table.getKeys(coloredEnts)
        local count = #keys
        local i = 1
        while i <= count do
            while quotaAverage() >= 0.003 do coroutine.yield() end
            local ent = keys[i]
            local tbl = coloredEnts[ent]
            local mult = tbl[2]
            if mult == 0 then
                coloredEnts[ent] = nil
                table.remove(keys, i)
                count = count - 1
            else
                local time = curtime()
                mult = math_max(0, mult - fadeSpeed * (time - tbl[3]))
                tbl[3] = time
                tbl[2] = mult
                local col = tbl[1] * mult
                col[4] = 255
                ent:setColor(col)
                i = i + 1
            end
        end
    end)
    
    hook.add("think", "", function()
        fadeColors()
    end)
    
    hook.add("EntityTakeDamage", "", function(ent)
        if ents[ent] then
            coloredEnts[ent] = {Color(timer.curtime() * hueSpeed, 1, 1):hsvToRGB(), 1, timer.curtime()}
        end
    end)
    
    corWrap(function()
        -- Spawn props
        local model = "models/hunter/plates/plate05x05.mdl"
        local width = 47.45 * 0.5
        local height = width
        local gridx = 20
        local gridy = 20
        local origin = chip():getPos()
        local ang = Angle()
        
        for x = (gridx - 1) * -0.5 * width, (gridx - 1) * 0.5 * width, width do
            for y = (gridy - 1) * -0.5 * height, (gridy - 1) * 0.5 * height, height do
                local ent = prop.create(origin + Vector(x, y, 0), ang, model, true)
                ents[ent] = true
                ent:addCollisionListener(function()
                    coloredEnts[ent] = {Color(timer.curtime() * hueSpeed, 1, 1):hsvToRGB(), 1, timer.curtime()}
                end)
                ent:setMaterial("lights/white001")
                coloredEnts[ent] = {Color(timer.curtime() * hueSpeed, 1, 1):hsvToRGB(), 1, timer.curtime()}
            end
        end
    end)
else -- CLIENT
    
end