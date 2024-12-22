-- Lets you play a sound on players when they do .snd <file url>

--@name WebSound
--@author Jacbo
--@client

local sounds = {}

hook.add("PlayerChat", "", function(ply, text)
    try(function()
    if string.find(text, "^[!%./]snd .+", 1) then
        local url = string.sub(text, 6)
        if string.find(url, "https://www%.dropbox%.com/s/.+", 1) then
            url = "https://dl.dropboxusercontent.com/s/" .. string.sub(url, 27, #url - 5)
        elseif string.find(url, "https://drive%.google%.com/file/d/.+", 1) then
            url = "https://drive.google.com/uc?export=download&id=" .. string.sub(url, 33, string.find(url, "/", 33, true) - 1)
        end
        bass.loadURL(url, "3d", function(sound)
            if not sound or not sound:isValid() then return end
            
            sound:setPos(ply:getPos())
            sound:play()
            local t = {ply, sound}
            table.insert(sounds, t)
            timer.simple(sound:getLength(), function()
                table.removeByValue(sounds, t)
                try(function()
                    sound:destroy()
                end)
            end)
        end)
    end
    
    if text == "sh" then
        for _, pair in ipairs(sounds) do
            try(function()
                pair[1]:destroy()
            end)
        end
        sounds = {}
    end
    end)
end)

hook.add("think", "", function()
    for _, pair in ipairs(sounds) do
        pair[2]:setPos(pair[1]:getPos())
    end
end)