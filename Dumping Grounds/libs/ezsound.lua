--@name EZ Sound
--@author Jacbo

ezsound = {}

function ezsound.play(ent, path, duration)
    if not sound.canCreate() then return nil end
    local snd = sound.create(ent, path, true)
    snd:play()
    if duration then
        timer.simple(duration, function()
            snd:destroy()
        end)
    end
    return snd
end