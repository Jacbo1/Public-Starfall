--@name FFT Screen
--@author Jacbo
--@client

if player() ~= owner() then return end

--Lemon Demon
--local urls = {"https://cdn.discordapp.com/attachments/607371740540305424/851518714120503336/Ancient_Aliens.mp3", 
--Adoring Fan - Star.mp3
local fps = 60
--local max = 0.125
local max = 0.1
--local samples = 5.321928095
--local samples = math.floor(math.log(1024 / max / 256,2))+1
local samples = 6
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
local interval = 256 * 2^samples * max / count

local colorShift = 0
local oldTime = timer.curtime()
local colorInterval = 360 / count

render.createRenderTarget("screen")
--bass.loadURL( "https://play.sas-media.ru/play_256", "3d noblock", function(Sound)
--bass.loadURL( "https://skspoof.000webhostapp.com/Audio/17%20Burning%20Sunset.mp3", "3d noblock", function(Sound)
--bass.loadURL( "https://www.dropbox.com/s/vq9ihz9t62bzilo/Bohemian%20Rhapsody.mp3?dl=1", "3d noblock", function(Sound)
--bass.loadURL( "https://www.dropbox.com/s/xbnr3hwe133bkjs/WALKIN%27%20-%20JerryTerry.mp3?dl=1", "3d noblock", function(Sound)
--bass.loadURL( "https://www.dropbox.com/s/69qaxty4qv1p3kr/Dancin.mp3?dl=1", "3d noblock", function(Sound)
--bass.loadFile( "music/Adoring Fan - Star.mp3", "3d noblock", function(Sound)
--bass.loadURL( "https://www.dropbox.com/s/ewstmtg3bamwt8p/untitled.mp3?dl=1", "3d noblock", function(Sound)
--bass.loadURL( "https://www.dropbox.com/s/sfyr7xwe4dm3ysp/aaaaaaaaaaaaaaaaaaaa.mp3?dl=1", "3d noblock", function(Sound)
--bass.loadURL( "https://www.dropbox.com/s/tkksfzk3nim8mlb/dinosaur.mp3?dl=1", "3d noblock", function(Sound)
--bass.loadURL( "https://www.dropbox.com/s/ga3816zqx8uq26u/big%20iron.mp3?dl=1", "3d noblock", function(Sound)
--bass.loadURL( "https://www.soundboard.com/handler/DownLoadTrack.ashx?cliptitle=Never+Gonna+Give+You+Up-+Original&filename=mz/Mzg1ODMxNTIzMzg1ODM3_JzthsfvUY24.MP3", "3d noblock", function(Sound)
bass.loadURL( "https://dl.dropboxusercontent.com/s/vq9ihz9t62bzilo/Bohemian%20Rhapsody.mp3", "3d noblock", function(Sound)
    print("Sound loaded")
    if Sound then
        Sound:play()
    end
    hook.add("renderoffscreen","",function()
        --render.setColor(Color(188,1,(fft[5] or 0)*10):hsvToRGB())
        --render.draw3DBox(Vector(0,512,0),Angle(),Vector(),Vector(512*2))
        if Sound then
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
                --print(#fft)
                table.insert(volumeHistory, 1023 - math.max(Sound:getLevels()) * 1024)
                local hcount = #volumeHistory
                if hcount > volumeHistorySize then
                    table.remove(volumeHistory,1)
                    hcount = #volumeHistory
                end
                --render.setRGBA(128,128,128,255)
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
                render.setColor(Color(colorShift,1,1):hsvToRGB())
                local last = 1
                for i = 1, count do
                    local next = math.round(i * interval)
                    local fftVal = fft[i]*volumeMult
                    --[[for i2 = last, next, 1 do
                        fftVal = math.max(fftVal,(fft[i2] or 0))
                    end]]
                    last = next+1
                    --render.draw3DBox(Vector(0,512,0),Angle(),Vector(),Vector(512*2))
                    --render.setColor(Color(fftVal*360, 1, 1):hsvToRGB())
                    --render.setColor(Color((colorShift + i * colorInterval)%360, 1, 1):hsvToRGB())
                    render.drawLine(i,1023,i,1023-1023*fftVal)
                    --render.draw3DBox(Vector(-50,x,y),Angle(),Vector(),Vector(1,1,fftVal*1024))
                    --top:setPos(bottom:localToWorld(Vector(halfSize + halfSize * math.cos(angr) + math.cos(angr + math.pi/2) * halfSize, 0, size*3/4 + halfSize * math.sin(angr) + math.sin(angr + math.pi/2) * size/4)))
                end
            else
                --hook.remove("think","")
            end
        end
    end)
    hook.add("render","",function()
        render.setRenderTargetTexture("screen")
        render.drawTexturedRect(0,0,512,512)
    end)
end)