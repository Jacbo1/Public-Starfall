-- Subwoofer with animated speaker based on bass

--@name Subwoofer
--@author Jacbo
--@shared

if SERVER then
    local subwoofer = holograms.create(chip():getPos(), chip():getAngles(), "models/bull/various/subwoofer.mdl")
    subwoofer:setParent(chip())
    local speakers = {}
    local speaker_count = 25
    local speaker_size
    local first = true
    local makeSpeakers = coroutine.wrap(function()
        for level = 0, 0.25, 1 / speaker_count * 0.25 do
            while quotaAverage() > 1/60 or not holograms.canSpawn() do
                coroutine.yield()
            end
            local speaker = holograms.create(chip():getPos(), chip():getAngles(), "models/bull/various/subwoofer.mdl", Vector(1, 1, 1))
            if first then
                speaker_size = speaker:obbSize()
            end
            speaker:setSubMaterial(0, "particle/warp1_warp")
            speaker:setSubMaterial(2, "particle/warp1_warp")
            speaker:setSubMaterial(3, "particle/warp1_warp")
            speaker:setSize(speaker_size + Vector(level*100,0,0))
            speaker:setPos(subwoofer:getPos() - subwoofer:getForward() * level * 48.125)
            speaker:setParent(subwoofer)
            table.insert(speakers, speaker)
        end
        subwoofer:setSubMaterial(1, "particle/warp1_warp")
        return true
    end)
    --speaker:setDrawShadow()
    local ready = false
    local playerQueue = {}
    hook.add("think", "", function()
        if makeSpeakers() == true then
            hook.remove("think", "")
            timer.simple(0.5, function()
                ready = true
                for _, ply in pairs(playerQueue) do
                    --[[subwoofer:setDrawShadow(false, ply)
                    for i, speaker in pairs(speakers) do
                        speaker:setDrawShadow(false, ply)
                    end]]
                    net.start("")
                    net.writeEntity(subwoofer)
                    --net.writeEntity(speaker)
                    net.writeTable(speakers)
                    net.send(ply)
                end
            end)
        end
    end)
    net.receive("", function(_, ply)
        if ready then
            --[[subwoofer:setDrawShadow(false, ply)
            for _, speaker in pairs(speakers) do
                speaker:setDrawShadow(false, ply)
            end]]
            net.start("")
            net.writeEntity(subwoofer)
            --net.writeEntity(speaker)
            net.writeTable(speakers)
            net.send(ply)
        else
            table.insert(playerQueue, ply)
        end
    end)
else
    local url = "https://dl.dropboxusercontent.com/s/dy3d91vfr96olms/Among_Us_Trap_Remix_Bass_Boosted_Leonz.mp3"
    --local url = "https://www.dropbox.com/s/69qaxty4qv1p3kr/Dancin.mp3?dl=1"
    --local url = "https://dl.dropboxusercontent.com/s/sfyr7xwe4dm3ysp/aaaaaaaaaaaaaaaaaaaa.mp3"
    --local url = "https://play.sas-media.ru/play_256"
    --local url = "https://www.dropbox.com/s/xbnr3hwe133bkjs/WALKIN%27%20-%20JerryTerry.mp3?dl=1"
    --local url = "https://www.dropbox.com/s/bekfun99iqnhze5/DANGEROUSLY_LOUD.mp3?dl=1"
    local maxCPU = 1/60
    net.start("")
    net.send()
    net.receive("", function()
        local subwoofer = net.readEntity():toHologram()
        --subwoofer:setNoDraw(true)
        --local speaker = net.readEntity():toHologram()
        local speakers = net.readTable()
        --local speaker_size = speaker:obbSize()
        timer.simple(1, function()
        for _, speaker in pairs(speakers) do
            try(function()
            speaker:suppressEngineLighting(true)
            end)
            speaker:setNoDraw(true)
        end
        bass.loadURL(url, "3d noblock", function(Sound)
            if Sound then
                Sound:play()
                --Sound:setVolume(10)
            end
            local bass_level = 0
            local max_pitch = 32
            local lastTime = timer.curtime()
            local oldSpeaker = 1
            hook.add("think","",function()
                if Sound then
                    local time = timer.curtime()
                    local ftime = time - lastTime
                    lastTime = time
                    Sound:setPos(chip():getPos())
                    --if time > nextFrameTime then
                    --nextFrameTime = nextFrameTime + 1/fps
                    fft = Sound:getFFT(32)
                    bass_level = math.max(bass_level - ftime * 5, 0)
                    for i = 1, max_pitch do
                        bass_level = math.max(bass_level, fft[i] == nil and 0 or fft[i])
                    end
                    speakers[oldSpeaker]:setNoDraw(true)
                    local index = math.round(math.clamp((1.15 - bass_level) * (#speakers - 1) + 1, 1, #speakers))
                    oldSpeaker = index
                    speakers[index]:setNoDraw(false)
                    --[[speaker:setAngles(subwoofer:getAngles())
                    speaker:setScale((speaker_size + Vector(bass_level*50,0,0)) / speaker_size)
                    speaker:setPos(subwoofer:getPos() - subwoofer:getForward() * bass_level * 100)]]
                end
            end)
        end)
        end)
    end)
end