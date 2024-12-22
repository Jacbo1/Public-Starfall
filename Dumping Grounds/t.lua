-- Classic pre-rewrite NotSoBot tag scripting done through chat
-- Doesn't support most of this but it will support the basics https://gist.github.com/Jacbo1/3b3e2702b4b6f210872348b7b42b4cba (old outdated documentation ftw)
-- Note: responses will come from YOU

--@name .tag
--@author Jacbo
--@client

if player() == owner() then
    local persistMaxLength = 2000
    local easychat = string.find(string.lower(game.getHostname()), "meta construct", 1, true) != nil
    local tags = {} --"tag" = {owner steamid, owner name, text}
    local persistedVars = {} -- "var" = {"owner steamid" = {value, {tags}}}
    local waitingForBot = false
    local saving = false
    local lastMessage = ""
    local savingVars = false
    local validCommands = {["arg"] = true, ["if"] = true, ["read"] = true, ["write"] = true, ["get"] = true, ["set"] = true, ["replace"] = true, ["upper"] = true, ["lower"] = true, ["choose"] = true, ["range"] = true, ["substring"] = true, ["math"] = true}
    
    local data = file.read("t.txt")
    if data != nil and data != "" then
        tags = json.decode(data)
        --[[local keys = table.getKeys(tags)
        local ids = {}
        for v, k in pairs(keys) do
            if tags[k] != nil then
                local id = tags[k][1] .. ""
                if ids[id] == nil then
                    local player = find.allPlayers(function(ent)
                        return ent:getSteamID64() .. "" == id
                    end)[1]
                    if player != nil then
                        local newid = player:getSteamID()
                        ids[id] = newid
                        tags[k][1] = newid
                        saving = true
                    end
                else
                    tags[k][1] = ids[id]
                end
            end
        end
        if saving then
            print("changed")
            saving = false
            file.write("t.txt", json.encode(tags))
        end]]
    end
    data = file.read("t vars.txt")
    if data != nil and data != "" then
        persistedVars = json.decode(data)
    end
    data = nil
    
    
    
    local function updateName(tag)
        if tags[tag] != nil then
            local id = tags[tag][1]
            local player = find.allPlayers(function(ent)
                return ent:getSteamID() == id
            end)[1]
            if player != nil then
                local name = player:getName()
                if name != tags[tag][2] then
                    saving = true
                    tags[tag][2] = name
                end
            end
            if easychat then
                return tags[tag][2] .. "<stop>"
            else
                return tags[tag][2]
            end
        end
        return ""
    end
    
    local function ownerError(tag)
        if tag == "add" then
            return "Error: \"add\" is a system command"
        elseif tag == "remove" then
            return "Error: \"remove\" is a system command"
        elseif tag == "edit" then
            return "Error: \"edit\" is a system command"
        elseif tag == "owner" then
            return "Error: \"owner\" is a system command"
        elseif tag == "list" then
            return "Error: \"list\" is a system command"
        elseif tag == "help" then
            return "Error: \"help\" is a system command"
        elseif tag == "raw" then
            return "Error: \"raw\" is a system command"
        elseif tag == "view" then
            return "Error: \"view\" is a system command"
        end
        return "Error: " .. updateName(tag) .. " owns \"" .. tag .. "\""
    end
    
    local function swap(text, start, stop, with)
        if start == 1 and stop == #text then
            return with
        elseif start == 1 then
            return with .. string.sub(text, stop + 1, 1000000)
        elseif stop == #text then
            return string.sub(text, 1, start - 1) .. with
        else
            return string.sub(text, 1, start - 1) .. with .. string.sub(text, stop + 1, 1000000)
        end
    end
    
    local function findLast(haystack, needle)
        local pos = string.find(string.reverse(haystack), string.reverse(needle), 1, true)
        if pos == nil then
            return nil
        end
        return #haystack - pos - #needle + 2
    end
    
    local function findOutside(haystack, needle, start, args, vars, tag, id)
        local open = 0
        local i = start
        if #needle == 1 then
            local length = #haystack
            while i <= length do
                if haystack[i] == "{" then
                    local colon = findOutside(haystack, ":", i + 1, args, vars, tag, id)
                    local text = eval(string.sub(haystack, i + 1, colon - 1), args, vars, nil, tag, id)
                    if validCommands[text] != nil then
                        open = open + 1
                    end
                elseif haystack[i] == "}" then
                    open = open - 1
                elseif haystack[i] == needle and open == 0 then
                    return i
                end
                i = i + 1
            end
        else
            local found = ""
            local length = #haystack - #needle + 1
            while i <= length do
                if haystack[i] == "{" then
                    local colon = findOutside(haystack, ":", i + 1, args, vars, tag, id)
                    local text = eval(string.sub(haystack, i + 1, colon - 1), args, vars, nil, tag, id)
                    if validCommands[text] != nil then
                        open = open + 1
                    end
                elseif haystack[i] == "}" then
                    open = open - 1
                elseif open == 0 then
                    found = string.sub(haystack, i, i + #needle - 1)
                    if found == needle then
                        return i
                    end
                end
                i = i + 1
            end
        end
        return nil
    end
    
    function eval(text, args, vars, command, tag, id)
        local start = 1
        local stop = 1
        local open = 0
        local cmd = ""
        local cln
        local i = 1
        if command == "if" then
            local sep1 = findOutside(text, "|", 1, args, vars, tag, id)
            if sep1 == nil then
                return "If Error: No first separator found"
            end
            local sep2 = findOutside(text, "|", sep1 + 1, args, vars, tag, id)
            if sep2 == nil then
                return "If Error: No second separator found"
            end
            local sep3 = findOutside(text, "|then:", sep2 + 1, args, vars, tag, id)
            if sep3 == nil then
                return "If Error: No |then: found"
            end
            local sep4 = findOutside(text, "|else:", sep3 + 1, args, vars, tag, id)
            local s1 = eval(string.sub(text, 1, sep1 - 1), args, vars, nil, tag, id)
            local s2 = eval(string.sub(text, sep1 + 1, sep2 - 1), args, vars, nil, tag, id)
            local s3 = eval(string.sub(text, sep2 + 1, sep3 - 1), args, vars, nil, tag, id)
            local yes = false
            if s2 == "=" or s2 == "==" then
                if s1 == s3 then
                    yes = true
                end
            elseif s2 == "!=" then
                if s1 != s3 then
                    yes = true
                end
            elseif s2 == "<" then
                local n1 = tonumber(s1)
                local n2 = tonumber(s3)
                if n1 != nil and n2 != nil and n1 < n2 then
                    yes = true
                end
            elseif s2 == "<=" then
                local n1 = tonumber(s1)
                local n2 = tonumber(s3)
                if n1 != nil and n2 != nil and n1 <= n2 then
                    yes = true
                end
            elseif s2 == ">" then
                local n1 = tonumber(s1)
                local n2 = tonumber(s3)
                if n1 != nil and n2 != nil and n1 > n2 then
                    yes = true
                end
            elseif s2 == ">=" then
                local n1 = tonumber(s1)
                local n2 = tonumber(s3)
                if n1 != nil and n2 != nil and n1 >= n2 then
                    yes = true
                end
            elseif s2 == "~" then
                if string.lower(s1) == string.lower(s3) then
                    yes = true
                end
            end
            if yes then
                if sep4 == nil then
                    text = eval(string.sub(text, sep3 + 6, 1000000), args, vars, nil, tag, id)
                else
                    text = eval(string.sub(text, sep3 + 6, sep4 - 1), args, vars, nil, tag, id)
                end
            elseif sep4 == nil then
                text = ""
            else
                text = eval(string.sub(text, sep4 + 6, 1000000), args, vars, nil, tag, id)
            end
            return text
        else
            while i <= #text do
                if text[i] == "{" then
                    local colon = findOutside(text, ":", i + 1, args, vars, tag, id)
                    if colon != nil then
                        local com = string.sub(text, i + 1, colon - 1)
                        if validCommands[com] != nil then
                            if open == 0 then
                                cln = colon
                                start = i
                                cmd = com
                            end
                            open = open + 1
                        end
                    end
                elseif text[i] == "}" then
                    open = open - 1
                    if open == 0 then
                        stop = i
                        text = swap(text, start, stop, eval(string.sub(text, cln + 1, stop - 1), args, vars, cmd, tag, id))
                        i = start - 1
                    end
                end
                i = i + 1
            end
        end
        
        if command != nil then
            if command == "arg" then
                local n = tonumber(text)
                if n != nil then
                    text = args[n + 1]
                    if text == nil then
                        text = ""
                    end
                else
                    text = "Arg Error: Arg is nil or not a number"
                end
            elseif command == "choose" then
                local ar = string.explode("|", text)
                if #ar == 0 then
                    text = ""
                elseif #ar == 1 then
                    text = ar[1]
                else
                    text = ar[math.random(1, #ar)]
                end
            elseif command == "range" then
                local sep = string.find(text, "|", 1, true)
                if sep != nil then
                    local n1 = tonumber(string.sub(text, 1, sep - 1))
                    local n2 = tonumber(string.sub(text, sep + 1, 1000000))
                    if n1 != nil and n2 != nil then
                        text = tostring(math.random(n1, n2))
                    elseif n1 == nil and n2 == nil then
                        Text = "Range Error: Arg1 and Arg2 are nil or not numbers"
                    elseif n1 == nil then
                        Text = "Range Error: Arg1 is nil or not a number"
                    elseif n2 == nil then
                        Text = "Range Error: Arg2 is nil or not a number"
                    end
                else
                    text = "Range Error: No separator found"
                end
            elseif command == "replace" then
                local sep1 = string.find(text, "|", 1, true)
                if sep1 == nil then
                    return "Replace Error: No first separator found"
                end
                local sep2 = string.find(text, "|", sep1 + 1, true)
                if sep2 == nil then
                    return "Replace Error: No second separator found"
                end
                local arg1 = string.sub(text, sep2 + 1, 1000000)
                local arg2 = string.sub(text, 1, sep1 - 1)
                local arg3 = string.sub(text, sep1 + 1, sep2 - 1)
                if string.sub(arg2, 1, 5) == "with:" then
                    arg2 = swap(arg2, 1, 5, "")
                end
                if string.sub(arg3, 1, 3) == "in:" then
                    arg3 = swap(arg3, 1, 3, "")
                end
                text = string.replace(arg1, arg2, arg3)
            elseif command == "upper" then
                text = string.upper(text)
            elseif command == "lower" then
                text = string.lower(text)
            elseif command == "math" then
            local precedences = {["+"] = 1, ["-"] = 1, ["*"] = 2, ["/"] = 2, ["%"] = 2, ["^"] = 3, ["("] = 4, [")"] = 4, ["sin"] = 4, ["cos"] = 4, ["tan"] = 4, ["asin"] = 4, ["acos"] = 4, ["atan"] = 4, ["min"] = 4, ["max"] = 4, ["clamp"] = 4, ["floor"] = 4, ["ceil"] = 4, ["abs"] = 4}
                local negatable = {["+"] = true, ["-"] = true, ["*"] = true, ["/"] = true, ["%"] = true, ["^"] = true, ["("] = true}
                local oldpieces = string.explode("|", text)
                local pieces = {}
                --Fix negatives
                for i = 1, #oldpieces do
                    local n = tonumber(oldpieces[i])
                    if n == nil then
                        if oldpieces[i] == "sin(" then
                            table.insert(pieces, "sin")
                            table.insert(pieces, "(")
                        elseif oldpieces[i] == "asin(" then
                            table.insert(pieces, "asin")
                            table.insert(pieces, "(")
                        elseif oldpieces[i] == "cos(" then
                            table.insert(pieces, "cos")
                            table.insert(pieces, "(")
                        elseif oldpieces[i] == "acos(" then
                            table.insert(pieces, "acos")
                            table.insert(pieces, "(")
                        elseif oldpieces[i] == "tan(" then
                            table.insert(pieces, "atan")
                            table.insert(pieces, "(")
                        elseif oldpieces[i] == "min(" then
                            table.insert(pieces, "min")
                            table.insert(pieces, "(")
                        elseif oldpieces[i] == "max(" then
                            table.insert(pieces, "max")
                            table.insert(pieces, "(")
                        elseif oldpieces[i] == "clamp(" then
                            table.insert(pieces, "clamp")
                            table.insert(pieces, "(")
                        elseif oldpieces[i] == "floor(" then
                            table.insert(pieces, "floor")
                            table.insert(pieces, "(")
                        elseif oldpieces[i] == "ceil(" then
                            table.insert(pieces, "ceil")
                            table.insert(pieces, "(")
                        elseif oldpieces[i] == "abs(" then
                            table.insert(pieces, "abs")
                            table.insert(pieces, "(")
                        else
                            table.insert(pieces, oldpieces[i])
                        end
                    else --Number
                        if #pieces > 1 then
                            if pieces[#pieces] == "-" and negatable[pieces[#pieces - 1]] != nil then
                                pieces[#pieces] = tostring(-n)
                            else
                                table.insert(pieces, oldpieces[i])
                            end
                        else
                            table.insert(pieces, oldpieces[i])
                        end
                    end
                end
                
                if #pieces > 1 then
                    local n = tonumber(pieces[2])
                    if n != nil and pieces[1] == "-" then
                        pieces[2] = tostring(-n)
                        table.remove(pieces, 1)
                    end
                end
                
                --
                
                local operators = {}
                local postFix = {}
                for i = 1, #pieces do
                    if tonumber(pieces[i]) == nil then
                        if pieces[i] == ")" then
                            while #operators != 0 and operators[#operators] != "(" do
                                table.insert(postFix, table.remove(operators))
                            end
                            if #operators != 0 then
                                table.remove(operators)
                            end
                        elseif pieces[i] == "(" then
                            table.insert(operators, pieces[i])
                        else
                            local curScore = precedences[pieces[i]]
                            if curScore == nil then
                                return "Math Error: Invalid operator \"" .. pieces[i] .. "\""
                            end
                            if #operators == 0 then
                                table.insert(operators, pieces[i])
                            else
                                local top = operators[#operators]
                                local topScore = precedences[top]
                                if topScore == nil then
                                    return "Math Error: Invalid operator \"" .. top .. "\""
                                end
                                if top == "(" or topScore < curScore then
                                    table.insert(operators, pieces[i])
                                else
                                    while #operators != 0 and top != "(" and topScore >= curScore do
                                        table.insert(postFix, top)
                                        table.remove(operators)
                                        if #operators != 0 then
                                            top = operators[#operators]
                                            topScore = precedences[top]
                                            if topScore == nil then
                                                return "Math Error: Invalid operator \"" .. top .. "\""
                                            end
                                        end
                                    end
                                    table.insert(operators, pieces[i])
                                end
                            end
                        end
                    else --Number
                        table.insert(postFix, pieces[i])
                    end
                end
                
                for i = #operators, 1, -1 do
                    table.insert(postFix, operators[i])
                end
                table.empty(operators)
                
                --Calculate
                for i = 1, #postFix do
                    local n = tonumber(postFix[i])
                    if n == nil then
                        if postFix[i] == "sin" then
                            if #operators != 0 then
                                operators[#operators] = math.sin(operators[#operators])
                            else
                                return "Math Error: sin has no number"
                            end
                        elseif postFix[i] == "asin" then
                            if #operators != 0 then
                                operators[#operators] = math.asin(operators[#operators])
                            else
                                return "Math Error: asin has no number"
                            end
                        elseif postFix[i] == "cos" then
                            if #operators != 0 then
                                operators[#operators] = math.cos(operators[#operators])
                            else
                                return "Math Error: cos has no number"
                            end
                        elseif postFix[i] == "acos" then
                            if #operators != 0 then
                                operators[#operators] = math.acos(operators[#operators])
                            else
                                return "Math Error: acos has no number"
                            end
                        elseif postFix[i] == "tan" then
                            if #operators != 0 then
                                operators[#operators] = math.tan(operators[#operators])
                            else
                                return "Math Error: tan has no number"
                            end
                        elseif postFix[i] == "atan" then
                            if #operators != 0 then
                                operators[#operators] = math.atan(operators[#operators])
                            else
                                return "Math Error: atan has no number"
                            end
                        elseif postFix[i] == "+" then
                            if #operators == 0 then
                                return "Math Error: + has no numbers"
                            elseif #operators == 1 then
                                return "Math Error: + has no second number"
                            else
                                table.insert(operators, table.remove(operators) + table.remove(operators))
                            end
                        elseif postFix[i] == "*" then
                            if #operators == 0 then
                                return "Math Error: * has no numbers"
                            elseif #operators == 1 then
                                return "Math Error: * has no second number"
                            else
                                table.insert(operators, table.remove(operators) * table.remove(operators))
                            end
                        elseif postFix[i] == "-" then
                            if #operators == 0 then
                                return "Math Error: - has no numbers"
                            elseif #operators == 1 then
                                operators[#operators] = -operators[#operators]
                            else
                                local n2 = table.remove(operators)
                                local n1 = table.remove(operators)
                                table.insert(operators, n1 - n2)
                            end
                        elseif postFix[i] == "/" then
                            if #operators == 0 then
                                return "Math Error: / has no numbers"
                            elseif #operators == 1 then
                                return "Math Error: / has no second number"
                            else
                                local n2 = table.remove(operators)
                                local n1 = table.remove(operators)
                                table.insert(operators, n1 / n2)
                            end
                        elseif postFix[i] == "%" then
                            if #operators == 0 then
                                return "Math Error: % has no numbers"
                            elseif #operators == 1 then
                                return "Math Error: % has no second number"
                            else
                                local n2 = table.remove(operators)
                                local n1 = table.remove(operators)
                                table.insert(operators, n1 % n2)
                            end
                        elseif postFix[i] == "^" then
                            if #operators == 0 then
                                return "Math Error: ^ has no numbers"
                            elseif #operators == 1 then
                                return "Math Error: ^ has no second number"
                            else
                                local n2 = table.remove(operators)
                                local n1 = table.remove(operators)
                                table.insert(operators, n1 ^ n2)
                            end
                        elseif postFix[i] == "min" then
                            if #operators == 0 then
                                return "Math Error: min has no numbers"
                            elseif #operators == 1 then
                                return "Math Error: min has no second number"
                            else
                                table.insert(operators, math.min(table.remove(operators), table.remove(operators)))
                            end
                        elseif postFix[i] == "max" then
                            if #operators == 0 then
                                return "Math Error: max has no numbers"
                            elseif #operators == 1 then
                                return "Math Error: max has no second number"
                            else
                                table.insert(operators, math.max(table.remove(operators), table.remove(operators)))
                            end
                        elseif postFix[i] == "clamp" then
                            if #operators == 0 then
                                return "Math Error: clamp has no numbers"
                            elseif #operators == 1 then
                                return "Math Error: clamp has no second number"
                            elseif #operators == 2 then
                                return "Math Error: clamp has no third number"
                            else
                                local n3 = table.remove(operators)
                                local n2 = table.remove(operators)
                                local n1 = table.remove(operators)
                                table.insert(operators, math.clamp(n1, n2, n3))
                            end
                        elseif postFix[i] == "floor" then
                            if #operators == 0 then
                                return "Math Error: floor has no number"
                            else
                                operators[#operators] = math.floor(operators[#operators])
                            end
                        elseif postFix[i] == "ceil" then
                            if #operators == 0 then
                                return "Math Error: ceil has no number"
                            else
                                operators[#operators] = math.ceil(operators[#operators])
                            end
                        elseif postFix[i] == "abs" then
                            if #operators == 0 then
                                return "Math Error: abs has no number"
                            else
                                operators[#operators] = math.abs(operators[#operators])
                            end
                        else
                            return "Math Error: Invalid operator \"" .. postFix[i] .. "\""
                        end
                    else --Number
                        table.insert(operators, n)
                    end
                end
                
                if #operators == 1 then
                    text = tostring(operators[1])
                else
                    return "Math Error: Too many results"
                end
        
            elseif command == "set" then
                local sep = string.find(text, "|", 1, true)
                if sep == nil then
                    text = "Set Error: No separator found"
                else
                    vars[string.sub(text, 1, sep - 1)] = string.sub(text, sep + 1, 1000000)
                    text = ""
                end
            elseif command == "get" then
                text = vars[text]
                if text == nil then
                    text = ""
                end
            elseif command == "substring" then
                local sep1 = string.find(text, "|", 1, true)
                if sep1 == nil then
                    return "Substring Error: No first separator found"
                end
                local sep2 = string.find(text, "|", sep1 + 1, true)
                if sep2 == nil then
                    return "Substring Error: No second separator found"
                end
                local n1 = tonumber(string.sub(sep1 + 1, sep2 - 1))
                local n2 = tonumber(string.sub(sep2 + 1, 10000000))
                if n1 == nil then
                    return "Substring Error: Start is nil or not a number"
                end
                if n2 == nil then
                    return "Substring Error: End is nil or not a number"
                end
                text = string.sub(string.sub(text, 1, sep1 - 1), n1 + 1, n2)
            elseif command == "write" then
                local sep = string.find(text, "|", 1, true)
                if sep == nil then
                    text = "Write Error: No separator found"
                else
                    local value = string.sub(text, sep + 1, 1000000)
                    local var = string.sub(text, 1, sep - 1)
                    if #value <= persistMaxLength then
                        if persistedVars[var] == nil then
                            persistedVars[var] = {[id] = {value, {tag}}}
                            savingVars = true
                        elseif persistedVars[var][id] == nil then
                            persistedVars[var][id] = {value, {tag}}
                            savingVars = true
                        else
                            persistedVars[var][id][1] = value
                            local found = false
                            for v, k in pairs(persistedVars[var][id][2]) do
                                if k == tag then
                                    found = true
                                    break
                                end
                            end
                            if not found then
                                table.insert(persistedVars[var][id][2], tag)
                            end
                            savingVars = true
                        end
                        text = ""
                    else
                        text = "Write Error: Value for \"" .. var .. "\" is too long! Max length is " .. persistMaxLength .. ". Value length is " .. #value
                    end
                end
            elseif command == "read" then
                if persistedVars[text] == nil or persistedVars[text][id] == nil or persistedVars[text][id][1] == nil then
                    text = ""
                else
                    text = persistedVars[text][id][1]
                end
            end
        end
        
        return text
    end
    
    local function replaceOnce(text, replacee, replacer)
        local start = string.find(text, replacee, 1, true)
        if start == nil then
            return text, false
        else
            local stop = start + #replacee - 1
            if start == 1 and stop == #text then
                return replacer, true
            elseif start == 1 then
                return replacer .. string.sub(text, stop + 1, 10000000), true
            elseif stop == #text then
                return string.sub(text, 1, start - 1) .. replacer, true
            else
                return string.sub(text, 1, start - 1) .. replacer .. string.sub(text, stop + 1, 10000000), true
            end
        end
    end
    
    local function eval2(text, afterTag, name, id, argslen, easychat, args, tag)
        text = string.replace(text, "{args}", afterTag)
        text = string.replace(text, "{argslen}", tostring(argslen))
        text = string.replace(text, "{user}", name)
        text = string.replace(text, "{mention}", name)
        text = string.replace(text, "{id}", id)
        text = string.replace(text, "{server}", game.getHostname())
        text = string.replace(text, "{servercount}", tostring(#find.allPlayers()))
        text = string.replace(text, "{serverid}", game.getHostname())
        text = string.replace(text, "{time}", os.time())
        if easychat then
            text = string.replace(text, "{easychat}", "true")
            text = string.replace(text, "{nick}", name .. "<stop>")
        else
            text = string.replace(text, "{easychat}", "false")
            text = string.replace(text, "{nick}", name)
        end
        text = string.replace(text, "{randonline}", "{randuser}")
        
        local players = find.allPlayers()
        
        local changed = true
        while changed do
            if easychat then
                text, changed = replaceOnce(text, "{randuser}", players[math.random(1, #players)]:getName() .. "<stop>")
            else
                text, changed = replaceOnce(text, "{randuser}", players[math.random(1, #players)]:getName())
            end
        end
        
        text = eval(text, args, {}, nil, tag, id)
        
        return text
    end
    
    hook.add("PlayerChat", "tag", function(ply, text, Team, isdead)
        if ply == owner() and lastMessage == text and waitingForBot then
            waitingForBot = false
        else
            --[[if ply == owner() and waitingForBot then
                print(text .. "\n!=\n" .. lastMessage)
            end]]
            if string.sub(text, 1, 4) == ".tag" then
                local result = "Unknown error"
                if #text > 5 then
                    local name = ply:getName()
                    local id = ply:getSteamID() .. ""
                    local args = string.explode(" ", text)
                    table.remove(args, 1)
                    local argslen = #args - 1
                    local tag = args[2]
                    
                    if args[1] == "help" then
                        result = "https://mods.nyc/help/"
                    elseif args[1] == "add" then
                        if argslen > 1 then
                            local ar = tags[tag]
                            if ar == nil then
                                tags[tag] = {id, name, string.sub(text, string.find(text, " ", string.find(text, " ", 6, true) + 1, true) + 1)}
                                saving = true
                                result = "Added tag \"" .. tag .. "\""
                            else
                                result = ownerError(tag)
                            end
                        elseif argslen == 1 then
                            result = "Error: No text specified. Format: .t add <tag> <text>"
                        else
                            result = "Error: No tag specified. Format: .t add <tag> <text>"
                        end
                    elseif args[1] == "remove" then
                        if argslen > 0 then
                            local ar = tags[tag]
                            if ar == nil then
                                result = "Error: Tag \"" .. tag .. "\" does not exist"
                            elseif ar[1] == id then
                                local keys = table.getKeys(persistedVars)
                                local i = 1
                                while i <= #keys do
                                    local j = 1
                                    if persistedVars[keys[i]][id] != nil then
                                        while j <= #persistedVars[keys[i]][id][2] do
                                            if persistedVars[keys[i]][id][2][j] == tag then
                                                savingVars = true
                                                table.remove(persistedVars[keys[i]][id][2], j)
                                                j = j - 1
                                            end
                                            j = j + 1
                                        end
                                        if #persistedVars[keys[i]][id][2] == 0 then
                                            persistedVars[keys[i]][id] = nil
                                            savingVars = true
                                            if next(persistedVars[keys[i]]) == nil then
                                                persistedVars[keys[i]] = nil
                                                savingVars = true
                                            end
                                        end
                                    end
                                    i = i + 1
                                end
                                
                                
                                tags[tag] = nil
                                saving = true
                                result = "Removed tag \"" .. tag .. "\""
                            else
                                result = ownerError(tag)
                            end
                        else
                            result = "Error: No tag specified. Format: .t remove <tag>"
                        end
                    elseif args[1] == "edit" then
                        if argslen > 1 then
                            local ar = tags[tag]
                            if ar == nil then
                                result = "Error: Tag \"" .. tag .. "\" does not exist"
                            elseif ar[1] == id then
                                tags[tag] = {id, name, string.sub(text, string.find(text, " ", string.find(text, " ", 6, true) + 1, true) + 1)}
                                saving = true
                                result = "Edited tag \"" .. tag .. "\""
                            else
                                result = ownerError(tag)
                            end
                        elseif argslen == 1 then
                            result = "Error: No text specified. Format: .t edit <tag> <text>"
                        else
                            result = "Error: No tag specified. Format: .t edit <tag> <text>"
                        end
                    elseif args[1] == "owner" then
                        if argslen > 0 then
                            local ar = tags[tag]
                            if ar == nil then
                                result = "Error: Tag \"" .. tag .. "\" does not exist"
                            else
                                if tag == "add" then
                                    result = "\"add\" is a system command"
                                elseif tag == "remove" then
                                    result = "\"remove\" is a system command"
                                elseif tag == "edit" then
                                    result = "\"edit\" is a system command"
                                elseif tag == "owner" then
                                    result = "\"owner\" is a system command"
                                elseif tag == "list" then
                                    result = "\"list\" is a system command"
                                elseif tag == "help" then
                                    result = "\"help\" is a system command"
                                elseif tag == "raw" then
                                    result = "\"raw\" is a system command"
                                elseif tag == "view" then
                                    result = "\"view\" is a system command"
                                else
                                    result = updateName(tag) .. " owns \"" .. tag .. "\""
                                end
                            end
                        else
                            result = "Error: No tag specified. Format: .t owner <tag>"
                        end
                    elseif args[1] == "list" then
                        result = ""
                        for tag, tagAr in pairs(tags) do
                            if tagAr[1] == id then
                                result = result .. ", " .. tag
                            end
                        end
                        if #result == 0 then
                            if easychat then
                                result = name .. "<stop> does not own any tags"
                            else
                                result = name .. " does not own any tags"
                            end
                        elseif easychat then
                            result = name .. "<stop> owns: " .. string.sub(result, 3)
                        else
                            result = name .. " owns: " .. string.sub(result, 3)
                        end
                    elseif args[1] == "raw" or args[1] == "view" then
                        if argslen > 0 then
                            local ar = tags[tag]
                            if ar == nil then
                                result = "Error: Tag \"" .. tag .. "\" does not exist"
                            else
                                updateName(tag)
                                result = ar[3]
                            end
                        else
                            result = "Error: No tag specified. Format: .t " .. args[1] .. " <tag>"
                        end
                    else
                        tag = table.remove(args, 1)
                        tagAr = tags[tag]
                        if tagAr == nil then
                            result = "Error: Tag \"" .. tag .. "\" does not exist"
                        else
                            if tagAr[4] == nil then
                                tagAr[4] = {}
                            end
                            updateName(tag)
                            result = tagAr[3]
                            local afterTag = ""
                            if argslen > 0 then
                                afterTag = string.sub(text, string.find(text, " ", 6, true) + 1, 1000000)
                            end
                            
                            for i = 1, #args do
                                args[i] = eval2(args[i], afterTag, name, id, argslen, easychat, args, tag)
                            end
                            
                            result = eval2(result, afterTag, name, id, argslen, easychat, args, tag)
                        end
                    end
                else
                    result = ".tag <tag>, .tag <tag> <text>, .tag add <tag>, .tag remove <tag>, .tag edit <tag>, .tag owner <tag>, .tag list, .tag raw <tag>, say .tag help for tag scripting help (open the link and scroll all the way to the bottom)"
                end
                
                if result != "" then
                    waitingForBot = true
                    lastMessage = string.replace(result, "\"", "")
                    local cmd = "say \"" .. result .. "\""
                    timer.simple(1, function()
                        concmd(cmd)
                    end)
                end
            end
            
            if saving then
                saving = false
                file.write("t.txt", json.encode(tags))
            end
            if savingVars then
                savingVars = false
                file.write("t vars.txt", json.encode(persistedVars))
            end
        end
    end)
end