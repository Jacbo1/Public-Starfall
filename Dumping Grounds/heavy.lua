-- Doesn't really do anything. I mean it works it just doesn't do much.

--@name Heavy
--@author Jacbo
--@client

chip():setNoDraw(true)
local holo = hologram.create(chip():getPos(), chip():getAngles(), "models/player/heavy.mdl")
holo:setParent(chip())

local sparkSound
local function Vibrate()
    timer.simple(math.rand(2, 10), Vibrate)
    timer.simple(math.rand(0.1, 0.25), function()
        hook.remove("think", "")
        holo:setPos(chip():getPos())
    end)
    
    if sparkSound then
        sparkSound:destroy()
        sparkSound = nil
    end
    
    if sound.canCreate() then
        sparkSound = sound.create(holo, "ambient/energy/spark" .. math.random(1, 6) .. ".wav", false)
        sparkSound:play()
    end
    
    hook.add("think", "", function()
        holo:setPos(chip():getPos() + Vector(math.rand(-1, 1), math.rand(-1, 1), math.rand(-1, 1)))
    end)
end

Vibrate()

local isBlack = true
local zapSoundIDs = { 1, 2, 3, 5, 6, 7, 8, 9 }
local zapSound
local function Blacken()
    isBlack = not isBlack
    if isBlack then
        holo:setColor(Color(0,0,0))
        holo:suppressEngineLighting(true)
        holo:setMaterial("models/debug/debugwhite")
        timer.simple(math.rand(5, 10), Blacken)
    else
        holo:setColor(Color(255,255,255))
        holo:suppressEngineLighting(false)
        holo:setMaterial("")
        timer.simple(math.rand(20, 30), Blacken)
    end
    
    if zapSound then
        zapSound:destroy()
        zapSound = nil
    end
    
    if isBlack and sound.canCreate() then
        if sparkSound then
            sparkSound:destroy()
            sparkSound = nil
        end
        zapSound = sound.create(holo, "ambient/energy/zap" .. zapSoundIDs[math.random(1, #zapSoundIDs)] .. ".wav", false)
        zapSound:play()
    end
end
Blacken()