--@name Midi Player
--@author Jacbo
--@shared

if SERVER then
    local props = {}
    local propCount = 20
    local ready = false
    local playerQueue = {}
    hook.add("think", "", function()
        if prop.canSpawn() then
            local p = prop.create(chip():getPos(), Angle(0,0,0), "models/hunter/plates/plate.mdl", 1)
            p:setParent(chip())
            table.insert(props, p)
            if #props >= propCount then
                hook.remove("think", "")
                timer.simple(1, function()
                    ready = true
                    for v, ply in pairs(playerQueue) do
                        net.start("")
                        net.writeTable(props)
                        net.send(ply)
                    end
                end)
            end
        end
    end)
    for i = 1, 20 do
        if prop.canSpawn() then
            local p = prop.create(chip():getPos(), Angle(0,0,0), "models/hunter/plates/plate.mdl", 1)
            p:setParent(chip())
            table.insert(props, p)
        else
            break
        end
    end
    net.receive("", function(_, ply)
        if ready then
            net.start("")
            net.writeTable(props)
            net.send(ply)
        else
            table.insert(playerQueue, ply)
        end
    end)
else --CLIENT
    local function everything()
    net.start("")
    net.send()
    local enableParticles = true
    local cpuLimit = quotaMax() * 0.9
    local cpuMax = cpuLimit
    local volume1 = 1
    local enabled = true
    local midis = {}
    local loadingMessages = {}
    local lastLoadDotChange = 0
    local txts = {}
    local pianoNotes = {}
    local loadingMessageID = 0
    local soundTable = {}
    local noteIndex = 0
    local fadeDuration = 0.5
    local noteLengthAdd = 0.5
    local minNoteLength = 0
    local soundLength = 2.5
    
    local visualLookAhead = 5
    local visualTrackPositions = {}
    local trackColors = {Color(255,0,0), Color(0,255,0), Color(0,0,255), Color(140,0,255), Color(255,255,0), Color(255,140,0), Color(0,255,255)}
    local noteWidth = 1
    local pitchRange = 1
    local cornerRadius = 1
    
    local holos = {}
    local holoIndex = 1
    
    local screenFPS = 60
    local screenUpdateInterval = 1 / screenFPS
    local screenUpdateTime = nil
    
    local notes = {}
    
    local currentMidi = nil
    
    pianoNotes[36] = "a1" pianoNotes[37] = "b1" pianoNotes[38] = "a2" pianoNotes[39] = "b2" pianoNotes[40] = "a3" pianoNotes[41] = "a4" pianoNotes[42] = "b3" pianoNotes[43] = "a5" pianoNotes[44] = "b4" pianoNotes[45] = "a6" pianoNotes[46] = "b5" pianoNotes[47] = "a7" pianoNotes[48] = "a8" pianoNotes[49] = "b6" pianoNotes[50] = "a9" pianoNotes[51] = "b7" pianoNotes[52] = "a10" pianoNotes[53] = "a11" pianoNotes[54] = "b8" pianoNotes[55] = "a12" pianoNotes[56] = "b9"  pianoNotes[57] = "a13" pianoNotes[58] = "b10" pianoNotes[59] = "a14" pianoNotes[60] = "a15" pianoNotes[61] = "b11" pianoNotes[62] = "a16" pianoNotes[63] = "b12" pianoNotes[64] = "a17" pianoNotes[65] = "a18" pianoNotes[66] = "b13" pianoNotes[67] = "a19" pianoNotes[68] = "b14" pianoNotes[69] = "a20" pianoNotes[70] = "b15" pianoNotes[71] = "a21" pianoNotes[72] = "a22" pianoNotes[73] = "b16" pianoNotes[74] = "a23" pianoNotes[75] = "b17" pianoNotes[76] = "a24" pianoNotes[77] = "a25" pianoNotes[78] = "b18" pianoNotes[79] = "a26" pianoNotes[80] = "b19" pianoNotes[81] = "a27" pianoNotes[82] = "b20" pianoNotes[83] = "a28" pianoNotes[84] = "a29" pianoNotes[85] = "b21" pianoNotes[86] = "a30" pianoNotes[87] = "b22" pianoNotes[88] = "a31" pianoNotes[89] = "a32" pianoNotes[90] = "b23" pianoNotes[91] = "a33" pianoNotes[92] = "b24" pianoNotes[93] = "a34" pianoNotes[94] = "b25" pianoNotes[95] = "a35"
    
    local starMat
    local makeParticle
    local particles
    local particleInterval = 0.015
    local particlesPerTick = 1
    local lastTickTime = nil
    local updateParticles
    local drawParticles
    local noteParticles = {}
    local spawnNoteParticle
    
    local glowFade = 0.5
    local glowTimes = {}
    local glowMat = material.create("UnlitGeneric")
    glowMat:setTextureURL("$basetexture", "https://i.imgur.com/pXp6zwS.png")
    
    if enableParticles then
        starMat = material.create("UnlitGeneric")
        particles = {}
        makeParticle = function(x, y, dx, dy)
            table.insert(particles,{
                x = x,
                y = y,
                dx = dx,
                dy = dy,
                radius = 2,
                gravity = 10000
            })
        end
        updateParticles = function(timeElapsed)
            local i = 1
            while i <= #particles do
                part = particles[i]
                if part.y - part.radius < 512 then
                    part.dy = part.dy + part.gravity * timeElapsed ^ 2
                    part.x = part.x + part.dx * timeElapsed
                    part.y = part.y + part.dy * timeElapsed
                else
                    table.remove(particles, i)
                    i = i - 1
                end
                i = i + 1
            end
        end
        drawParticles = function()
            render.setColor(Color(255,255,255))
            render.setMaterial(starMat)
            for i, part in pairs(particles) do
                render.drawTexturedRect(
                    part.x - part.radius,
                    part.y - part.radius,
                    part.radius * 2,
                    part.radius * 2
                )
            end
        end
        spawnNoteParticle = function(note)
            if currentMidi != nil then
                local x = (note.pitch - currentMidi.midi.minPitch) / (pitchRange + 1) * 511
                makeParticle(
                    math.rand(x, x + noteWidth),
                    511,
                    math.rand(-50, 50),
                    math.rand(-100, -50)
                )
                noteParticles[note.id] = timer.systime()
            end
        end
        --[[spawnNoteParticle = function(pitch, id)
            if currentMidi != nil then
                local x = (pitch - currentMidi.midi.minPitch) / (pitchRange + 1) * 511
                makeParticle(
                    math.rand(x, x + noteWidth),
                    511,
                    math.rand(-50, 50),
                    math.rand(-100, -50)
                )
                noteParticles[id] = timer.systime()
            end
        end]]
        starMat:setTextureURL("$basetexture", "https://i.imgur.com/NGP2PCD.png")
    end
    
    local function destroyAllSounds()
        for v, k in pairs(soundTable) do
            if k != nil then
                k:destroy()
            end
        end
        table.empty(soundTable)
        table.empty(notes)
    end
    
    local function addLoadingMessage()
        loadingMessageID = loadingMessageID + 1
        local loadingMessage = {id = loadingMessageID}
        table.insert(loadingMessages, loadingMessage)
        return loadingMessage
    end
    
    local function removeLoadingMessage(id)
        for i = #loadingMessages, 1, -1 do
            if loadingMessages[i].id == id then
                table.remove(loadingMessages, i)
                return
            end
        end
    end
    
    local processtxt = coroutine.wrap(function()
        while true do
            while #txts == 0 do
                coroutine.yield()
            end
            local loadingMessage = txts[1].loadingMessage
            loadingMessage.message = "Processing data"
            loadingMessage.progress = {0, 0}
            while quotaAverage() >= cpuLimit do coroutine.yield() end
            local midi = {name = "test", minPitch = math.huge, maxPitch = -math.huge, duration = 0, data = {}}
            local pos = 2
            local b = string.find(txts[1].data, "b", pos, true)
            local trackCount = 0
            local trackEnds = {}
            while b != nil do
                table.insert(trackEnds, b)
                trackCount = trackCount + 1
                b = string.find(txts[1].data, "b", b + 1, true)
                while quotaAverage() >= cpuLimit do coroutine.yield() end
            end
            local trackIndex = 1
            b = trackEnds[1]
            while b != nil do
                loadingMessage.progress[2] = 0
                local track = {times = {}, pitches = {}, volumes = {}, lengths = {}}
                local decoderStart = pos
                pos = b + 1
                local decoderEnd = b - 1
                local loadLength = decoderEnd - decoderStart
                
                local decodeNext = string.find(txts[1].data, "t", decoderStart, true)
                while decodeNext != nil and decodeNext < decoderEnd do
                    while quotaAverage() >= cpuLimit do
                        loadingMessage.progress[2] = (decodeNext - decoderStart) / (decoderEnd - decoderStart)
                        coroutine.yield()
                    end
                    local T = decodeNext
                    local P = string.find(txts[1].data, "p", T, true)
                    local V = string.find(txts[1].data, "v", P, true)
                    local L = string.find(txts[1].data, "l", V, true)
                    decodeNext = string.find(txts[1].data, "t", L, true)
                    if decodeNext == nil or decodeNext > decoderEnd then
                        decodeNext = decoderEnd + 1
                    end
                    local start = tonumber(string.sub(txts[1].data, T + 1, P - 1)) / 1000
                    local pitch = tonumber(string.sub(txts[1].data, P + 1, V - 1))
                    local length = tonumber(string.sub(txts[1].data, L + 1, decodeNext - 1)) / 1000
                    local volume = tonumber(string.sub(txts[1].data, V + 1, L - 1)) / 100
                    midi.minPitch = math.min(midi.minPitch, pitch)
                    midi.maxPitch = math.max(midi.maxPitch, pitch)
                    midi.duration = math.max(midi.duration, start + length)
                    table.insert(track.times, start)
                    table.insert(track.pitches, pitch)
                    table.insert(track.volumes, volume)
                    table.insert(track.lengths, length)
                end
                
                table.insert(midi.data, track)
                loadingMessage.progress[1] = trackIndex / trackCount
                loadingMessage.progress[2] = 1
                trackIndex = trackIndex + 1
                b = trackEnds[trackIndex]
            end
            removeLoadingMessage(loadingMessage.id)
            table.insert(midis, midi)
            table.remove(txts, 1)
            print("Midi processed")
            print(midi.duration)
        end
    end)
    
    local function downloadNewMidi(url)
        local loadingMessage = addLoadingMessage()
        
        function httpSuccess(body, length, headers, code)
            table.insert(txts, {data = body, loadingMessage = loadingMessage})
            loadingMessage.message = "Awaiting processing"
            print("Processing txt")
        end
        
        local function httpFail(reason)
            print("http request failed!")
            print(reason)
            removeLoadingMessage(loadingMessage.id)
        end
        
        local function request()
            loadingMessage.message = "Downloading"
            http.get(url, httpSuccess, httpFail)
        end
        
        if http.canRequest() then
            request()
        else
            loadingMessage.message = "Waiting to request"
            hook.add("think", "request " .. url, function()
                if http.canRequest() then
                    request()
                    hook.remove("think", "request " .. url)
                end
            end)
        end
    end
    
    --[[local function playNote(pitch, volume, length, fade)
        noteIndex = noteIndex + 1
        if sounds.canCreate() then
            local thisNote = "n" .. noteIndex
            bass.loadFile("sound/gmodtower/lobby/instruments/piano/" .. pianoNotes[math.clamp(pitch, 36, 95)] .. ".wav", "noblock", function(sound, _, err)
                if sound != nil and sound:isValid() then
                    sound:setVolume(volume)
                    if pitch < 36 then
                        sound:setPitch(math.clamp(100 - 2 ^ ((pitch - 36) / 12), 0, 255))
                    elseif pitch > 95 then
                        sound:setPitch(math.clamp(2 ^ ((pitch - 95) / 12) + 100, 0, 255))
                    end
                    local stopTime = timer.systime() + length
                    local stopTime = timer.systime() + length
                    local note
                    if length < minNoteLength then
                        note = {pitch = pitch, volume = volume, length = length, fade = 0, sound = sound, stopTime = stopTime, id = thisNote}
                    else
                        note = {pitch = pitch, volume = volume, length = length, fade = fade, sound = sound, stopTime = stopTime, id = thisNote}
                    end
                    table.insert(notes, note)
                    if enableParticles then
                        spawnNoteParticle(note)
                    end
                    sound:play()
                else
                    --error(err)
                end
            end)
        end
    end]]
    
   local function playNote(pitch, volume, length, fade)
        noteIndex = noteIndex + 1
        if sounds.canCreate() then
            local note = pianoNotes[math.clamp(pitch, 36, 95)]
            if note != nil then
                holoIndex = holoIndex % #holos + 1
                local sound = sounds.create(holos[holoIndex], "gmodtower/lobby/instruments/piano/" .. note .. ".wav", false)
                --local sound = sounds.create(holos[holoIndex], "buttons/button1.wav", false)
                --local sound = sounds.create(holos[holoIndex], "buttons/button15.wav", false)
                --local sound = sounds.create(holos[holoIndex], "synth/saw_440.wav", false)
                //local sound = sounds.create(holos[holoIndex], "synth/saw.wav", false)
                --local sound = sounds.create(holos[holoIndex], "synth/saw_inverted_440.wav", false)
                --local sound = sounds.create(holos[holoIndex], "buttons/bell1.wav", false)
                --local sound = sounds.create(holos[holoIndex], "ambient/rottenburg/rottenburg_belltower.wav", false)
                sound:play()
                if pitch < 36 then
                    sound:setPitch(math.clamp(2 ^ ((pitch + 43.72627428) / 12), 0, 255))
                elseif pitch > 95 then
                    sound:setPitch(math.clamp(2 ^ ((pitch - 15.27372572) / 12), 0, 255))
                end
                sound:setVolume(volume)
                local stopTime = timer.systime() + length
                local noteT
                if length < minNoteLength then
                    noteT = {pitch = pitch, volume = volume, length = length, fade = 0, sound = sound, stopTime = stopTime, id = "n" .. noteIndex}
                else
                    noteT = {pitch = pitch, volume = volume, length = length, fade = fade, sound = sound, stopTime = stopTime, id = "n" .. noteIndex}
                end
                table.insert(notes, noteT)
                if enableParticles then
                    spawnNoteParticle(noteT)
                end
            end
        end
    end
    
    --[[local function playNote(pitch, volume, length, fade)
        noteIndex = noteIndex + 1
        if sounds.canCreate() then
            local thisNote = noteIndex
            local note = pianoNotes[math.clamp(pitch, 36, 95)]
            if note != nil then
                local sound = sounds.create(chip(), "gmodtower/lobby/instruments/piano/" .. note .. ".wav", false)
                sound:play()
                if pitch < 36 then
                    sound:setPitch(math.clamp(100 - 2 ^ ((pitch - 36) / 12), 0, 255))
                elseif pitch > 95 then
                    sound:setPitch(math.clamp(2 ^ ((pitch - 95) / 12) + 100, 0, 255))
                end
                sound:setVolume(volume)
                local stopTime = timer.systime() + length
                hook.add("think", "note " .. thisNote, function()
                    if sound == nil then
                        hook.remove("think", "note " .. thisNote)
                    else
                        local time = timer.systime()
                        if time >= stopTime then
                            sound:destroy()
                            sound = nil
                            hook.remove("think", "note " .. thisNote)
                        elseif stopTime - time <= fade then
                            --sound:setVolume(math.max(volume - 1 + (stopTime - time) / fade, 0))
                            sound:setVolume(math.max(volume * (stopTime - time) / fade, 0))
                        end
                    end
                end)
            end
        end
    end]]
    
    local function loadNewMidi(index)
        print("Loading midi " .. index)
        destroyAllSounds()
        currentMidi = {midi = midis[index], time = 0, startTime = nil, trackPositions = {}}
        table.empty(visualTrackPositions)
        for i = 1, #midis[index].data do
            table.insert(currentMidi.trackPositions, 1)
            table.insert(visualTrackPositions, 1)
        end
        noteIndex = 0
        pitchRange = midis[index].maxPitch - midis[index].minPitch
        noteWidth = 512 / (pitchRange + 1)
        cornerRadius = noteWidth / 2 / 4
        table.empty(glowTimes)
    end
    
    local function playMidi()
        if currentMidi.startTime == nil then
            currentMidi.startTime = timer.systime()
        end
        currentMidi.time = timer.systime() - currentMidi.startTime
        for i = 1, #currentMidi.trackPositions do
            --Still playing this track
            while currentMidi.trackPositions[i] <= #currentMidi.midi.data[i].times and currentMidi.midi.data[i].times[currentMidi.trackPositions[i]] <= currentMidi.time do
                playNote(
                    currentMidi.midi.data[i].pitches[currentMidi.trackPositions[i]],
                    currentMidi.midi.data[i].volumes[currentMidi.trackPositions[i]] * volume1,
                    currentMidi.midi.data[i].lengths[currentMidi.trackPositions[i]] + noteLengthAdd,
                    fadeDuration
                )
                currentMidi.trackPositions[i] = currentMidi.trackPositions[i] + 1
            end
        end
    end
    
    hook.add("think", "", function()
        cpuMax = quotaMax() * 0.9
        if currentMidi == nil then
            if #midis > 0 then
                loadNewMidi(1)
            end
        else
            playMidi()
        end
        local i = 1
        local time = timer.systime()
        --local lfopitch = math.sin(time * math.pi * 4) * 25 + 100
        while i <= #notes do
            if notes[i].sound == nil then
                noteParticles[notes[i].id] = nil
                table.remove(notes, i)
                i = i - 1
            else
                if time >= notes[i].stopTime then
                    notes[i].sound:destroy()
                    noteParticles[notes[i].id] = nil
                    table.remove(notes, i)
                    i = i - 1
                else
                    if enableParticles then
                        while time - noteParticles[notes[i].id] >= particleInterval do
                            for j = 1, particlesPerTick do
                                spawnNoteParticle(notes[i])
                            end
                            noteParticles[notes[i].id] = noteParticles[notes[i].id] + particleInterval
                        end
                    end
                    if notes[i].stopTime - time <= notes[i].fade and notes[i].length <= soundLength and notes[i].sound:isPlaying() then
                    --if notes[i].stopTime - time <= notes[i].fade then
                        --sound:setVolume(math.max(volume - 1 + (stopTime - time) / fade, 0))
                        notes[i].sound:setVolume(notes[i].volume * (notes[i].stopTime - time) / notes[i].fade)
                    end
                    --notes[i].sound:setPitch(lfopitch)
                end
            end
            i = i + 1
        end
        processtxt()
    end)
    
    
    net.receive("", function()
        holos = net.readTable()
        print(#holos .. " ents")
        downloadNewMidi("https://dl.dropboxusercontent.com/s/vxqt3bw4txqxpu6/midis.txt")
    end)
    
    local function getTrackColor(track)
        local color = trackColors[track]
        if color == nil then
            trackColors[track] = Color(math.random(0, 255), math.random(0, 255), math.random(0, 255))
            color = trackColors[track]
        end
        return color
    end
    
    hook.add("render", "", function()
        --[[if screenUpdateTime == nil then
            screenUpdateTime = timer.systime()
        end
        local time = timer.systime()
        if time >= screenUpdateTime then
            --Render
            screenUpdateTime = math.ceil((time - screenUpdateTime) / screenUpdateInterval) * screenUpdateInterval]]
            
            local time = timer.systime()
            
            if lastTickTime == nil then
                lastTickTime = time
            end
            
            local glowY = 512 - noteWidth * 2
            
            if currentMidi != nil then
                --render.setMaterial(glowMat)
                for i = #visualTrackPositions, 1, -1 do
                    while visualTrackPositions[i] <= #currentMidi.midi.data[i].times and currentMidi.midi.data[i].times[visualTrackPositions[i]] + currentMidi.midi.data[i].lengths[visualTrackPositions[i]] < currentMidi.time do
                        visualTrackPositions[i] = visualTrackPositions[i] + 1
                    end
                    local n = visualTrackPositions[i]
                    while n <= #currentMidi.midi.data[i].times and currentMidi.midi.data[i].times[n] <= currentMidi.time + visualLookAhead do
                        render.setColor(getTrackColor(i))
                        render.drawRoundedBox(
                            cornerRadius,
                            (currentMidi.midi.data[i].pitches[n] - currentMidi.midi.minPitch) / (pitchRange + 1) * 511,
                            (currentMidi.time + visualLookAhead - currentMidi.midi.data[i].times[n] - currentMidi.midi.data[i].lengths[n]) / visualLookAhead * 511,
                            noteWidth,
                            currentMidi.midi.data[i].lengths[n] / visualLookAhead * 511
                        )
                        if currentMidi.midi.data[i].times[n] <= currentMidi.time and currentMidi.midi.data[i].times[n] - currentMidi.midi.data[i].lengths[n] <= currentMidi.time then
                            local pitch = currentMidi.midi.data[i].pitches[n]
                            if glowTimes[pitch] != time then
                                render.setColor(Color(255,255,255))
                                glowTimes[pitch] = time
                                render.setMaterial(glowMat)
                                render.drawTexturedRect(
                                    (currentMidi.midi.data[i].pitches[n] - currentMidi.midi.minPitch) / (pitchRange + 1) * 511 - noteWidth / 2,
                                    glowY,
                                    noteWidth * 2,
                                    noteWidth * 2
                                )
                            end
                        end
                        n = n + 1
                    end
                    for pitch = currentMidi.midi.minPitch, currentMidi.midi.maxPitch do
                        if glowTimes[pitch] != time and glowTimes[pitch] != nil and time - glowTimes[pitch] < glowFade then
                            render.setColor(Color(255, 255, 255, 255 - 255 * (time - glowTimes[pitch]) / glowFade))
                            render.setMaterial(glowMat)
                            render.drawTexturedRect(
                                (pitch - currentMidi.midi.minPitch) / (pitchRange + 1) * 511 - noteWidth / 2,
                                glowY,
                                noteWidth * 2,
                                noteWidth * 2
                            )
                        end
                    end
                end
            end
            if enableParticles then
                updateParticles(time - lastTickTime)
                drawParticles()
            end
            if #loadingMessages then
                render.setColor(Color(255,255,255))
                local height = 75
                local loading = {
                    height = 20,
                    width = 512 - 20
                }
                for v, k in pairs(loadingMessages) do
                    local x = 10
                    local y = v * height
                    render.drawText(x, y, k.message, 0, 0)
                    if k.progress != nil then
                        for i, j in pairs(k.progress) do
                            y = v * height + i * 25
                            render.drawRect(x, y, loading.width * j, loading.height)
                            render.drawRectOutline(x, y, loading.width, loading.height)
                        end
                    end
                end
            end
            
            lastTickTime = time
        --end
    end)
    end
    if player() == owner() then
        everything()
    else
        hook.add("render", "pre", function()
            render.drawText(256, 256, "Press use on the screen to enable midi player.\nTerminate the chip to disable it.\nRestart the chip if you want to turn it back on or\ncheck for a new midi/restart the current one.\nArbitrary settings for convars:\nsf_sounds_burstmax_cl 100\nsf_sounds_burstrate_cl 1000\nsf_sounds_max_cl 1000\nsf_timebuffer_cl 0.1\nEnter any of these into console with no argument to see the default value.", 1, 1)
            --render.drawText(256, 256, "Press use on the screen to enable midi player.\nTerminate the chip to disable it.\nRestart the chip if you want to turn it back on or\ncheck for a new midi/restart the current one.\nConvars:\nsf_bass_max_cl 10000\nsf_timebuffer_cl 0.1\nEnter any of these into console with no argument to see the default value.", 1, 1)
        end)
        --setupPermissionRequest({"http.get", "material.create", "material.urlcreate", "sound.create", "sound.modify"}," ",true)
        setupPermissionRequest({"http.get", "material.create", "material.urlcreate", "sound.create"}," ",true)
        --setupPermissionRequest({"http.get", "material.create", "material.urlcreate", "bass.loadFile"}," ",true)
        hook.add("permissionrequest","",function()
            if permissionRequestSatisfied() then
                hook.remove("render", "pre")
                hook.remove("permissionrequest","")
                everything()
            end
        end)
    end
end