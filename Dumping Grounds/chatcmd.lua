--@name Chat Commands
--@author Jacbo
--@shared
--@include safeNet.txt

--[[
    Can be used client side or server side
    Listeners are client side
    Multiple clients can have different versions of the same command
    

    FUNCTION addChatCommand(prefix, name, arglength, ownerOnly, hidechat, callback)
    
    prefix is nil, string, or table of possible prefixes such as . or /
    defaults to . or / or !
    
    name is the command name string e.g. setpos
    
    arglength is a number or nil that, if specified, will ignore command calls that do not match the argument length
    arguments are separated by spaces
    
    callback is a callback function called with callback(args, player)
    args is the substring of everything after the space following the command name
    player is the player who used the command
    
    ownerOnly is a boolean or nil that determines whether to ignore players that are not the one who created the command
    defaults to false
    The owner is whatever player created the command so it may not be the owner of the chip
    Owner is owner() serverside
    
    hidechat is a boolean or nil that hides the player's chat message
    Only works if the owner used the chat command
    
    
    
    FUNCTION removeChatCommand(name)
    
    removes the chat command specified by this name (if used client side, it will only remove that client's listener)
]]

local net = require("safeNet.txt")

if SERVER then
    -- {{server}, {client}}
    local commands = {{}, {}}
    net.receive("chatcmd add cmd", function(_, ply)
        local hasPrefix = net.readBool()
        local prefix = net.readTable()
        local name = net.readString()
        local arglength = safeNet and net.readInt16() or net.readInt(16)
        local ownerOnly = net.readBool()
        local hide = net.readBool()
        local netName = net.readString()
        
        local t = commands[2][name]
        if not t then
            commands[2][name] = {}
            t = commands[2][name]
        end
        
        try(function() -- Safety blanket incase ply is now invalid
            t[ply:getSteamID()] = {hasPrefix, prefix, arglength, netName, ownerOnly, hide, ply}
        end)
    end)
    
    net.receive("chatcmd rm cmd", function(_, ply)
        local name = net.readString()
        
        local t = commands[2][name]
        if t then
            try(function() -- Safety blanket incase ply is now invalid
                t[ply:getSteamID()] = nil
                if not table.findNext(t) then
                    commands[2][name] = nil
                end
            end)
        end
    end)
    
    function addChatCommand(prefix, name, arglength, ownerOnly, hidechat, callback)
        if type(prefix) == "string" then
            prefix = {prefix}
        end
        
        commands[1][name] = {
            prefix and true or false,
            prefix or {".", "/", "!"},
            arglength or -1,
            callback,
            ownerOnly == true and true or false,
            hidechat == true and true or false
        }
    end
    
    function removeChatCommand(name)
        commands[1][name] = nil
    end
    
    local string_find = string.find
    local string_sub = string.sub
    local string_startWith = string.startWith
    local string_explode = string.explode
    hook.add("PlayerSay", "chatcmd", function(ply, text)
        local hidechat = false
        local remove = {}
        local hasDefaultPrefix = string_find(string_sub(text, 1, 1), "[./!]") ~= nil
        
        -- Server side chat commands
        for cmd, tbl in pairs(commands[1]) do
            -- Check for owner only
            if tbl[5] and ply ~= owner() then continue end
            
            -- Check for prefix
            local usesCustomPrefix = tbl[1]
            local start, hasPrefix
            if usesCustomPrefix then
                -- Check prefixes
                for _, prefix in ipairs(tbl[2]) do
                    hasPrefix = string_startWith(text, prefix)
                    if hasPrefix then
                        start = #prefix + 1
                        break
                    end
                end
            else
                -- Uses default prefix
                start = 2
                hasPrefix = hasDefaultPrefix
            end
            
            -- Check for name
            if hasPrefix then
                local stop = #cmd + start
                if string_sub(text, start, stop-1) == cmd then
                    -- Has name
                    -- Check for arg length
                    local args = string_sub(text, stop+1)
                    if tbl[3] == -1 or ((tbl[3] == 0 and args == "") or tbl[3] == #string_explode(" ", args)) then
                        -- Success
                        tbl[4](args, ply)
                        if tbl[6] and ply == tbl[7] then
                            -- Hide chat
                            hidechat = true
                        end
                    end
                    break
                end
            end
        end
        
        -- Client side chat commands
        for cmd, tbl2 in pairs(commands[2]) do
            local doBreak = false
            for id, tbl in pairs(tbl2) do
                -- Check for owner only
                if tbl[5] and ply ~= tbl[7] then continue end
            
                -- Check for prefix
                local usesCustomPrefix = tbl[1]
                local start, hasPrefix
                if usesCustomPrefix then
                    -- Check prefixes
                    for _, prefix in ipairs(tbl[2]) do
                        hasPrefix = string_startWith(text, prefix)
                        if hasPrefix then
                            start = #prefix + 1
                            break
                        end
                    end
                else
                    -- Uses default prefix
                    start = 2
                    hasPrefix = hasDefaultPrefix
                end
            
                -- Check for name
                if hasPrefix then
                    local stop = #cmd + start
                    if string_sub(text, start, stop-1) == cmd then
                        -- Has name
                        -- Check for arg length
                        local args = string_sub(text, stop+1)
                        if tbl[3] == -1 or ((tbl[3] == 0 and args == "") or tbl[3] == #string_explode(" ", args)) then
                            -- Success
                            if tbl[7] and tbl[7]:isValid() and tbl[7]:isPlayer() then
                                -- Valid player
                                net.start(tbl[4])
                                if safeNet then net.writeData2(args)
                                else net.writeString(args) end
                                net.writeEntity(ply)
                                net.send(tbl[7])
                                
                                if tbl[6] and ply == tbl[7] then
                                    -- Hide chat
                                    hidechat = true
                                end
                            else
                                -- Invalid player
                                table.insert(remove, {cmd, id})
                            end
                        end
                        doBreak = true
                    end
                end
            end
            
            if doBreak then break end
        end
        
        for _, set in ipairs(remove) do
            local t = commands[2][set[1]]
            t[set[2]] = nil
            if not table.findNext(t) then
                commands[2][set[1]] = nil
            end
        end
        
        if hidechat then
            return ""
        end
    end)
else -- CLIENT
    function addChatCommand(prefix, name, arglength, ownerOnly, hidechat, callback)
        net.receive("chatcmd CB " .. name, function()
            callback(safeNet and net.readData2() or net.readString(), net.readEntity())
        end)
        
        if type(prefix) == "string" then
            prefix = {prefix}
        end
        
        net.start("chatcmd add cmd")
        net.writeBool(prefix and true or false)
        net.writeTable(prefix or {".", "/", "!"})
        net.writeString(name)
        if safeNet then net.writeInt16(arglength or -1)
        else net.writeInt(arglength or -1, 16) end
        net.writeBool(ownerOnly == true and true or false)
        net.writeBool(hidechat == true and true or false)
        net.writeString("chatcmd CB " .. name)
        net.send()
    end
    
    function removeChatCommand(name)
        net.receive("chatcmd CB " .. name)
        
        net.start("chatcmd rm cmd")
        net.writeString(name)
        net.send()
    end
end