--@name !fpscontest or !pingcontest
--@author Jacbo
--@shared

if SERVER then
    --FPS
    local awaitingPlayers = {}
    local FPSs = {}
    net.receive("fps contest start", function(_, ply)
        awaitingPlayers = find.allPlayers(function(ent)
            if ent:isBot() then
                return false
            end
            return true
        end)
        FPSs = {}
        net.start("fps contest")
        net.send()
    end)
    net.receive("fps contest", function(_, ply)
        local found = table.removeByValue(awaitingPlayers, ply)
        if found then
            table.insert(FPSs, {ply, net.readUInt(16)})
            if #awaitingPlayers == 0 then
                local min = math.huge
                local max = 0
                local minPlayer = null
                local maxPlayer = null
                local average = 0
                for v, k in pairs(FPSs) do
                    if k[2] < min then
                        min = k[2]
                        minPlayer = k[1]
                    end
                    if k[2] > max then
                        max = k[2]
                        maxPlayer = k[1]
                    end
                    average = average + k[2]
                end
                average = math.round(average / #FPSs)
                net.start("fps contest results")
                net.writeString(maxPlayer:getName())
                net.writeUInt(max, 16)
                net.writeString(minPlayer:getName())
                net.writeUInt(min, 16)
                net.writeUInt(average, 16)
                net.writeUInt(math.round(1 / timer.frametime()), 16)
                net.send()
            end
        end
    end)
    --Ping
    net.receive("ping contest", function(_, ply)
        local players = find.allPlayers(function(ent)
            if ent:isBot() then
                return false
            end
            return true
        end)
        local min = math.huge
        local max = 0
        local minPlayer = null
        local maxPlayer = null
        local average = 0
        for v, player in pairs(players) do
            local ping = player:getPing()
            if ping < min then
                min = ping
                minPlayer = player
            end
            if ping > max then
                max = ping
                maxPlayer = player
            end
            average = average + ping
        end
        average = math.round(average / #players)
        net.start("ping contest")
        net.writeString(maxPlayer:getName())
        net.writeUInt(max, 16)
        net.writeString(minPlayer:getName())
        net.writeUInt(min, 16)
        net.writeUInt(average, 16)
        net.send()
    end)
else
    if player() == owner() then
        hook.add("PlayerChat", "", function(ply, text, Team, isdead)
            local lower = string.lower(text)
            if lower == "!fpscontest" then
                net.start("fps contest start")
                net.send()
            elseif lower == "!pingcontest" then
                net.start("ping contest")
                net.send()
            end
        end)
        net.receive("ping contest", function(_, ply)
            local s = "say Highest ping: " .. net.readString() .. ": " .. net.readUInt(16) .. " Lowest ping: " .. net.readString() .. ": " .. net.readUInt(16) .. " Average: " .. net.readUInt(16)
            timer.simple(1, function()
                concmd(s)
            end)
        end)
        net.receive("fps contest results", function(_, ply)
            local s = "say Highest FPS: " .. net.readString() .. ": " .. net.readUInt(16) .. " Lowest FPS: " .. net.readString() .. ": " .. net.readUInt(16) .. " Average: " .. net.readUInt(16) .. " Server: " .. net.readUInt(16)
            timer.simple(1, function()
                concmd(s)
            end)
        end)
    end
    net.receive("fps contest", function(_, ply)
        net.start("fps contest")
        net.writeUInt(math.round(1 / timer.frametime()), 16)
        net.send()
    end)
end