-- This was really good before but specific to E2 Beyond Infinity (server).
-- Custom chat window with image embedding and emoji support tho the emojis were for E2BI's Discord relay.
-- Don't remember how it broke. Good luck if you want to try fixing it.
-- Here's what it looks like when it works: https://i.imgur.com/GbTo9Ef.png
-- I think it might require injecting one of the chat hooks into your clientside starfall

--@name Custom Chat
--@author Jacbo
--@shared
--@include funcs.txt
--@include better_coroutines.txt

local corlib = require("better_coroutines.txt")
require("funcs.txt")
if SERVER then
    
elseif player() == owner() then
    hook.add("RelayImage", "", function()
        return false
    end)
    local init = true
    local width, height
    local border = 1 / 1080
    local textOffset = 5 / 1080
    local fontSize = 20 / 1080
    local verticalSpacing = 1
    local fadeStart = 15
    local fadeTime = 2
    local emojiSize = 35 / 1080
    local maxImageSize = {1, 0.3}
    local chatbox = {
        musicPlayer = {
            w = 0.4, -- This one is relative to height
            h = 0.2
        },
        bounds = {
            x = 0,
            y = 0,
            w = 0,
            h = 0
        },
        native = {
            x = 22/1920,
            y = 618/1080,
            w = 720/1920,
            h = 270/1080
        },
        text = {},
        min = {
            bounds = {
                x = 0.0115,
                --y = 0.5,
                y = 0.2225,
                w = 0.3,
                --w = 0.3,
                --h = 0.3225
                h = 0.55
            },
            chat = {
                --[[getTextStart = function()
                    return chatbox.min.chat.x + textOffset,
                        chatbox.min.chat.y + textOffset
                end]]
            }--[[,
            say = {
                text = {},
                getBounds = function()
                    local x = chatbox.min.say.x + textOffset
                    local y = chatbox.min.say.y + (chatbox.min.say.h - fontSize)*0.5 - (#chatbox.min. + textOffset
                    return {
                        x = x
                        y = y
                end
            }]]
        },
        max = {
            x = 0.1,
            y = 0.5,
            w = 1,
            h = 1
        }
    }

    render.createRenderTarget("")

    hook.add("renderoffscreen", "", function()
        render.selectRenderTarget("")
        render.clear(Color(0,0,0,0))
        render.drawRect(0,0,1024,1024)
        hook.remove("renderoffscreen", "")
    end)

    local chatOpen = false
    hook.add("StartChat", "", function()
        chatOpen = true
        --[[hook.add("drawhud", "chat open", function()
            local cursorx, cursory = input.getCursorPos()
            local native = chatbox.native
            local w = chatbox.musicPlayer.w
            local h = chatbox.musicPlayer.h
            --local x = math.max(native.x + native.w, chatbox.bounds.x + chatbox.bounds.w)
            local x = native.x + native.w
            local y = chatbox.native.y + chatbox.native.h - h
            render.setRGBA(100, 100, 100, 150)
            render.drawRectOutline(x, y-2, w+2, h+2)
            render.setRGBA(0, 0, 0, 100)
            render.drawRect(x+1, y-1, w, h)
        end)]]
    end)
    hook.add("FinishChat", "", function()
        chatOpen = false
        --hook.remove("drawhud", "chat open")
    end)

    hook.add("hudshoulddraw", "", function(hudElName)
        if hudElName == "CHudChat" and not chatOpen then
            return false
        end
    end)
    
    local wrapQueue = {}
    
    local function addText(...)
        local t = {...}
        local text = {}
        if #t == 1 then
            text = {Color(255, 255, 255)}
        end
        local x = 0
        local lastPiece
        for _, piece in ipairs(t) do
            if type(piece) == "table" then
                --Color
                for key, _ in pairs(piece) do
                    if key ~= "r" and key ~= "g" and key ~= "b" and key ~= "a" then
                        print(key)
                    end
                end
                table.insert(text, Color(piece.r, piece.g, piece.b, piece.a))
            else
                --Text
                table.insert(text, tostring(piece))
                --if lastPiece == ":" and (piece == "<:xok:751251641755369540>" or piece == "<:trollhd:838628657525555220>" or piece == "<a:sosiska:854004707059957791>") then return end
                --if piece == "<:xok:751251641755369540>" or piece == "<:trollhd:838628657525555220>" or piece == "<a:sosiska:854004707059957791>" then return end
                if string.find(piece, "<:xok:751251641755369540>", 1, true) or string.find(piece, "<:trollhd:838628657525555220>", 1, true) or string.find(piece, "<a:sosiska:854004707059957791>", 1, true) or string.find(piece, "<:xok:854832352659767346>", 1, true) then return end
                lastPiece = piece
            end
        end
        table.insert(wrapQueue, text)
    end
    
    local maxMats = 20
    local mats = {}
    local matOrder = {}
    local function getMat(url, failCB, successCB, scaleUp)
        if scaleUp == nil then
            scaleUp = true
        end
        local mattbl = mats[url]
        if mattbl then
            if successCB then
                successCB(mattbl[2], mattbl[3])
            end
            return mattbl[1], true
        else
            mats[url] = {nil, 1, 1}
            if #matOrder >= maxMats then
                local key = table.remove(matOrder, 1)
                try(function()
                    mats[key]:destroy()
                end)
                mats[key] = nil
            end
            table.insert(matOrder, url)
            local index = #matOrder
            local mat
            mat = funcs.loadMat(url, 0, 0, nil, "$basetexture", scaleUp, function(_, _, x, y, w, h)
                mats[url][1] = mat
                mats[url][2] = w
                mats[url][3] = h
                if successCB then
                    successCB(w, h)
                end
            end, function()
                mats[table.remove(matOrder, index)] = nil
                if failCB then
                    failCB()
                end
            end)
            return mat, false
        end
    end
    local renderGetTextSize = render.getTextSize
    local tableInsert = table.insert
    local stringExplode = string.explode
    local wrapText = corlib.wrap(function()
        local bounds = chatbox.min.bounds
        local bw = bounds.w - textOffset*2
        local bh = bounds.h - textOffset*2
        local text = chatbox.text
        local spaceWidth = renderGetTextSize(" ")
        --<:[^:]+:([0-9]+)>
        --while #wrapQueue ~= 0 do
        if #wrapQueue ~= 0 then
            local t = table.remove(wrapQueue, 1)
            local h = verticalSpacing
            local new = {timer.curtime(), {{h, 0, {}}}}
            local lines = new[2]
            local curline = lines[1]
            local pieces = curline[3]
            local x = 0
            local setHeight = false
            local lastColor = Color(255, 255, 255)
            local appendWhenDone = false
            for _, piece in ipairs(t) do
                if type(piece) == "Color" then
                    --Add color and new segment
                    tableInsert(pieces, {x, piece, ""})
                    lastColor = piece
                else
                    --Add and wrap text
                    local fromEmoji = false
                    local lineBreaks = stringExplode("\n", piece)
                    for i = 1, #lineBreaks do
                        if i ~= 1 then
                            x = 0
                            tableInsert(lines, {h, 0, {{x, Color(lastColor[1], lastColor[2], lastColor[3], lastColor[4]), ""}}})
                            curline = lines[#lines]
                            pieces = curline[3]
                        end
                        fromEmoji = false
                        local str = ""
                        local first = true
                        local first2 = true
                        local spaceWidthAdd2 = 0
                        local second = true
                        local spaceWidthAdd = 0
                        local width = 0
                        local function wrap(strPiece)
                            --[[if fromEmoji then
                                fromEmoji = false
                                spaceWidthAdd = 0
                            end]]
                            h = math.max(verticalSpacing, h)
                            first2 = false
                            spaceWidthAdd2 = 0
                            appendWhenDone = true
                            width = renderGetTextSize(strPiece)
                            if x + width > bw then
                                if x == 0 then
                                    --Force it to stay on this line
                                    if first or fromEmoji then
                                        str = str .. strPiece
                                        x = x + width
                                    else
                                        str = str .. " " .. strPiece
                                        x = x + spaceWidth + width
                                    end
                                else
                                    --Move down a line
                                    pieces[#pieces][3] = str .. ""
                                    str = strPiece
                                    curline[1] = h
                                    curline[2] = x
                                    h = verticalSpacing
                                    x = width
                                    tableInsert(lines, {h, width, {{0, Color(lastColor[1], lastColor[2], lastColor[3], lastColor[4]), strPiece}}})
                                    curline = lines[#lines]
                                    pieces = curline[3]
                                    first = true
                                end
                            else
                                --Add to current line
                                if first or fromEmoji then
                                    str = str .. strPiece
                                    x = x + width
                                else
                                    str = str .. " " .. strPiece
                                    x = x + spaceWidth + width
                                end
                            end
                            fromEmoji = false
                            if first then
                                spaceWidthAdd = 0
                                second = true
                                first = false
                            else
                                spaceWidthAdd = spaceWidth
                                second = false
                            end
                        end
                        
                        for _, strPiece in ipairs(stringExplode(" ", lineBreaks[i])) do
                            --Embed images
                            first2 = true
                            --first2 = first
                            spaceWidthAdd2 = (first and 0 or spaceWidth)
                            --spaceWidthAdd2 = spaceWidthAdd
                            fromEmoji = false
                            --https://cdn.discordapp.com/attachments/642904079663890432/855177356889161778/unknown.png
                            if (string.startWith(strPiece, "https://") or string.startWith(strPiece, "http://")) and not string.find(strPiece, " ", 1, true) and (
                                string.find(strPiece, ".png", 1, true) or
                                string.find(strPiece, ".PNG", 1, true) or
                                string.find(strPiece, ".jpg", 1, true) or
                                string.find(strPiece, ".jpeg", 1, true) or
                                string.find(strPiece, ".JPG", 1, true) or
                                string.find(strPiece, ".JPEG", 1, true)
                            ) then
                                --Image
                                --local ready = false
                                local skip = false
                                local myMat = {x, nil, 0, 0, 1, 1}
                                --local myline = {h, width, {myMat}}
                                local myline = {0, 0, {myMat}}
                                myMat[2] = getMat(strPiece, function()
                                    --Fail
                                    myMat[2] = nil
                                    myMat[5] = 0
                                    myMat[6] = 0
                                    --ready = true
                                    skip = true
                                end, function(width, height)
                                    --Success
                                    local ratio
                                    if width > maxImageSize[1] or height > maxImageSize[2] then
                                        ratio = math.min(maxImageSize[1] / width, maxImageSize[2] / height)
                                    else
                                        ratio = 1
                                    end
                                    local newWidth = width * ratio
                                    local newHeight = height * ratio
                                    myMat[3] = newWidth * 1024 / width
                                    myMat[4] = newHeight * 1024 / height
                                    myMat[5] = newWidth
                                    myMat[6] = newHeight
                                    myline[1] = newHeight
                                    myline[2] = newWidth
                                    --ready = true
                                end, false)
                                --while not ready do coroutine.yield() end
                                if not skip then
                                    pieces[#pieces][3] = str .. ""
                                    str = ""
                                    myMat[1] = x + spaceWidthAdd2
                                    curline[1] = h
                                    curline[2] = x
                                    --h = math.max(verticalSpacing, myMat[6])
                                    h = 0
                                    x = myMat[5]
                                    myMat[1] = 0
                                    tableInsert(lines, myline)
                                    fromEmoji = true
                                    curline = lines[#lines]
                                    pieces = curline[3]
                                    spaceWidthAdd2 = 0
                                    first2 = false
                                    
                                    tableInsert(pieces, {x, Color(lastColor[1], lastColor[2], lastColor[3], lastColor[4]), ""})
                                    continue
                                end
                            end
                            
                            
                            
                            --Find discord emojis
                            --local discordEmojiPlainTextIndex = string.find(strPiece, "<:[^:]+:([0-9]+)>")
                            local matches = {}
                            --local starts = {}
                            local stops = {}
                            local i = 1
                            for hit, a in string.gmatch(strPiece, "<:[^:]+:([0-9]+)>") do
                                tableInsert(matches, hit)
                                --i = string.find(strPiece, "<", i, true)
                                --tableInsert(starts, i)
                                i = string.find(strPiece, hit .. ">", i, true) + #hit
                                tableInsert(stops, i)
                            end
                            if #stops ~= 0 then
                                stops[#stops] = #strPiece
                            end
                            local stop1 = 0
                            i = 1
                            --if discordEmojiPlainTextIndex then
                            --if #matches ~= 0 then
                            --local spaceWidth2 = spaceWidthAdd
                            --local first2 = first
                            for i = 1, #matches do
                                local start1 = stop1 + 1
                                stop1 = stops[i]
                                local strPiece = string.sub(strPiece, start1, stop1)
                                --local start = string.find(strPiece, ":", discordEmojiPlainTextIndex+2, true) + 1
                                local start2 = string.find(strPiece, "<", 1, true)
                                local start = string.find(strPiece, ":", start2+2, true) + 1
                                local stop = string.find(strPiece, ">", start+1, true) - 1
                                --local start = starts[i]
                                --local stop = stop1
                                appendWhenDone = false
                                if start < stop then
                                    discordEmojiURL = "https://cdn.discordapp.com/emojis/" .. string.sub(strPiece, start, stop) .. "?v=1"
                                    --discordEmojiURL = "https://cdn.discordapp.com/emojis/" .. matches[i] .. "?v=1"
                                    local myMat = {x, nil, 0, 0, emojiSize, emojiSize}
                                    local ready = false
                                    local skip = false
                                    myMat[2] = getMat(discordEmojiURL, function()
                                        --Fail
                                        myMat[2] = nil
                                        myMat[5] = 0
                                        myMat[6] = 0
                                        ready = true
                                        skip = true
                                    end, function(width, height)
                                        --Success
                                        local ratio = math.min(emojiSize / width, emojiSize / height)
                                        local newWidth = width * ratio
                                        local newHeight = height * ratio
                                        myMat[3] = newWidth * 1024 / width
                                        myMat[4] = newHeight * 1024 / height
                                        myMat[5] = newWidth
                                        myMat[6] = newHeight
                                        ready = true
                                    end)
                                    while not ready do coroutine.yield() end
                                    if skip then
                                        wrap(strPiece)
                                        continue
                                    end
                                    if start2 ~= 1 then
                                        first2 = false
                                        spaceWidth2 = 0
                                        --Wrap pre text
                                        --wrap(string.sub(strPiece, 1, discordEmojiPlainTextIndex-1))
                                        wrap(string.sub(strPiece, 1, start2-1))
                                        --myMat[1] = x
                                    end
                                    pieces[#pieces][3] = str .. ""
                                    str = ""
                                    myMat[1] = x + spaceWidthAdd2
                                    if x + spaceWidthAdd2 + myMat[5] > bw and x ~= 0 then
                                        --Go down a line
                                        curline[1] = h
                                        curline[2] = x
                                        h = math.max(verticalSpacing, myMat[6])
                                        x = myMat[5]
                                        myMat[1] = 0
                                        tableInsert(lines, {h, width, {myMat}})
                                        fromEmoji = true
                                        curline = lines[#lines]
                                        pieces = curline[3]
                                    else
                                        --Stay on this line
                                        x = x + myMat[5] + spaceWidthAdd2
                                        h = math.max(verticalSpacing, myMat[6])
                                        tableInsert(pieces, myMat)
                                        fromEmoji = true
                                        --first = true
                                    end
                                    spaceWidthAdd2 = 0
                                    first2 = false
                                    
                                    tableInsert(pieces, {x, Color(lastColor[1], lastColor[2], lastColor[3], lastColor[4]), ""})
                                    if stop+1 ~= #strPiece then
                                        --Wrap post text
                                        --print(string.sub(strPiece, stop+2))
                                        wrap(string.sub(strPiece, stop+2))
                                    end
                                else
                                    wrap(strPiece)
                                end
                            end
                            if #matches == 0 then
                                wrap(strPiece)
                            end
                        end
                        --Add to current line
                        if appendWhenDone then
                            try(function()
                                pieces[#pieces][3] = str .. ""
                            end)
                        end
                        curline[1] = h
                        curline[2] = x
                    end
                end
            end
            table.insert(text, new)
        end
    end)
    
    local renderDrawSimpleText = render.drawSimpleText
    local renderSetColor = render.setColor
    local renderSetRGBA = render.setRGBA
    local font
    hook.add("drawhud", "", function()
        if init then
            init = false
            width, height = render.getGameResolution()
            --border = math.round(border * width)
            border = 1
            textOffset = math.round(textOffset * height)
            emojiSize = math.round(emojiSize * height)
            fontSize = math.round(fontSize * height)
            verticalSpacing = math.round(fontSize*1.1)
            --font = render.createFont("Roboto", fontSize, nil, true)
            --font = render.createFont("DejaVu Sans Mono", fontSize, nil, true)
            font = render.createFont("Coolvetica", fontSize, 575, true)
            --font = render.createFont("Trebuchet", fontSize, 575, true, nil, true)
            --font = render.createFont("ChatFont", fontSize, 600, true, nil, nil)
            render.setFont(font)
            
            function scaleChatbox(tbl)
                for key, val in pairs(tbl) do
                    if type(val) == "table" then
                        scaleChatbox(val)
                    else
                        if key == "x" then
                            tbl.x = math.round(tbl.x * width)
                        elseif key == "w" then
                            tbl.w = math.round(tbl.w * width)
                        elseif key == "y" then
                            tbl.y = math.round(tbl.y * height)
                        elseif key == "h" then
                            tbl.h = math.round(tbl.h * height)
                        end
                    end
                end
            end
            
            chatbox.musicPlayer.w = chatbox.musicPlayer.w / width * height
            scaleChatbox(chatbox)
            local bounds = chatbox.min.bounds
            local set = chatbox.min.chat
            set.x = bounds.x + border
            set.y = bounds.y + border
            set.w = bounds.w - 2*border
            set.h = bounds.h - 2*border
            
            maxImageSize[1] = (set.w - textOffset*2) * maxImageSize[1]
            maxImageSize[2] = (set.h - textOffset*2) * maxImageSize[2]
            
            --[[set = chatbox.min.say
            set.x = bounds.x + border
            set.y = bounds.y + bounds.h - border - math.round(fontSize * 1.5) - 1
            set.w = bounds.w - 2*border
            set.h = math.round(fontSize * 1.5)]]
        end
        render.setFont(font)
        wrapText()
        --[[render.drawRect(chatbox.min.bounds.x, chatbox.min.bounds.y, chatbox.min.bounds.w, chatbox.min.bounds.h)
        render.setRGBA(0,0,0,255)
        render.drawRect(chatbox.min.chat.x, chatbox.min.chat.y, chatbox.min.chat.w, chatbox.min.chat.h)]]
        --render.drawRect(chatbox.min.say.x, chatbox.min.say.y, chatbox.min.say.w, chatbox.min.say.h)
        
        
        --render.setRGBA(255,255,255,255)
        --[[render.setRGBA(100, 100, 100, 150)
        render.drawRectOutline(chatbox.min.bounds.x, chatbox.min.bounds.y, chatbox.min.bounds.w, chatbox.min.bounds.h)
        render.setRGBA(0, 0, 0, 100)
        render.drawRect(chatbox.min.bounds.x, chatbox.min.bounds.y, chatbox.min.bounds.w, chatbox.min.bounds.h)]]
        
        
        --render.setRGBA(255, 255, 255, 255)
        --render.drawRect(chatbox.min.bounds.x+textOffset, chatbox.min.bounds.y+textOffset, chatbox.min.bounds.w-textOffset*2, chatbox.min.bounds.h-textOffset*2)
        
        --table.insert(text, {Color(255, 255, 255), "Hello,"})
        --table.insert(text, {Color(255, 0, 0), "World!"})
        
        --Render text
        local y = chatbox.min.bounds.y + chatbox.min.bounds.h
        local vertSpacing = fontSize
        local x = chatbox.min.bounds.x + textOffset
        local black = Color(0,0,0)
        local miny = chatbox.min.bounds.y
        --printTable(chatbox.text)
        --for _, message in ipairs(chatbox.text) do
        local time = timer.curtime()
        local text = chatbox.text
        --Find bounds
        local mmin = math.min
        local mmax = math.max
        local dynBounds = {{x, y}, {x, y}}
        local i1, i2, i3 = #text, 1, 1
        local persist = not game.hasFocus() or chatOpen
        while i1 >= 1 do
            local message = text[i1]
            if persist then
                message[1] = time
            else
                if time - message[1] >= fadeStart + fadeTime then
                    table.remove(text, i1)
                    i1 = i1 - 1
                    continue
                end
            end
            local message2 = message[2]
            i2 = #message2
            while i2 >= 1 do
                local line = message2[i2]
                local lineHeight = line[1]
                local lineWidth = line[2]
                y = y - lineHeight
                if y < miny then
                    table.remove(message2, i2)
                    i2 = i2 - 1
                    continue
                end
                dynBounds[1][1] = mmin(dynBounds[1][1], x + lineWidth)
                dynBounds[1][2] = mmin(dynBounds[1][2], y)
                dynBounds[2][1] = mmax(dynBounds[2][1], x + lineWidth)
                dynBounds[2][2] = mmax(dynBounds[2][2], y)
                i2 = i2 - 1
            end
            if #message2 == 0 then
                table.remove(text, i1)
                i1 = i1 - 1
                continue
            end
            i1 = i1 - 1
        end
        
        chatbox.bounds.x = dynBounds[1][1] - textOffset
        chatbox.bounds.y = dynBounds[1][2] - textOffset
        chatbox.bounds.w = dynBounds[2][1] - dynBounds[1][1] - textOffset*2 + 1
        chatbox.bounds.h = dynBounds[2][2] - dynBounds[1][2] - textOffset*2 + 1
        
        if dynBounds[1][1] ~= dynBounds[2][1] or dynBounds[1][2] ~= dynBounds[2][2] then
            local w, h = dynBounds[2][1] - dynBounds[1][1] + 1 + textOffset*2, dynBounds[2][2] - dynBounds[1][2] + 1 + textOffset*2
            local x, y = dynBounds[1][1] - textOffset, dynBounds[1][2] - textOffset
            if chatOpen then
                x = x + 1
                y = math.max(y - chatbox.min.bounds.y - chatbox.min.bounds.h + chatbox.native.y - textOffset - 1, chatbox.min.bounds.y)
                h = chatbox.native.y - y
            end
                
            render.setRGBA(100, 100, 100, 150)
            render.drawRectOutline(x-1, y-1, w+2, h+2)
            render.setRGBA(0, 0, 0, 100)
            render.drawRect(x, y, w, h)
        end
        
        if chatOpen then
            y = chatbox.native.y - textOffset - 2
        else
            y = chatbox.min.bounds.y + chatbox.min.bounds.h
        end
        local miny = chatbox.min.bounds.y
        --Draw text
        for i1 = #text, 1, -1 do
            local message = text[i1]
            local messageTime = message[1]
            local dt = time - messageTime
            local messageAlpha
            local black = black
            if dt <= fadeStart then
                messageAlpha = 1
            else
                messageAlpha = math.clamp(1 - (dt - fadeStart) / fadeTime, 0, 1)
                black = Color(0, 0, 0, 255 * messageAlpha)
            end
            local message2 = message[2]
            i2 = #message2
            for i2 = #message2, 1, -1 do
                local line = message2[i2]
                local lineHeight = line[1]
                local lineWidth = line[2]
                y = y - lineHeight
                if y < miny then
                    break
                end
                for _, piece in ipairs(line[3]) do
                    if piece[2] then
                        if type(piece[2]) == "Color" then
                            --Text
                            renderSetColor(black)
                            renderDrawSimpleText(piece[1]+x+1, y+1, piece[3], 0, 0)
                            if messageAlpha == 1 then
                                try(function()
                                    renderSetColor(piece[2])
                                end)
                            else
                                try(function()
                                    renderSetRGBA(piece[2][1], piece[2][2], piece[2][3], piece[2][4] * messageAlpha)
                                end)
                            end
                            try(function()
                                renderDrawSimpleText(piece[1]+x, y, piece[3], 0, 0)
                            end)
                        else
                            --Material
                            try(function()
                                renderSetRGBA(255, 255, 255, 255*messageAlpha)
                                render.setMaterial(piece[2])
                                render.drawTexturedRect(piece[1]+x, y, piece[3], piece[4])
                            end)
                            --render.drawRect(piece[1]+x, y, piece[5], piece[6])
                        end
                    end
                end
            end
        end
    end)
    
    local first = true
    hook.add("ChatAddText", "", function(...)
        addText(...)
    end)

--[[hook.add("ChatTextChanged", "", function(txt)
    print("Changed")
    print(txt)
end)]]
    enableHud(owner(), true)
end