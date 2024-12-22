--@name Jinx
--@author Jacbo
--@shared
--@include spawn_blocking.txt

local scale = 1
if SERVER then
    local players = find.allPlayers()
    
    hook.add("PlayerConnect", "", function()
        players = find.allPlayers()
    end)
    
    local jump
    jump = function(bot)
        local pos = bot:getPos()
        local closest
        local plyPos
        local minDist = 5000 * 5000
        for _, ply in ipairs(players) do
            if not ply:isValid() then
                players = find.allPlayers()
            end
            local v = ply:getPos()
            local dist = pos:getDistanceSqr(v)
            if dist < minDist then
                minDist = dist
                closest = v
                plyPos = v
            end
        end
        
        if minDist < (50 + math.max(0, 10 * (scale - 1)))^2 or not closest then
            timer.simple(math.rand(0.5, 1), function() jump(bot) end)
            return
        end
        
        bot:faceTowards(closest)
        minDist = math.sqrt(minDist)
        local maxDist = math.rand(5, 10) * scale
        if minDist > maxDist then
            closest = pos + (closest - pos) / minDist * maxDist
        end
        bot:jumpAcrossGap((closest + pos) / 2 + Vector(0, 0, 10 * scale), plyPos)
    end
    
    local bots = {}
    for i = 1, 1 do
        if not nextbot.canSpawn() then break end
        local bot = nextbot.create(chip():getPos() + Vector(0,i * 40, 0), "models/hunter/blocks/cube025x025x025.mdl")
        bot:setNocollideAll(true)
        table.insert(bots, bot)
    
        local jumpFunc
        jumpFunc = function()
            jump(bot)
            timer.simple(math.rand(1.5, 2.5), jumpFunc)
        end
        --jumpFunc()
        bot:addLandCallback("", function()
            jump(bot)
        end)
        timer.simple(3, function() jump(bot) end)
    
        i = i + 1
    end
    
    net.receive("init", function(_, ply)
        net.start("init")
        net.writeTable(bots)
        net.send(ply)
    end)
else -- CLIENT
    require("spawn_blocking.txt")
    
    local soundURLs = {
        "https://dl.dropboxusercontent.com/s/rmrttnx8ycukbza/Cat-sound-meow.mp3",
        "https://dl.dropboxusercontent.com/s/m5ogjeu145ia3mq/Cute-cat-meow-sound.mp3",
        "https://dl.dropboxusercontent.com/s/e1qbhg3tf8vz16e/mixkit-little-cat-attention-meow-86.mp3",
        "https://dl.dropboxusercontent.com/s/9d4osfq26ab932k/mixkit-sweet-kitty-meow-93.mp3",
        "https://dl.dropboxusercontent.com/s/fcay67lg68pcgv4/Short-meow-sound-effect.mp3"
    }
    
    local availableSounds = {}
    local playingSounds = {}
    local sounds = {}
    --for i = 1, 2 do
        for _, url in ipairs(soundURLs) do
            try(function()
                bass.loadURL(url, "3d noblock", function(sound)
                    if sound and sound:isValid() then
                        sound:setPitch(math.sqrt(1 / scale))
                        table.insert(sounds, sound)
                        table.insert(playingSounds, {false})
                        table.insert(availableSounds, #sounds)
                    end
                end)
            end)
        end
    --end
    
    local bots
    local botsOnGround = {}
    
    local mymesh
    local texture = material.create("VertexLitGeneric")
    texture:setTextureURL("$basetexture", "https://dl.dropboxusercontent.com/s/dk0016dhy2o6v4d/jinx.png", function(_, _, _, _, layout) layout(0, 0, 1024, 1024) end)
        
    local function jump(bot)
        try(function()
            timer.simple(math.rand(3, 6), function() jump(bot) end)
            if #availableSounds == 0 then return end
            local index = table.remove(availableSounds, math.random(1, #availableSounds))
            sounds[index]:setPos(bot:getPos())
            sounds[index]:setTime(0)
            sounds[index]:play()
            playingSounds[index][1] = true
            playingSounds[index][2] = bot
            timer.simple(sounds[index]:getLength(), function()
                playingSounds[index][1] = false
                table.insert(availableSounds, index)
            end)
        end, function()
            if holos then
                for _, holo in ipairs(holos) do
                    holo:remove()
                end
            end
            holos = {}
            bots = nil
            timer.simple(math.rand(0, 1), function()
                net.start("init")
                net.send()
            end)
        end)
    end
    
    http.get("https://dl.dropboxusercontent.com/s/ixdw576z5zux00s/jinx.obj",function(objdata)
        local triangles = mesh.trianglesLeft()
        
        local holos = {}

        local function doneLoadingMesh()
            net.receive("init", function()
                try(function()
                    bots = net.readTable()
                    botsOnGround = {}
                    for _, bot in ipairs(bots) do
                        bot:setNoDraw(true)
                        local holo = hologram.create(bot:getPos(), bot:getAngles(), "models/hunter/plates/plate.mdl", Vector(scale / 2))
                        table.insert(holos, holo)
                        holo:setParent(bot)
                        holo:setMesh(mymesh)
                        holo:setMeshMaterial(texture)
                        holo:setRenderBounds(Vector(-20, -20, -10) * scale / 2, Vector(20, 20, 40) * scale / 2)
                        
                        jump(bot)
                    end
                end, function()
                    if holos then
                        for _, holo in ipairs(holos) do
                            holo:remove()
                        end
                    end
                    holos = {}
                    bots = nil
                    timer.simple(10, function()
                        net.start("init")
                        net.send()
                    end)
                end)
            end)
            net.start("init")
            net.send()
        end

        local loadmesh = coroutine.wrap(function() mymesh = mesh.createFromObj(objdata, true).JinxCat return true end)
        hook.add("think","loadingMesh",function()
            while quotaAverage() < quotaMax() / 2 do
                if loadmesh() == true then
                    doneLoadingMesh()
                    hook.remove("think","loadingMesh")
                    return
                end
            end
        end)
        
        hook.add("think", "", function()
            if not bots then return end
            --[[for i, bot in ipairs(bots) do
                local onGround = bot:getVelocity()[3] == 0
                if onGround ~= botsOnGround[i] then
                    botsOnGround[i] = onGround
                    
                    if not onGround then
                        -- Jumped so play sound
                        if #availableSounds == 0 then continue end
                        local index = table.remove(availableSounds, math.random(1, #availableSounds))
                        playingSounds[index][1] = true
                        playingSounds[index][2] = bot
                        sounds[index]:setPos(bot:getPos())
                        sounds[index]:setTime(0)
                        sounds[index]:play()
                        timer.simple(sounds[index]:getLength(), function()
                            playingSounds[index][1] = false
                            table.insert(availableSounds, index)
                        end)
                    end
                end
            end]]
            
            try(function()
                for i = 1, #sounds do
                    if playingSounds[i][1] then
                        sounds[i]:setPos(playingSounds[i][2]:getPos())
                    end
                end
            end)
        end)
    end)
end