-- Working as of 12/21/2024. Connect chip to HUD component and activate HUD.
-- All chat messages will be read by Dectalk (Moonbase Alpha TTS) for players connected to the HUD.
-- Can also do .t space odyssey or one of the other things in the t table.

--@name Moonbase Alpha TTS
--@author Jacbo
--@client

--Makes all chat messages play moonbase alpha tts
local running = false
local firstUse = true
local using = false
local curSounds = {}
local sequence = {}
local makingSequence = false
local stoppedSounds = {}
local t = {}
t["space odyssey"] = {"[bah<1500,13>][bah<1500,20>][bah<1500,25>][bah<800,28>][bah<800,27>][bah<200,8>][bah<200,13>][bah<200,8>][bah<200,13>][bah<200,8>][bah<200,13>] [bah<200,8>][bah<800,1>][bah<1500,13>][bah<1500,20>][bah<1500,25>][bah<800,28>][bah<800,29>][bah<200,8>][bah<200,13>][bah<200,8>][bah<200,13>][bah<200,8>][bah<200,13>] [bah<200,8>][bah<800,1>][bah<1500,13>][bah<1500,20>][bah<1500,25>][bah<400,32>][bah<800,34>][bah<400,22>][bah<400,24>][bah<1500,27>][bah<400,24>][bah<400,26>][bah<400,27>][bah<1600,29>][bah<400,27>][bah<400,29>][bah<1600,31>][bah<1600,33>][bah<1600,34>]"}
t["imperial march"] = {"[dah<600,20>][dah<600,20>][dah<600,20>][dah<500,16>][dah<130,23>][dah<600,20>][dah<500,16>][dah<130,23>][dah<600,20>][dah<600,27>][dah<600,27>][dah<600,27>][dah<500,28>][dah<130,23>][dah<600,19>][dah<500,16>][dah<130,23>][dah<600,20>][dah<600,32>][dah<600,20>][dah<600,32>][dah<600,31>][dah<100,30>][dah<100,29>][dah<100,28>][dah<300,29>][dah<150,18>][dah<600,28>][dah<600,27>][dah<100,26>][dah<100,25>][dah<100,24>][dah<100,26>][dah<150,15>][dah<600,20>][dah<600,16>][dah<150,23>][dah<600,20>][dah<600,20>][dah<150,23>][dah<600,27>][dah<600,32>][dah<600,20>][dah<600,32>][dah<600,31>][dah<100,30>][dah<100,29>][dah<100,28>][dah<300,29>][dah<150,18>][dah<600,28>][dah<600,27>][dah<100,26>][dah<100,25>][dah<100,24>][dah<100,26>][dah<150,15>][dah<600,20>][dah<600,16>][dah<150,23>][dah<600,20>][dah<600,16>][dah<150,23>][dah<600,20>]"}
t["whalers on the moon"] = {"[_<1,13>]we're[_<1,18>]whalers[_<1,17>]on[_<1,18>]the[_<1,20>]moon[_<400,13>]we[_<1,20>]carry[_<1,18>]a[_<1,20>]har[_<1,22>]poon[_<1,22>]but there[_<1,23>]aint no[_<1,15>]whales[_<1,23>]so we[_<1,22>]tell tall[_<1,18>]tales and[_<1,20>]sing our[_<1,18>]whale[_<1,17>]ing[_<1,18>]tune"}

local checkSound = function(sound)
    if table.removeByValue(stoppedSounds, sound) then
        return false
    end
    if sound == nil then
        return false
    end
    if not sound then
        return false
    end
    if not sound:isValid() then
        return false
    end
    return true
end

local function chatSequence(text, index)
    if index <= #text and running and bass.soundsLeft() > 0 and text[index] != nil then
        local URL = "http://tts.cyzon.us/tts?text=" .. text[index]
        bass.loadURL( URL, "2d", function(Sound)
            if bass.soundsLeft() <= 0 then
                Sound:destroy()
            elseif checkSound(Sound) and running then
                Sound:play()
                table.insert(curSounds, Sound)
                timer.simple(Sound:getLength(), function()
                    table.removeByValue(curSounds, Sound)
                    if checkSound(Sound) then
                        Sound:destroy()
                    end
                    chatSequence(text, index + 1)
                end)
            elseif checkSound(Sound) then
                Sound:destroy()
            end
        end)
    end
end

local chat = function(text)
    if #text > 511 then
        local newSequence = {}
        local index = 1023
        while index <= #text do
            table.insert(newSequence, string.sub(text, 1, index))
            index = index + 1023
        end
        table.insert(newSequence, string.sub(index - 1023, -1))
        chatSequence(newSequence, 1)
    elseif bass.soundsLeft() > 0 then
        local URL = "http://tts.cyzon.us/tts?text=" .. text
        bass.loadURL( URL, "2d", function(Sound)
            if bass.soundsLeft() <= 0 then
                Sound:destroy()
            elseif checkSound(Sound) and running then
                Sound:play()
                table.insert(curSounds, Sound)
                timer.simple(Sound:getLength(), function()
                    table.removeByValue(curSounds, Sound)
                    if checkSound(Sound) then
                        Sound:destroy()
                    end
                end)
            elseif checkSound(Sound) then
                Sound:destroy()
            end
        end)
    end
end

local shrinkSequence = function(text)
    local base = #("http://tts.cyzon.us/tts?text=")
    local newSequence = {""}
    local index = 1
    for v, k in pairs(text) do
        if #newSequence[index] + #k + base < 1023 then
            newSequence[index] = newSequence[index] .. k
        else
            index = index + 1
            table.insert(newSequence, k)
        end
    end
    return newSequence
end

local stopAllSounds = function()
    for v, k in pairs(curSounds) do
        if not table.hasValue(stoppedSounds, k) and k != nil and k and k:isValid() then
            k:destroy()
        end
        table.insert(stoppedSounds, k)
    end
    table.empty(sequence)
    table.empty(curSounds)
end

local enable = function()
    running = true
    hook.add("PlayerChat", "moonbase alpha tts", function(ply, text, team, isdead)
        local play = true
        if ply == player() then
            if text[1] == "." or text[1] == "/" or text[1] == "!" then
                if string.sub(text, 2, -1) == "sequence" then
                    if makingSequence then
                        chatSequence(shrinkSequence(sequence), 1)
                    else
                    table.empty(sequence)
                    end
                    makingSequence = not makingSequence
                    play = false
                end
            elseif makingSequence then
                play = false
                table.insert(sequence, text)
            end
        end
        if text[1] == "." or text[1] == "/" or text[1] == "!" then
            if string.sub(text, 2, 3) == "t " then
                play = false
                local message = t[string.sub(text, 4, -1)]
                if message != nil then
                    chatSequence(shrinkSequence(message), 1)
                elseif ply == player() then
                    chat("Error: no message found.")
                end
            end
        end
        if play then
            chat(text)
        end
    end)
    setName("Moonbase Alpha TTS\nUse the chip to disable\nSay !sequence to start or play a sequence of messages that play one after another")
end

local disable = function()
    running = false
    hook.remove("PlayerChat", "moonbase alpha tts")
    stopAllSounds()
    setName("Moonbase Alpha TTS\nUse the chip to enable")
end

if player() == owner() then
    enable()
    firstUse = false
else
    disable()
    setupPermissionRequest({"bass.loadURL", "bass.play2D"},"Turn on Moonbase Alpha TTS?",true)
    hook.add("permissionrequest","",function()
        if permissionRequestSatisfied() then
            hook.remove("permissionrequest","")
            enable()
            firstUse = false
        end
    end)
end

hook.add("KeyPress", "moonbase alpha tts", function(ply, key)
    if key == 32 and not using and not firstUse and ply == player() then
        using = true
        local eyeTrace = ply:getEyeTrace()
        if eyeTrace.Entity == chip() and eyeTrace.StartPos:getDistance(eyeTrace.HitPos) <= 90 then
            if running then
                disable()
            else
                enable()
            end
        end
    end
end)

hook.add("KeyRelease", "moonbase alpha tts", function(ply, key)
    if key == 32 and using and ply == player() then
        using = false
    end
end)