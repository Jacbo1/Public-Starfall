--@name FFT Screen 2
--@author Jacbo
--@shared
--@include funcs.txt

require("funcs.txt")
if SERVER then
    funcs.linkToClosestScreen()
elseif player() == owner() then
    local cutoff = 0.05
    local fps = 60
local max = 0.125
--local max = 0.1
--local max = 0.05
--local max = 0.0025
--local samples = 5.321928095
--local samples = math.floor(math.log(1024 / max / 256,2))+1
--local samples = math.floor(math.log(1024 / max / 128,2)+1)
local samples = 6
--print(samples, "", 2^samples*128)
--local samples = 6
--local samples = 32
--print(samples)
local count = 1024
local size = 2
local volumeHistorySize = 100
local colorShiftSpeed = 75
local volumeMult = 10

local volumeHistory = {}
local chip = chip()
local rowSpacing = 10
local perRow = math.ceil(1024/size)
local rowCount = math.ceil(count/perRow)
local lastRowCount = count - (rowCount-1) * perRow
local nextFrameTime = timer.curtime()
--local interval = 256 * 2^samples * max / count
local interval = 128 * 2^samples * max / count
--local interval = 512 * max / count
--print(count * interval)

local colorShift = 0
local oldTime = timer.curtime()
local colorInterval = 360 / count

local trails = {}
local i512 = 1/512

render.createRenderTarget("screen")
--bass.loadURL( "https://play.sas-media.ru/play_256", "3d noblock", function(Sound)
--bass.loadURL( "https://skspoof.000webhostapp.com/Audio/17%20Burning%20Sunset.mp3", "3d noblock", function(Sound)
bass.loadURL( "https://www.dropbox.com/s/vq9ihz9t62bzilo/Bohemian%20Rhapsody.mp3?dl=1", "3d noblock", function(Sound)
--bass.loadURL( "https://www.dropbox.com/s/xbnr3hwe133bkjs/WALKIN%27%20-%20JerryTerry.mp3?dl=1", "3d noblock", function(Sound)
--bass.loadURL( "https://www.dropbox.com/s/69qaxty4qv1p3kr/Dancin.mp3?dl=1", "3d noblock", function(Sound)
--bass.loadURL( "https://www.dropbox.com/s/ewstmtg3bamwt8p/untitled.mp3?dl=1", "3d noblock", function(Sound)
--bass.loadURL( "https://www.dropbox.com/s/sfyr7xwe4dm3ysp/aaaaaaaaaaaaaaaaaaaa.mp3?dl=1", "3d noblock", function(Sound)
--bass.loadURL( "https://www.dropbox.com/s/tkksfzk3nim8mlb/dinosaur.mp3?dl=1", "3d noblock", function(Sound)
--bass.loadURL( "https://www.dropbox.com/s/ga3816zqx8uq26u/big%20iron.mp3?dl=1", "3d noblock", function(Sound)
--bass.loadURL( "https://www.soundboard.com/handler/DownLoadTrack.ashx?cliptitle=Never+Gonna+Give+You+Up-+Original&filename=mz/Mzg1ODMxNTIzMzg1ODM3_JzthsfvUY24.MP3", "3d noblock", function(Sound)
--bass.loadURL( "https://cdn.discordapp.com/attachments/607371740540305424/851557390856093696/The_Last_Stand_-_SABATON.mp3", "3d noblock", function(Sound)
--bass.loadURL( "https://cdn.discordapp.com/attachments/607371740540305424/851560693215658054/The_Red_Baron_-_SABATON.mp3", "3d noblock", function(Sound)
--bass.loadURL( "https://cdn.discordapp.com/attachments/607371740540305424/851565404098527322/Amore.mp3", "3d noblock", function(Sound)
    print("Sound loaded")
    if Sound then
        Sound:play()
    end
    local tick = 0
    local volFade = 0
    local volFadeMax = 0
    local volFadeSpeedDown = 500
    local volFadeSpeedUp = 2000
    hook.add("renderoffscreen","",function()
        --render.setColor(Color(188,1,(fft[5] or 0)*10):hsvToRGB())
        --render.draw3DBox(Vector(0,512,0),Angle(),Vector(),Vector(512*2))
        if Sound then
            tick = tick + 1
            render.selectRenderTarget("screen")
            render.clear()
            
            Sound:setPos(chip:getPos())
            local time = timer.curtime()
            if time > nextFrameTime then
                local timeElapsed = time - oldTime
                oldTime = time
                colorShift = (colorShift + timeElapsed * colorShiftSpeed)%360
                nextFrameTime = nextFrameTime + 1/fps
                fft = Sound:getFFT(samples)
                local vol = 1023 - math.max(Sound:getLevels()) * 1024
                if vol <= volFadeMax then
                    volFadeMax = vol
                else
                    volFadeMax = volFadeMax + math.min(vol - volFadeMax, volFadeSpeedDown * timer.frametime())
                end
                volFade = volFade + math.clamp(volFadeMax - volFade, -volFadeSpeedUp * timer.frametime(), volFadeSpeedDown * timer.frametime())
                render.setColor(Color(540 - colorShift,1,0.25):hsvToRGB())
                render.drawRect(0, volFade, 1024, 1024-volFade)
                
                table.insert(volumeHistory, vol)
                local hcount = #volumeHistory
                if hcount > volumeHistorySize then
                    table.remove(volumeHistory,1)
                    hcount = #volumeHistory
                end
                render.setColor(Color(360 - colorShift,1,0.25):hsvToRGB())
                if hcount > 1 then
                    local xinterval = 1024 / (hcount-1)
                    local x = 0
                    for i = 1, hcount-1 do
                        --render.drawLine(x, volumeHistory[i], x + xinterval, volumeHistory[i+1])
                        render.drawPoly({
                            {x = x, y = 1023},
                            {x = x, y = volumeHistory[i]},
                            {x = x + xinterval, y = volumeHistory[i+1]},
                            {x = x + xinterval, y = 1023}
                        })
                        x = x + xinterval
                    end
                end
                --render.setColor(Color(colorShift,1,1):hsvToRGB())
                local color = Color(colorShift,1,1):hsvToRGB()
                
                local last = 0
                for i = 1, count do
                    local next = math.round(i * interval)
                    if next == last then continue end
                    last = next
                    --print(next, "", #fft)
                    --print(i, "", next, "", #fft)
                    --local fftVal = fft[i]*volumeMult
                    local fftVal = fft[next]*volumeMult
                    --last = next+1
                    if fftVal >= cutoff then
                        local trail = trails[i]
                        if not trail then
                            trails[i] = {}
                            trail = trails[i]
                        end
                        if #trail == 0 then
                            table.insert(trail, {tick, {{i, 1023, color}}})
                        elseif trail[#trail][1] == tick - 1 then
                            trail[#trail][1] = tick
                            table.insert(trail[#trail][2], {i, 1023, color})
                        else
                            table.insert(trail, {tick, {{i, 1023, color}}})
                        end
                        --[[local trail = trails[i]
                        if not trail then
                            trails[i] = {}
                            trail = trails[i]
                        end
                        if #trail == 0 then
                            table.insert(trail, {tick, tick, {i, 1023}, {}, {color}})
                        elseif trail[#trail][2] == tick - 1 then
                            trail[#trail][2] = tick
                            table.insert(trail[#trail][5], 1, color)
                        else
                            table.insert(trail, {tick, tick, {i, 1023}, {}, {color}})
                        end]]
                    end
                end
            else
                --hook.remove("think","")
            end
        end
        
        --Draw trails
        local setColor = render.setColor
        setColor(Color(255,255,255))
        local drawLine = render.drawLine
        for _, trail in pairs(trails) do
            local groupi = 1
            while groupi <= #trail do
                --Draw
                local group = trail[groupi][2]
                local b = false
                if #group ~= 1 then
                    b = true
                    local nextpoint, point
                    local x, y, nextx, nexty
                    for i = 1, #group - 1 do
                        if nextpoint then
                            setColor(nextpoint[3])
                            x = nextx
                            y = nexty
                        else
                            point = group[i]
                            setColor(point[3])
                            x = point[1]
                            y = point[2]
                        end
                        nextpoint = group[i+1]
                        nextx = nextpoint[1]
                        nexty = nextpoint[2]
                        drawLine(x, y, nextx, nexty)
                        group[i][1] = x - 30 * (x*i512-1)
                        local y1 = (y*i512-1)
                        group[i][2] = y -8 * y1 * y1 - 20
                    end
                end
                local i = #group
                local x = group[i][1]
                local y = group[i][2]
                group[i][1] = x - 30 * (x*i512-1)
                local y1 = (y*i512-1)
                group[i][2] = y -8 * y1 * y1 - 20
                --640
                while #group ~= 0 and group[#group][2] <= 0 do
                    table.remove(group)
                end
                if b and #group == 1 then
                    table.remove(group)
                end
                if #group == 0 then
                    table.remove(trail, groupi)
                else
                    groupi = groupi + 1
                end
                --[[local group = trail[groupi]
                local head = group[3]
                local points = group[4]
                local colors = group[5]
                local tickStart = group[1]
                local tickStop = group[2]
                if #head ~= 0 then
                    --Head exist
                    local x = head[1]
                    local y = head[2]
                    table.insert(points, {x, y})
                    if y > 0 then
                        --Move head
                        head[1] = x - 30*(x*i512-1)
                        local y1 = (y*i512-1)
                        head[2] = y - 8*y1*y1 - 20
                    else
                        --Delete head
                        head = {}
                    end
                else
                    --No head
                    table.remove(colors)
                end
                if tickStop ~= tick then
                    table.remove(points, 1)
                    if #points == 0 then
                        table.remove(trail, groupi)
                        continue
                    end
                end
                
                local b = false
                if #points ~= 1 then
                    --Draw trail
                    b = true
                    local nextpoint = points[1]
                    local x, y
                    local nextx, nexty = nextpoint[1], nextpoint[2]
                    for i = 1, #points - 1 do
                        x = nextx
                        y = nexty
                        setColor(colors[i])
                        nextpoint = points[i+1]
                        nextx = nextpoint[1]
                        nexty = nextpoint[2]
                        drawLine(x, y, nextx, nexty)
                    end
                end
                groupi = groupi + 1]]
            end
        end
    end)
    hook.add("render","",function()
        render.setRenderTargetTexture("screen")
        render.drawTexturedRect(0,0,512,512)
    end)
end)
end