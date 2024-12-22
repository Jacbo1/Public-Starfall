-- Basic ray tracer with results comparable to gmod's graphics except specular reflections are actual reflections and water has refraction.
-- Requires Vistrace https://github.com/Derpius/VisTrace
-- This is more here for anyone who wants to look at code for making their own tracer.
--    FYI you won't find texture sampling code in here as that's handled by Vistrace.
-- This probably should have been split into multiple files but whatever I wasn't planning on releasing it when I wrote it.

--@name Vistracer
--@author Jacbo
--@shared
--@include safeNet.txt
--@include json_lib.txt
--@include funcs.txt
--@include chatcmd.txt

-- !sunColor 0.92156862745098 0.9843137254902 1
-- skydir1

local onlyFindOwnerProps = true

local fileAppendSize = 4000
local findOwnerOnly = false

local startTime

local math_lerp = math.lerp
local math_lerpVector = math.lerpVector
local math_clamp = math.clamp
local math_max = math.max
local math_min = math.min
local math_floor = math.floor
local math_ceil = math.ceil
local math_log = math.log
local math_abs = math.abs
local math_atan2 = math.atan2
local math_pi = math.pi
local math_sqrt = math.sqrt
local math_round = math.round
local string_replace = string.replace
local string_find = string.find
local string_reverse = string.reverse
local string_sub = string.sub
local string_char = string.char
local string_byte = string.byte
local material_getInt, material_getVector, material_getTexture, material_getFloat, material_getString
local file_read, file_write, file_append, file_delete
if CLIENT then
    material_getInt = material.getInt
    material_getVector = material.getVector
    material_getTexture = material.getTexture
    material_getFloat = material.getFloat
    material_getString = material.getString
    file_read = file.read
    file_write = file.write
    file_append = file.append
    file_delete = file.delete
end
local table_insert = table.insert
local table_remove = table.remove
local bit_band = bit.band
local bit_rshift = bit.rshift
local bit_lshift = bit.lshift

require("chatcmd.txt")
require("funcs.txt")
local json = require("json_lib.txt")
json.setMaxQuota(math_min(0.002, quotaMax() * 0.75))
require("safeNet.txt")
local net = safeNet
--lua_run_cl require("VisTrace")

--local lightDistMult = 0.0357
local lightLog = 1.059

if SERVER then
    funcs.linkToClosestScreen()
    local blacklist = {}
    local using = {}
    
    local data = {}
    local isReceiving = false
    local isSending = false
    --isSending
    
    net.receive("blacklist", function(_, ply)
        local players = find.allPlayers()
        json.decode(net.readString(), function(t)
            for v, k in pairs(t) do
                blacklist[k] = true
                local enabled = true
                for i, j in pairs(players) do
                    if j:getSteamID() == k then
                        enabled = false
                        net.start("enabled")
                        net.writeBool(false)
                        net.send(j)
                        table_remove(players, i)
                        break
                    end
                end
            end
            for v, k in pairs(players) do
                net.start("enabled")
                net.writeBool(true)
                net.send(k)
            end
        end)
    end)
    
    hook.add("ComponentLinked", "", function(screen)
        hook.add("KeyPress", tostring(screen), function(ply, key)
            if ply ~= owner() then
                local id = ply:getSteamID()
                if key == 32 and not using[id] then
                    using[id] = true
                    local eyeTrace = ply:getEyeTrace()
                    if eyeTrace.Entity == screen and eyeTrace.StartPos:getDistance(eyeTrace.HitPos) <= 90 then
                        if blacklist[id] == nil then
                            blacklist[id] = true
                            net.start("blacklist")
                            net.writeString(id)
                            net.writeBool(true)
                            net.send(owner())
                            net.start("enabled")
                            net.writeBool(false)
                            net.send(ply)
                        else
                            blacklist[id] = nil
                            net.start("blacklist")
                            net.writeString(ply:getSteamID())
                            net.writeBool(false)
                            net.send(owner())
                            net.start("enabled")
                            net.writeBool(true)
                            net.send(ply)
                        end
                    end
                end
            end
        end)
        hook.add("KeyRelease", tostring(screen), function(ply, key)
            if ply ~= owner() then
                local id = ply:getSteamID()
                if key == 32 and using[id] then
                    using[id] = false
                end
            end
        end)
    end)
    
    local lines = {}
    local lineLengths = {}
    
    local function isFinished()
        local sending = net.isSending()
        if sending ~= isSending then
            isSending = sending
            if not isSending and not isReceiving and lines[1] then
                print("Finished streaming")
            end
        end
    end
    hook.add("think", "check sending", isFinished)
    
    net.receive("status", function(_, ply)
        isReceiving = net.readBool()
        if isReceiving then
            lines = {}
        elseif not isSending and not net.isSending() and lines[1] then
            print("Finished streaming")
        end
    end)
    
    net.receive("spawned", function(_, ply)
        local enabled = blacklist[ply:getSteamID()] ~= nil
        net.start("enabled")
        net.writeBool(enabled)
        net.send(ply)
        if enabled then
            for i = 1, #lines do
                net.start("line")
                net.writeData(lines[i], lineLengths[i])
                net.send(ply, true)
            end
            isSending = true
        end
    end)
    
    net.receive("line", function(size)
        table_insert(lines, line)
        table_insert(lineLengths, size)
        net.start("line")
        net.writeData(net.readData(size), size)
        net.send(nil, true)
        isSending = true
    end)
    
    local lightCutoff = 5
   --wire.adjustInputs({"RGB", "Brightness", "Size", "IsLight"}, {"Vector", "Number", "Number", "Number"})
    net.receive("find lights", function()
        local e2s = find.byClass("gmod_wire_expression2", function(ent)
            return ent:getOwner() == owner()
        end)
        local lights = {}
        for _, e2 in ipairs(e2s) do
            local wirelink = wire.getWirelink(e2)
            if wirelink.IsLight == 1234 then
                local rgb = wirelink.RGB
                local brightness = wirelink.Brightness
                local size = wirelink.Size
                if rgb and brightness and size then
                    --local radiusSqr = (math_sqrt(255 * brightness / lightCutoff) / lightDistMult)^2
                    --local radiusSqr = (lightLog ^ size)^2
                    --local radiusSqr = (lightLog ^ math_log(size, 2))^2
                    --{rgb, bright, radius, radius^2, pos, ent}
                    --table_insert(lights, {rgb, brightness, math_log(size, lightLog), math_log(size, lightLog)^2, e2:getPos(), e2})
                    --{rgb, brightness, radiusSqr, pos, ent}
                    --table_insert(lights, {rgb, brightness, radiusSqr, e2:getPos(), e2, size, math_log(size, lightLog)})
                    --table_insert(lights, {rgb, brightness / math_log(size + 1, 2), size * size, e2:getPos(), e2, size + 1})
                    table_insert(lights, {rgb, rgb * brightness * 219.51097961044988183998, brightness * 55975.29980066471986919588, e2:getPos(), e2})
                end
            end
        end
        net.start("found lights")
        net.writeTable(lights)
        net.send(owner())
        print("Found " .. #lights .. " lights")
    end)
else --CLIENT
    if player() != owner() then
        --NOT OWNER'S CLIENT
        
        net.start("spawned")
        net.send()
        local enabled = true
        local lines = {}
        local lineLengths = {}
        net.receive("enabled", function()
            enabled = net.readBool()
            lines = {}
            if enabled then
                net.receive("line", function(size)
                    if enabled then
                        table_insert(lines, net.readData(size))
                    end
                end)
            else
                --Tracer disabled
                net.receive("line")
            end
        end)
        
        net.receive("stop drawing", function()
            lines = {}
        end)
        
        local maxQuota = math_min(0.002, quotaMax() * 0.75)
        
        render.createRenderTarget("trace")
        
        local draw = coroutine.wrap(function()
            local setRGBA = render.setRGBA
            local drawRect = render.drawRect
            while true do
                while not lines[1] or not enabled or quotaAverage() >= maxQuota do coroutine.yield() end
                try(function()
                    local stream = net.stringstream(lines[1])
                    local pixelSize = stream:readUInt16()
                    local y = stream:readUInt16() * pixelSize
                    local length = stream:readUInt16()
                    for x = 0, (length-1) * pixelSize, pixelSize do
                        if not enabled then break end
                        while quotaAverage() >= maxQuota do coroutine.yield() end
                        setRGBA(stream:readUInt8(), stream:readUInt8(), stream:readUInt8(), 255)
                        drawRect(x, y, pixelSize, pixelSize)
                    end
                end)
                table_remove(lines, 1)
            end
        end)
        
        hook.add("renderoffscreen", "receive trace", function()
            --maxQuota = math_min(quotaMax() * 0.75, maxFPSDrop)
            maxQuota = math_min(0.002, quotaMax() * 0.75)
            render.selectRenderTarget("trace")
            draw()
        end)
        
        hook.add("render", "draw trace", function()
            render.setRenderTargetTexture("trace")
            render.drawTexturedRect(0,0,512,512)
            if not enabled then
                render.drawSimpleText(256, 256, "Press use on the screen to enable tracer", 1, 1)
            end
        end)
    else
        --OWNER'S CLIENT (TRACE IN THIS)
        local accel
        local lodShift = 1
        local contrast = 1.2
        --local hitClasses = {"prop_physics", "prop_ragdoll", "acf_gun", "acf_ammo"}
        --local hitClasses = {"prop_physics", "prop_ragdoll", "gmt_instrument_piano", "acf_gun", "acf_ammo", "gmod_wire_expression2", "starfall_processor", "prop_vehicle_prisoner_pod", "prop_vehicle_airboat", "prop_vehicle_jeep", "gmod_sent_vehicle_fphysics_base", "gmod_wire_gate", "gmod_wire_cpu", "gmod_wire_gpu", "gmod_wire_spu", "gmod_wire_button", "gmod_wire_cameracontroller", "gmod_wire_value", "gmod_wire_damage_detector", "gmod_wire_digitalscreen", "gmod_wire_egp", "gmod_wire_eyepod", "gmod_wire_igniter", "gmod_wire_keyboard", "gmod_wire_lever", "gmod_wire_pod", "gmod_wire_rtcam", "gmod_wire_thruster", "gmod_wire_turret", "gmod_wire_user", "gmod_wire_exit_point", "gmod_wire_consolescreen", "gmod_wire_egp_emitter", "gmod_wire_egp_hud", "gmod_wire_oscilloscope", "gmod_wire_screen", "gmod_wire_textscreen", "gmod_wire_lamp", "gmod_wire_light", "gmod_wire_holoemitter", "gmod_wire_hologrid", "gmod_wire_indicator", "gmod_wire_hudindicator", "gmod_wire_pixel", "gmod_wire_colorer", "gmod_wire_fx_emitter", "gmod_wire_gpulib_controller", "gmod_wire_trail", "gmod_wire_sensor", "gmod_wire_locator", "gmod_wire_target_finder", "gmod_wire_waypoint", "gmod_wire_adv_emarker", "gmod_wire_emarker", "gmod_wire_gps", "gmod_wire_gyroscope", "gmod_wire_las_receiver", "gmod_wire_ranger", "gmod_wire_speedometer", "gmod_wire_trigger", "gmod_wire_watersensor", "gmod_wire_weight", "gmod_wire_adv_input", "gmod_wire_dual_input", "gmod_wire_numpad", "gmod_wire_input", "gmod_wire_output", "gmod_wire_textentry", "gmod_wire_textreceiver", "gmod_wire_socket", "gmod_wire_radio", "gmod_wire_relay", "gmod_wire_twoway_radio", "gmod_wire_graphics_tablet", "gmod_wire_dynamic_button", "gmod_wire_friendslist", "gmod_wire_keypad", "gmod_wire_vehicle", "gmod_wire_freezer", "gmod_wire_grabber", "gmod_wire_nailer", "gmod_wire_forcer", "gmod_wire_hoverball", "gmod_wire_wheel", "phys_hinge", "phys_torque", "gmod_wire_clutch", "gmod_wire_detonator", "gmod_wire_explosive", "gmod_wire_simple_explosive", "gmod_wire_gimbal", "gmod_wire_teleporter", "gmod_wire_soundemitter", "gmod_wire_cd_disk", "gmod_wire_cd_ray", "gmod_wire_dhdd", "gmod_wire_data_satellitedish", "gmod_wire_data_store", "gmod_wire_data_transferer", "gmod_wire_addressbus", "gmod_wire_extbus", "gmod_wire_datasocket", "gmod_wire_dataport", "gmod_wire_datarate", "gmod_wire_hdd", "ra_small_omni", "wired_door", "gmod_wire_door_controller", "gmod_wire_ramcardreader", "gmod_wire_wirer", "gmod_wire_rfid_reader_beam", "gmod_wire_rfid_implanter", "gmod_wire_rfid_reader_prox", "gmod_wire_rfid_filter", "gmod_wire_rfid_reader_act", "damage_scaler", "gmod_wire_xyzbeacon", "gmod_wire_hsranger", "gmod_wire_microphone", "gmod_wire_touchplate", "gmod_wire_servo", "gmod_wire_simple_servo", "gmod_wire_realmagnet", "gmod_wire_dupeport", "gmod_wire_adv_hudindicator", "gmod_wire_hsholoemitter", "gmod_wire_materializer", "gmod_wire_painter", "gmod_wire_keycardspawner", "gmod_wire_dynamicmemory", "gmod_wire_wireless_srv", "gmod_wire_wireless_recv", "starfall_screen", "mediaplayer_tv"}
        local hitClasses = {"gmod_sent_vehicle_fphysics_base", "prop_vehicle_prisoner_pod", "prop_physics", "prop_ragdoll", "gmt_instrument_piano", "gmod_wheel", "gmod_light", "gmod_lamp", "acf_gun", "acf_ammo", "gmod_wire_expression2", "starfall_processor", "gmod_wire_gate", "gmod_wire_cpu", "gmod_wire_gpu", "gmod_wire_spu", "gmod_wire_button", "gmod_wire_cameracontroller", "gmod_wire_value", "gmod_wire_damage_detector", "gmod_wire_digitalscreen", "gmod_wire_egp", "gmod_wire_eyepod", "gmod_wire_igniter", "gmod_wire_keyboard", "gmod_wire_lever", "gmod_wire_pod", "gmod_wire_rtcam", "gmod_wire_thruster", "gmod_wire_turret", "gmod_wire_user", "gmod_wire_exit_point", "gmod_wire_consolescreen", "gmod_wire_egp_emitter", "gmod_wire_egp_hud", "gmod_wire_oscilloscope", "gmod_wire_screen", "gmod_wire_textscreen", "gmod_wire_lamp", "gmod_wire_light", "gmod_wire_holoemitter", "gmod_wire_hologrid", "gmod_wire_indicator", "gmod_wire_hudindicator", "gmod_wire_pixel", "gmod_wire_colorer", "gmod_wire_fx_emitter", "gmod_wire_gpulib_controller", "gmod_wire_trail", "gmod_wire_sensor", "gmod_wire_locator", "gmod_wire_target_finder", "gmod_wire_waypoint", "gmod_wire_adv_emarker", "gmod_wire_emarker", "gmod_wire_gps", "gmod_wire_gyroscope", "gmod_wire_las_receiver", "gmod_wire_ranger", "gmod_wire_speedometer", "gmod_wire_trigger", "gmod_wire_watersensor", "gmod_wire_weight", "gmod_wire_adv_input", "gmod_wire_dual_input", "gmod_wire_numpad", "gmod_wire_input", "gmod_wire_output", "gmod_wire_textentry", "gmod_wire_textreceiver", "gmod_wire_socket", "gmod_wire_radio", "gmod_wire_relay", "gmod_wire_twoway_radio", "gmod_wire_graphics_tablet", "gmod_wire_dynamic_button", "gmod_wire_friendslist", "gmod_wire_keypad", "gmod_wire_vehicle", "gmod_wire_freezer", "gmod_wire_grabber", "gmod_wire_nailer", "gmod_wire_forcer", "gmod_wire_hoverball", "gmod_wire_wheel", "phys_hinge", "phys_torque", "gmod_wire_clutch", "gmod_wire_detonator", "gmod_wire_explosive", "gmod_wire_simple_explosive", "gmod_wire_gimbal", "gmod_wire_teleporter", "gmod_wire_soundemitter", "gmod_wire_cd_disk", "gmod_wire_cd_ray", "gmod_wire_dhdd", "gmod_wire_data_satellitedish", "gmod_wire_data_store", "gmod_wire_data_transferer", "gmod_wire_addressbus", "gmod_wire_extbus", "gmod_wire_datasocket", "gmod_wire_dataport", "gmod_wire_datarate", "gmod_wire_hdd", "ra_small_omni", "wired_door", "gmod_wire_door_controller", "gmod_wire_ramcardreader", "gmod_wire_wirer", "gmod_wire_rfid_reader_beam", "gmod_wire_rfid_implanter", "gmod_wire_rfid_reader_prox", "gmod_wire_rfid_filter", "gmod_wire_rfid_reader_act", "damage_scaler", "gmod_wire_xyzbeacon", "gmod_wire_hsranger", "gmod_wire_microphone", "gmod_wire_touchplate", "gmod_wire_servo", "gmod_wire_simple_servo", "gmod_wire_realmagnet", "gmod_wire_dupeport", "gmod_wire_adv_hudindicator", "gmod_wire_hsholoemitter", "gmod_wire_materializer", "gmod_wire_painter", "gmod_wire_keycardspawner", "gmod_wire_dynamicmemory", "gmod_wire_wireless_srv", "gmod_wire_wireless_recv", "starfall_screen", "mediaplayer_tv"}
        --local hitClasses = {"prop_physics", "prop_ragdoll"}
        --local hitClasses = {"prop_physics"}
        local renderData = {}
        enableHud(owner(), true)
        local displacementMat
        local map = game.getMap()
        if map == "gm_construct_m3_259" then
            displacementMat = "maps/gm_construct_m3_259/metastruct_2/grassand_wvt_patch"
        elseif map == "gm_construct_m3_261" then
            displacementMat = "maps/gm_construct_m3_261/metastruct_2/grassand_wvt_patch"
        end
        map = nil
        
        local blacklist = {}
        
        if file.exists("ray_tracer_blacklist.txt") then
            net.start("blacklist")
            local data = file_read("ray_tracer_blacklist.txt")
            net.writeString(data)
            net.send()
            json.decode(data, function(tbl)
                blacklist = tbl
            end)
        end
        
        net.receive("blacklist", function()
            local id = net.readString()
            local add = net.readBool()
            if add then
                table_insert(blacklist, id)
            else
                local i = 1
                while i <= #blacklist do
                    if blacklist[i] == id then
                        table_remove(blacklist, i)
                        i = i - 1
                    end
                    i = i + 1
                end
            end
            json.encode(blacklist, function(str)
                file_write("ray_tracer_blacklist.txt", str)
            end)
        end)
        
        local manualTextures = {
            ["models/weapons/w_rocketlauncher/w_rocket01"] = true,
            ["models/shadertest/shader5"] = true,
            ["sprops/trans/wheels/wheel_d_rim1"] = true,
            ["models/weapons/c_items/c_urinejar_glass"] = true,
            ["models/gman/pupil_r"] = true
        }
        
        local spheres = {
            ["models/hunter/misc/sphere025x025.mdl"] = {47.45 * 0.25, 4},
            ["models/hunter/misc/sphere075x075.mdl"] = {47.45 * 0.75, 4},
            ["models/hunter/misc/sphere1x1.mdl"] = {47.45, 4},
            ["models/hunter/misc/sphere175x175.mdl"] = {47.45 * 1.75, 4},
            ["models/hunter/misc/sphere2x2.mdl"] = {47.45 * 2, 4},
            ["models/XQM/Rails/gumball_1.mdl"] = {30, 1},
            ["models/XQM/Rails/trackball_1.mdl"] = {30, 1},
            ["models/maxofs2d/hover_basic.mdl"] = {16.8213818868, 1},
            ["models/player/items/scout/soccer_ball.mdl"] = {16.668788274129, 1},
            ["models/dav0r/hoverball.mdl"] = {11.74353313446, 1},
            ["models/props_phx/misc/soccerball.mdl"] = {18.819671630859, 1},
            ["models/maxofs2d/hover_classic.mdl"] = {16.200000762939, 1},
            ["models/maxofs2d/hover_rings.mdl"] = {18.179999669393, 1},
            ["models/weapons/w_models/w_baseball.mdl"] = {8, 1},
            ["models/props_phx/misc/smallcannonball.mdl"] = {14.083333015442, 1},
            ["models/props_gameplay/ball001.mdl"] = {47.635405222575, 1},
            ["models/props_phx/cannonball.mdl"] = {44.800004323324, 1},
            ["models/props_phx/ball.mdl"] = {42.500045776367, 1},
            ["models/hunter/misc/shell2x2.mdl"] = {47.45 * 2, 4}
        }
        for v, k in pairs(spheres) do
            spheres[v][1] = spheres[v][1] * 0.475
        end
        
        local rainy = false
        local skyDir = "cubemap skies/sky1/"
        --local skyDir = "cubemap skies/sky2/"
        --local skyDir = "cubemap skies/sky3/"
        --local skyDir = "cubemap skies/greenscreen sky/"
        --local sunColor = Vector(100,100,100) / 255
        --local sunColor = Vector(180,180,180) / 255
        local sunColor = Vector(255,255,255) / 255
        --local sunColor = Vector(230, 170, 170) / 255
        --local windowColor = Vector(24, 48, 97) * sunColor
        local windowColor = Vector(129, 155, 163) * sunColor
        
        if rainy then
            skyDir = "cubemap skies/sky4/"
            sunColor = Vector(180,180,180) / 255
        end
        
        local capturingNewTexture = false
        
        render.createRenderTarget("new texture")
        
        local streamLimit = 1024 * 512
        local lines = {}
        
        local canStream = false
        
        net.receive("no stream", function()
            canStream = false
        end)
        
        net.receive("yes stream", function()
            canStream = true
        end)
        
        local lineNets = {}
        
        local function networkLine()
            local index = 1
            while index <= #lines do
                local line = lines[index]
                if line.done == true then
                    net.start("line")
                    net.writeUInt16(line.pixelSize)
                    net.writeUInt16(line.y)
                    net.writeUInt16(#line.data)
                    for v, k in pairs(line.data) do
                        for j = 1, 3 do
                            net.writeUInt8(k[j] or 0)
                        end
                    end
                    table_insert(lineNets, net.send(nil, true))
                    table_remove(lines, index)
                    continue
                end
                index = index + 1
            end
        end
        
        local players = find.allPlayers()
        
        net.receive("find players", function()
            players = find.allPlayers()
        end)
        
        net.receive("new player", function()
            table_insert(players, net.readEntity())
        end)
        
        local props = {}
        
        local networking = false
        
        local image = {width = 1, height = 1, data = {}}
        local hitWorld = true
        local maxResBuildUp = 128
        local traceOrigin = chip():getPos()
        local traceAngle = chip():getAngles()
        --local sunDir = Vector(-1,2,3.75):getNormalized()
        
        local sunDir = Vector(-1,2,2):getNormalized()
        --local sunDir = Vector(-1,2,1):getNormalized()
        
        --local sunDir = Vector(2,1,1.5):getNormalized()
        --local sunDir = Vector(1,2,2.75):getNormalized()
        --local sunDir = Vector(-1.5,2,1.5):getNormalized()
        --local sunDir = Vector(1.5,2,1.5):getNormalized()
        --local dotStrength = 0.35
        local dotStrength = 0.15
        --local dotStrength = 0.5
        --local shadowStrength = 0.35
        local shadowStrength = 0.25
        --local shadowStrength = 1
        --local shadowStrength = 0.45
        --local shadowStrength = 0.25
        local maxDarkening = 1 - 0.35
        local useAlpha = true
        local drawShadows = true
        local drawSimpleShadows = true
        
        local pixelSize = 1
        
        local res = {x = 512, y = 512}
        local targetRes = {x = res.x, y = res.y}
        local minFPS = 30
        
        local maxCPU = math_min(quotaMax() * 0.1, 1 / minFPS)
        --local CPUStepSizeMult = 0.00005
        local CPUStepSizeMult = 0.0001
        
        local traceLength = 100000
        local lights = {}
        
        --local maxCacheSize = 100
        local maxCacheSize = 10
        local textureCache = {}
        local textureCacheOrder = {}
        
        --[[local matOverwrites = {
            ["models/shadertest/shader5"] = {mat = "models/shadertest/shader5"} //Makes it not look for a different material because I had to manually make this one with special settings
        }]]
        
        local fov = 90
        local fovrad = math.rad(fov)
        local rayDirPre = Vector(res.x / 2 / math.tan(fovrad / 2), res.x / 2, res.y / 2)
        
        local function newLine(y)
            table_insert(renderData, {})
            table_insert(lines, {
                pixelSize = pixelSize,
                y = y,
                done = false,
                res = {x = res.x, y = res.y},
                data = renderData[#renderData]
            })
        end
        
        local rays = {}
        local holos = {}
        local availableHolos = {}
        
        for i = 1, 10 do
            if holograms.canSpawn() then
                local holo = holograms.create(chip():getPos(), Angle(0,0,0), "models/hunter/plates/plate.mdl")
                holo:setMaterial("models/debug/debugwhite")
                holo:suppressEngineLighting(true)
                table_insert(availableHolos, holo)
            else
                break
            end
        end
        
        local function getHolo()
            local holo
            if #availableHolos != 0 then
                holo = table_remove(availableHolos)
                table_insert(holos, holo)
                holo:setColor(Color(255,255,255,255))
                holo:setNoDraw(false)
            end
            return holo
        end
        
        local function removeHolos()
            while #holos != 0 do
                local holo = table_remove(holos)
                holo:setNoDraw(true)
                table_insert(availableHolos, holo)
            end
        end
        
        local function deleteHolos()
            while #holos != 0 do
                table_remove(holos):remove()
            end
            while #availableHolos != 0 do
                table_remove(holos):remove()
            end
        end
        
        local function aimHolo(holo, from, to)
            holo:setPos((from + to) / 2)
            holo:setAngles((to - from):getAngle())
            holo:setScale(Vector(from:getDistance(to), 0.5, 0.5) / 3)
        end
        
        local function aimHolos()
            removeHolos()
            for v, k in pairs(rays) do
                if k != nil then
                    local holo = getHolo()
                    if holo == nil then
                        break
                    end
                    aimHolo(holo, k.start, k.stop)
                    if k.sky then
                        local color = k.shadow * 255
                        holo:setColor(Color(0, 0, color))
                    end
                    if k.light then
                        local rgb = k.rgb
                        holo:setColor(Color(rgb[1], rgb[2], rgb[3]))
                    end
                end
            end
        end
        
        --[[local holo = holograms.create(chip():getPos(), Angle(0,0,0), "models/hunter/plates/plate.mdl")
        holo:setMaterial("models/debug/debugwhite")
        holo:suppressEngineLighting(true)]]
        local finalHitPos = Vector()
        
        local function calcPixelSize()
            pixelSize = math_floor(math_min(1024 / res.x, 1024 / res.y))
        end
        
        local function loadSettings()
            if file.exists("tracer settings.txt") then
                json.decode(file_read("tracer settings.txt"), function(t)
                    if t != nil then
                        --[[if t.sunDir != nil then sunDir = t.sunDir end
                        if t.dotStrength != nil then dotStrength = t.dotStrength end
                        if t.shadowStrength != nil then shadowStrength = t.shadowStrength end
                        if t.useAlpha != nil then useAlpha = t.useAlpha end]]
                        if t.drawShadows != nil then drawShadows = t.drawShadows end
                        if t.drawSimpleShadows != nil then drawSimpleShadows = t.drawSimpleShadows end
                        if t.res ~= nil then
                            res = {x = t.res.x, y = t.res.y}
                            targetRes = {x = t.res.x, y = t.res.y}
                        end
                        if t.minFPS != nil then minFPS = t.minFPS end
                        if t.fov != nil then fov = t.fov end
                        if t.useAlpha != nil then useAlpha = t.useAlpha end
                        if t.sunColor then sunColor = t.sunColor end
                        if t.sunDir then sunDir = t.sunDir end
                        if t.skyDir then skyDir = t.skyDir end
                        fovrad = math.rad(fov)
                        rayDirPre = Vector(res.x / 2 / math.tan(fovrad / 2), res.x / 2, res.y / 2)
                        for v,k in pairs(t) do
                            if v == "drawSimpleShadows" or v == "useAlpha" then continue end
                            if k == true then
                                print(v .. " = true")
                            elseif k == false then
                                print(v .. " = false")
                            elseif type(k) == "table" then
                                print(v .. " =")
                                printTable(k)
                            else
                                print(v, " = ", k)
                            end
                        end
                    end
                end)
            end
        end
        
        loadSettings()
        
        local function saveSettings()
            json.encode({
                --res = res,
                res = targetRes,
                minFPS = minFPS,
                fov = fov,
                drawShadows = drawShadows,
                sunDir = sunDir,
                sunColor = sunColor,
                skyDir = skyDir
                --drawSimpleShadows = drawSimpleShadows,
                --useAlpha = useAlpha
            }, function(s)
                file_write("tracer settings.txt", s)
            end)
        end
        
        local function adjustCPU()
            --maxCPU = math_clamp(maxCPU - (minFPS - 1 / timer.frametime()) * CPUStepSizeMult, 0, math_min(quotaMax() * 0.9, 1 / minFPS))
            maxCPU = maxCPU + math_min(math_min(quotaMax() * 0.9, 1 / minFPS) - maxCPU, CPUStepSizeMult)
            json.setMaxQuota(maxCPU)
        end
        
        local function scale(width, height, targetWidth, targetHeight) --Returns size for a scaled up image while maintaining aspect ratio
            local ratio = math_max(width / targetWidth, height / targetHeight)
            return width / ratio, height / ratio, ratio
        end
        
        local function findLast(haystack, needle)
            local pos = string_find(string_reverse(haystack), string_reverse(needle), 1, true)
            if pos == nil then
                return nil
            end
            return #haystack - pos - #needle + 2
        end
        
        local function removeBackground(pixel, background, tint) --Inputs are vectors, outputs alpha
            --[[if tint == background then
                return 255
            end]]
            local alpha = (pixel - background) / (tint - background) * 255
            return math_clamp(math_round((alpha[1] + alpha[2] + alpha[3]) / 3), 0, 255)
        end
        
        --local function saveNewTexture(texture, hasAlpha)
        local function saveNewTexture(texture, vmt)
            --Set hasAlpha to false for world textures
            if texture == "error" or texture == nil or texture == "" then
                return nil
            end
            local usemat = material.create("UnlitGeneric")
            local basetexture = texture
            --try(function()
                --basetexture = material_getTexture(texture, "$basetexture")
                usemat:setTexture("$basetexture", basetexture)
            --end)
            
            local alphatest = false
            local alphatestreference = 127.5
            local alphaMult = 1
            local hasAlpha = true
            if vmt then
                alphaMult = material_getFloat(vmt, "$alpha") or 1
                alphatest = bit_band(256, material_getInt(vmt, "$flags")) ~= 0
                hasAlpha = bit_band(2097152, material_getInt(vmt, "$flags")) ~= 0
                if alphatest then
                    alphatestreference = math_clamp((material_getFloat(vmt, "$alphatestreference") or 0.5) * 255, 0, 255)
                end
            end
            
            basetexture = string_replace(string_replace(basetexture, "\\", "/"), "*", "")
            local width = usemat:getWidth()
            local height = usemat:getHeight()
            if width >= 1024 and height >= 1024 then
                local ratio = math_min(width / 512, height / 512)
                width = width / ratio
                height = height / ratio
            end
            
            print("Capturing " .. basetexture .. " " .. width .. "x" .. height)
            
            render.selectRenderTarget("new texture")
            --render.setColor(Color(0,0,0))
            --render.drawRect(0,0,1024,1024)
            render.clear(Color(0,0,0,0))
            render.setColor(Color(255,255,255))
            --if hasAlpha then
                --Have to do this because of a bug with drawing materials to an rt
                local readyToCapture = false
                render.setMaterial(usemat)
                render.drawTexturedRect(0, 0, width, height)
                --hook.add("render", "capture",function()
                hook.add("drawhud", "capture", function()
                    render.setRenderTargetTexture("new texture")
                    render.drawTexturedRect(0,0,512,512)
                    --hook.remove("render", "capture")
                    hook.remove("drawhud", "capture")
                    readyToCapture = true
                end)
                while not readyToCapture do
                    coroutine.yield()
                end
                render.selectRenderTarget("new texture")
                render.clear(Color(0,0,0,0))
                render.setColor(Color(255,255,255))
                render.setMaterial(usemat)
                render.drawTexturedRect(0, 0, width, height)
            
            while quotaAverage() >= maxCPU do coroutine.yield() end
            render.capturePixels()
            render.selectRenderTarget()
            
            local txtPath = "textures/" .. basetexture .. ".txt"
            local dir = string_sub(txtPath, 1, findLast(txtPath, "/") - 1)
            
            file.createDir(dir)
            file_write(txtPath, string_char(
                width%0x100, bit_rshift(width, 8)%0x100,
                height%0x100, bit_rshift(height, 8)%0x100
            ))
            local text = ""
            --This is completely unneeded, it just shows progress
            local total = width * height
            local current = 0
            capturingNewTexture = true
            local scaledWidth, scaledHeight, scaleRatio = scale(width, height, 512, 512)
            local posx = (512 - scaledWidth) / 2
            local posy = (512 - scaledHeight) / 2
            local capturex = 0
            local capturey = 0
            local captureColor = Color(0,0,0,0)
            hook.add("render", "new texture progress", function()
                render.setMaterial(usemat)
                render.drawTexturedRect(posx, posy, scaledWidth, scaledHeight)
                render.setColor(Color(255,0,0,180))
                render.drawRect(capturex / scaleRatio - 1 + posx, capturey / scaleRatio - 1 + posy, 3, 3)
                render.setColor(Color(0,255,0))
                local w = 512 * current / total
                render.drawRect(0, 492, w, 20)
                if w <= 10 then
                    local color = captureColor
                    color[4] = w * 25.5
                    render.setColor(captureColor)
                    render.drawRect(w / 2, 497, w / 2, 10)
                else
                    render.setColor(captureColor)
                    render.drawRect(5, 497, w - 10, 10)
                end
            end)
            local textLength = 0
            --Capture texture data
            --if hasAlpha then
                --if width <= 512 then
                    --Drew 2 versions, one without alpha to the right of the one with alpha
                    for x = 0, width - 1 do
                        for y = 0, height - 1 do
                            capturex = x
                            capturey = y
                            current = current + 1
                            local rgba = render.readPixel(x, y)
                            --local rgb = render.readPixel(x + 512, y)
                            --local alpha = removeBackground(Vector(rgba[1], rgba[2], rgba[3]), Vector(0,0,0), Vector(rgb[1], rgb[2], rgb[3]))
                            --text = text .. string_char(rgb[1], rgb[2], rgb[3], alpha)
                            local a
                            local r, g, b = rgba[1], rgba[2], rgba[3]
                            if alphatest and r == g and g == b then
                                a = r > alphatestreference and 255 or 0
                            elseif hasAlpha then a = math_clamp(rgba[4] * alphaMult, 0, 255)
                            else a = 255 end
                            --text = text .. string_char(r, g, b, math_clamp(a * alphaMult, 0, 255))
                            text = text .. string_char(r, g, b, a)
                            textLength = textLength + 4
                            if textLength > fileAppendSize then
                                file_append(txtPath, text)
                                text = ""
                                textLength = 0
                            end
                            while quotaAverage() >= maxCPU do
                                --captureColor = Color(rgb[1], rgb[2], rgb[3], alpha)
                                captureColor = Color(r, g, b, a)
                                coroutine.yield()
                            end
                        end
                    end
                    file_append(txtPath, text)
            hook.remove("render", "new texture progress")
            capturingNewTexture = false
            usemat:destroy()
            render.selectRenderTarget("screen")
            return basetexture
        end
        
        local function getPixelDirect(data, x, y)
            local place = (x * data.height + y) * 4 + data.start
            local color
            local alpha
            local error
            try(function()
                color = Vector(string_byte(data.data, place, place+2))
                alpha = string_byte(data.data, place + 3, place + 3)
                if color == nil or alpha == nil then
                    color = Vector(255,0,0)
                    alpha = 255
                    if place > #data.data then
                        print("Deleting \"" .. data.path .. "\" because of read error. File too short, most likely incomplete.")
                        file_delete(data.path)
                        error = "File too short"
                    end
                end
            end, function()
                color = Vector(255,0,0)
                alpha = 255
                if place > #data.data then
                    print("Deleting \"" .. data.path .. "\" because of read error. File too short, most likely incomplete.")
                    file_delete(data.path)
                    error = "File too short"
                end
            end)
            return color, alpha, error
        end
        
        local mipmapDenom = 512
        local minMipmap = 32
        local maxMipmapLevel = 4
        
        local function getAverage(x1, y1, x2, y2, data)
            local color = Vector(0)
            local alpha = 0
            for x3 = x1, x2 do
                for y3 = y1, y2 do
                    local newColor, newAlpha, error = getPixelDirect(data, x3 % data.width, y3 % data.height)
                    if error then
                        --[[print("Deleting \"textures/" .. mat .. ".txt\" because of read error. File too short, most likely incomplete.")
                        file_delete("textures/" .. mat .. ".txt")]]
                        return nil
                    end
                    color = color + newColor
                    alpha = alpha + newAlpha
                end
            end
            local count = (x2 - x1 + 1) * (y2 - y1 + 1)
            return color / count, alpha / count
        end
        
        function loadMat(ogmat, useThisMat, mipmapLevel)
            local mat = ogmat
            if not mat or mat == "" then
                return nil
            end
            local basetexture = mat
            if useThisMat ~= true then
                try(function()
                    basetexture = material_getTexture(mat, "$basetexture")
                    if basetexture == "error" then
                        basetexture = material_getTexture(mat, "REFRACTTINTTEXTURE")
                    end
                    mat = string_replace(string_replace(basetexture, "\\", "/"), "*", "")
                end)
            end
            if mipmapLevel and mipmapLevel ~= 0 then
                --MIPMAP
                mipmapLevel = math_min(mipmapLevel, maxMipmapLevel)
                local name = "textures/mipmaps/" .. mat .. "_" .. mipmapLevel
                local t = textureCache[name]
                if t then
                    return t
                else
                    local txtPath = name .. ".txt"
                    local data = file_read(txtPath)
                    if data then
                        --LOAD MIPMAP
                        local a, b = string_byte(data, 1, 2)
                        local ogwidth = b * 0x100 + a
                        
                        a, b = string_byte(data, 3, 4)
                        local ogheight = b * 0x100 + a
                        
                        a, b = string_byte(data, 5, 6)
                        local newWidth = b * 0x100 + a
                        
                        a, b = string_byte(data, 7, 8)
                        local newHeight = b * 0x100 + a
                        
                        t = {path = txtPath, mipmap = true, data = data, ogwidth = ogwidth, ogheight = ogheight, width = newWidth, height = newHeight, widthRatio = ogwidth / newWidth, heightRatio = ogheight / newHeight, start = 9}
                        --[[if newWidth * newHeight * 4 + 8 > #data then
                            print("Deleting \"" .. txtPath .. "\" because of read error. File too short, most likely incomplete.")
                            file_delete(txtPath)
                            return loadMat(ogmat, useThisMat, mipmapLevel)
                        end]]
                        textureCache[name] = t
                        table_insert(textureCacheOrder, mat)
                        if #textureCacheOrder > maxCacheSize then
                            textureCache[table_remove(textureCacheOrder, 1)] = nil
                        end
                        return t
                    else
                        --CREATE MIPMAP
                        data = loadMat(mat, useThisMat)
                        if not data then return nil end
                        local mipmapPower = 2 ^ mipmapLevel
                        local newWidth = math_clamp(data.width / mipmapPower, minMipmap, data.width)
                        local widthRatio = data.width / newWidth
                        local newHeight = math_clamp(data.height / mipmapPower, minMipmap, data.height)
                        local heightRatio = data.height / newHeight
                        
                        local dir = string_sub(name, 1, findLast(name, "/") - 1)
                        local text = string_char(
                            data.width%0x100, bit_rshift(data.width, 8)%0x100,
                            data.height%0x100, bit_rshift(data.height, 8)%0x100,
                            newWidth%0x100, bit_rshift(newWidth, 8)%0x100,
                            newHeight%0x100, bit_rshift(newHeight, 8)%0x100
                        )
                        file.createDir(dir)
                        file_write(txtPath, text)
                        text = ""
                        local textLength = 0
                        
                        for x = 0, data.width - 1, widthRatio do
                            for y = 0, data.height - 1, heightRatio do
                                while quotaAverage() > maxCPU do coroutine.yield() end
                                local color, alpha = getAverage(x, y, x + widthRatio - 1, y + heightRatio - 1, data)
                                if not color then return loadMat(mat, true, mipmapLevel) end
                                text = text .. string_char(color[1], color[2], color[3], alpha)
                                textLength = textLength + 4
                                if textLength > fileAppendSize then
                                    file_append(txtPath, text)
                                    text = ""
                                    textLength = 0
                                end
                            end
                        end
                        file_append(txtPath, text)
                        text = nil
                        return loadMat(mat, true, mipmapLevel)
                    end
                end
            else
                --NO MIPMAP
                local name = "textures/" .. mat
                local t = textureCache[name]
                local data
                if t then
                    return t
                else
                    local txtPath = name .. ".txt"
                    data = file_read(txtPath)
                    if not data then
                        if saveNewTexture(basetexture, useThisMat and nil or mat) then
                            data = file_read(txtPath)
                        end
                    end
                    if data then
                        local a, b = string_byte(data, 1, 2)
                        local width = b * 0x100 + a
                        a, b = string_byte(data, 3, 4)
                        local height = b * 0x100 + a
                        t = {path = txtPath, mipmap = false, data = data, width = width, height = height, start = 5}
                        --[[if width * height * 4 + 4 > #data then
                            print("Deleting \"" .. txtPath .. "\" because of read error. File too short, most likely incomplete.")
                            file_delete(txtPath)
                            return loadMat(ogmat, useThisMat, mipmapLevel)
                        end]]
                        textureCache[name] = t
                        table_insert(textureCacheOrder, mat)
                        if #textureCacheOrder > maxCacheSize then
                            textureCache[table_remove(textureCacheOrder, 1)] = nil
                        end
                        return t
                    end
                end
            end
        end
        
        local function blur(data, x, y, radius)
            local rs = math_ceil(radius * 2.57)
            local color = Vector(0,0,0)
            local alpha = 0
            local wsum = 0
            local r2 = 2 * radius * radius
            local c = math_pi * r2
            for x1 = x - radius, x + radius do
                for y1 = y - radius, y + radius do
                    while quotaAverage() >= maxCPU do coroutine.yield() end
                    local x2 = x1 % data.width
                    local y2 = y1 % data.height
                    local dsq = (x1 - y) ^ 2 + (y1 - x) ^ 2
                    local wght = math.exp(-dsq / r2) / c
                    local newColor, newAlpha = getPixelDirect(data, x2, y2)
                    color = color + newColor * wght
                    alpha = alpha + newAlpha * wght
                    wsum = wsum + wght
                end
            end
            return color / wsum, alpha / wsum
        end
        
        local function getPixel(mat, u, v, dist, useThisMat, noSmoothing, xyNotuv)
            local t
            if dist == nil then
                t = loadMat(mat, useThisMat)
            else
                --t, overwrite = loadMat(mat, useThisMat, math_max(math_floor(math_log(dist * 0.01, 2) - 1), 0))
                t = loadMat(mat, useThisMat, math_max(math_floor(math_log(dist * 0.01, 2) - lodShift), 0))
            end
            if not t then
                return Vector(0, 0, 0), 0
            end
            
            if xyNotuv == true then
                local x = math_round(u) % t.width
                local y = math_round(v) % t.height
                local color, alpha = getPixelDirect(t, x, y)
                return color, alpha
            elseif noSmoothing == true then
                local x = math_round(u * (t.width - 1)) % t.width
                local y = math_round(v * (t.height - 1)) % t.height
                local color, alpha = getPixelDirect(t, x, y)
                return color, alpha
            else
                local x = u * (t.width - 1)
                local y = v * (t.height - 1)
                local x1 = math_floor(x) % t.width
                local x2 = math_ceil(x) % t.width
                local y1 = math_floor(y) % t.height
                local y2 = math_ceil(y) % t.height
                local ratiox = x % 1
                local ratioy = y % 1
                local color1, alpha1 = getPixelDirect(t, x1, y1)
                local color2, alpha2 = getPixelDirect(t, x2, y1)
                local color3, alpha3 = getPixelDirect(t, x1, y2)
                local color4, alpha4 = getPixelDirect(t, x2, y2)
            
                local color = math_lerpVector(ratioy, math_lerpVector(ratiox, color1, color2), math_lerpVector(ratiox, color3, color4))
                local alpha = math_lerp(ratioy, math_lerp(ratiox, alpha1, alpha2), math_lerp(ratiox, alpha3, alpha4))
            
                return color, alpha
            end
        end
        
        local function drawSky(dir)
            local absx = math_abs(dir[1])
            local absy = math_abs(dir[2])
            local absz = math_abs(dir[3])
            
            local xPositive = (dir[1] > 0 and true or false)
            local yPositive = (dir[2] > 0 and true or false)
            local zPositive = (dir[3] > 0 and true or false)
            
            local maxAxis
            local uc
            local vc
            local index
            local pre
            
            if absx >= absy and absx >= absz then
                maxAxis = absx
                if xPositive then
                    uc = -dir[3]
                    vc = dir[2]
                    index = 0
                    pre = "px"
                else
                    uc = dir[3]
                    vc = dir[2]
                    index = 1
                    pre = "nx"
                end
            end
            
            if absy >= absx and absy >= absz then
                maxAxis = absy
                if yPositive then
                    uc = dir[1]
                    vc = -dir[3]
                    index = 2
                    pre = "py"
                else
                    uc = dir[1]
                    vc = dir[3]
                    index = 3
                    pre = "ny"
                end
            end
            
            if absz >= absx and absz >= absy then
                maxAxis = absz
                if zPositive then
                    uc = dir[1]
                    vc = dir[2]
                    index = 4
                    pre = "pz"
                else
                    uc = -dir[1]
                    vc = dir[2]
                    index = 5
                    pre = "nz"
                end
            end
            
            uc = (uc / maxAxis + 1) / 2
            vc = (vc / maxAxis + 1) / 2
            local u = uc
            local v = vc
            
            local x = u * (2048 - 1)
            local y = v * (2048 - 1)
            local x1 = math_floor(x) % 2048
            local x2 = math_ceil(x) % 2048
            local y1 = math_floor(y) % 2048
            local y2 = math_ceil(y) % 2048
            local ratiox = x % 1
            local ratioy = y % 1
            local color1 = getPixel(skyDir .. pre .. math_floor(x1 / 512) .. math_floor(y1 / 512), x1, y1, nil, true, true, true)
            local color2 = getPixel(skyDir .. pre .. math_floor(x2 / 512) .. math_floor(y1 / 512), x2, y1, nil, true, true, true)
            local color3 = getPixel(skyDir .. pre .. math_floor(x1 / 512) .. math_floor(y2 / 512), x1, y2, nil, true, true, true)
            local color4 = getPixel(skyDir .. pre .. math_floor(x2 / 512) .. math_floor(y2 / 512), x2, y2, nil, true, true, true)
            
            local color = math_lerpVector(ratioy, math_lerpVector(ratiox, color1, color2), math_lerpVector(ratiox, color3, color4))
            
            return color, 255
        end
        
        local function rotate(vector, matrix)
            return Vector(
                vector[1]*matrix[1][1] + vector[2]*matrix[1][2] + vector[3]*matrix[1][3],
                vector[1]*matrix[2][1] + vector[2]*matrix[2][2] + vector[3]*matrix[2][3],
                vector[1]*matrix[3][1] + vector[2]*matrix[3][2] + vector[3]*matrix[3][3]
            )
        end
        
        local unitMatrix = {{1,0,0},{0,1,0},{0,0,1}}
        
        local function GModMatrixToCPP(matrix)
            local ang = {
                {0, 0, 0},
                {0, 0, 0},
                {0, 0, 0},
            }
            local invAng = {
                {0, 0, 0},
                {0, 0, 0},
                {0, 0, 0},
            }

            local nonZero = false
            for row = 1, 3 do
                for col = 1, 3 do
                    local cell = matrix:getField(row, col)
                                if cell != 0 then nonZero = true end
                    ang[row][col] = cell
                    invAng[col][row] = cell
                end
            end
            if not nonZero then
                ang, invAng = unitMatrix, unitMatrix
            end
            return ang, invAng
        end
        
        local function getNormalMap(mat, u, v, hitnormal, tangent, binormal, ent)
            if not mat then return hitnormal end
            local normal = Vector(0,0,1)
            local normalDone = false
            local normalmap = material_getTexture(mat, "$bumpmap")
            if normalmap ~= "error" and normalmap ~= "null-bumpmap" then
                normal = getPixel(normalmap, u, v, nil, true) / 127.5 - Vector(1)
                normal = Vector(
                    normal[1]*tangent[1] + normal[2]*binormal[1] + normal[3]*hitnormal[1],
                    normal[1]*tangent[2] + normal[2]*binormal[2] + normal[3]*hitnormal[2],
                    normal[1]*tangent[3] + normal[2]*binormal[3]+ normal[3]*hitnormal[3]
                )
                normal:normalize()
                return normal
            end
            return hitnormal
        end
        
        local function worldGetColor(mat, pos, normal, start, stop, dist, nonormal, useThisMat)
            if mat == "TOOLS/TOOLSNODRAW" then
                return Vector(128), 0, 0, 0
            end
            local t
            if dist then
                t = loadMat(mat, useThisMat, math_max(math_floor(math_log(dist * 0.01, 2) - lodShift), 0))
            else
                t = loadMat(mat, useThisMat)
            end
            if not t then
                --[[if mat ~= "**studio**" then
                    print(mat)
                    print("bad")
                end]]
                local color = render.traceSurfaceColor(start, stop)
                return Vector(color[1], color[2], color[3]), color[4], Vector(0,0,1), 0, 0
            end
            
            local posLocal = worldToLocal(pos, Angle(0,0,0), Vector(0,0,0), normal:getAngle())
            --[[local a = normal:cross(Vector(1,0,0))
            local b = normal:cross(Vector(0,1,0))
            local c = normal:cross(Vector(0,0,1))
            local max_ab = a:dot(a) < b:dot(b) and b or a
            local uAxis = max_ab:dot(max_ab) < c:dot(c) and c or max_ab
            local vAxis = normal:cross(uAxis)
            local x = uAxis:dot(pos) * 4
            local y = vAxis:dot(pos) * 4]]
            --[[local a, b, c = normal:cross(Vector(1,0,0)), normal:cross(Vector(0,1,0)), normal:cross(Vector(0,0,1))
            local max_ab = a:dot(a) < b:dot(b) and b or a
            local uAxis = max_ab:dot(max_ab) < c:dot(c) and c or max_ab
            local vAxis = normal:cross(uAxis)
            local x, y = uAxis:dot(pos) * 4, vAxis:dot(pos) * 4]]
            
            
            local x = posLocal[2] * 4
            local y = -posLocal[3] * 4
            local x1, y1, x2, y2, ratiox, ratioy
            local color
            local alpha
            if t.mipmap then
                x = x / t.widthRatio
                y = y / t.heightRatio
            end
            local u = x / t.width
            local v = y / t.height
            local x1 = math_floor(x) % t.width
            local x2 = math_ceil(x) % t.width
            local y1 = math_floor(y) % t.height
            local y2 = math_ceil(y) % t.height
            local ratiox = x % 1
            local ratioy = y % 1
            
            local color1, alpha1 = getPixelDirect(t, x1, y1, mat)
            local color2, alpha2 = getPixelDirect(t, x2, y1, mat)
            local color3, alpha3 = getPixelDirect(t, x1, y2, mat)
            local color4, alpha4 = getPixelDirect(t, x2, y2, mat)

            color = math_lerpVector(ratioy, math_lerpVector(ratiox, color1, color2), math_lerpVector(ratiox, color3, color4))
            alpha = math_lerp(ratioy, math_lerp(ratiox, alpha1, alpha2), math_lerp(ratiox, alpha3, alpha4))
            return color, alpha, u, v
            --return color, 255, u, v
        end
        
        local function getMaterial(ent)
            if ent == nil or not ent:isValid() then
                return ""
            end
            local mat = ent:getMaterial()
            if mat == "" then
                mat = ent:getMaterials()[1]
            end
            if mat == nil then
                mat = ""
            end
            return mat
        end
        
        local function getColor(ent, pos, normal, start, stop, dist, sphereData)
            if ent == nil or not ent:isValid() then
                return Vector(255, 255, 255), 255, Vector(0,0,1)
            end
            local pixelColor, alpha
            local mat = getMaterial(ent)
            local color = ent:getColor()
            --[[if mat == "models/debug/debugwhite" or mat == "models/shiny" then
                return Vector(color[1], color[2], color[3]), color[4], 0, 0
            end]]
            local ogmat = mat .. ""
            mat = string_replace(mat, "*", "")
            local pixelColor, alpha
            local model = ent:getModel()
            local uvmap = uvmaps[model]
            local u, v
            local tangent, binormal
            if uvmap == nil then
                if sphereData != nil then
                    local rotatedNormal = localToWorld(normal, Angle(), Vector(), ent:getAngles())
                    u = (math_atan2(rotatedNormal[2], rotatedNormal[1]) / math_pi / 2) * sphereData[2]
                    v = (rotatedNormal[3] + 1) * sphereData[2] / 4
                    pixelColor, alpha = getPixel(mat, u, v, dist)
                else
                    pixelColor, alpha, u, v = worldGetColor(mat, pos, normal, start, stop, dist)
                end
            else
                local entPos = ent:obbCenterW()
                local entAng = ent:getAngles()
                
                local localPos, localNormal = worldToLocal(pos, normal:getAngle(), entPos, entAng)
                localNormal = localNormal:getForward()
                
                --Snap unit vector to one axis
                local max = math_max(localNormal[1], localNormal[2], localNormal[3])
                local min = math_min(localNormal[1], localNormal[2], localNormal[3])
                local index
                --local size = ent:obbSize()
                local size = uvmap[7]
                local halfSize = size / 2
                local ratiox
                local ratioy
                if max > math_abs(min) then
                    --Max is prevailing direction and positive
                    if max == localNormal[1] then
                        index = 2
                        ratiox = (halfSize[2] - localPos[2]) / size[2]
                        ratioy = (halfSize[3] - localPos[3]) / size[3]
                    elseif max == localNormal[2] then
                        index = 4
                        ratiox = (halfSize[1] - localPos[1]) / size[1]
                        ratioy = (halfSize[3] - localPos[3]) / size[3]
                    else
                        index = 6
                        ratiox = (halfSize[2] - localPos[2]) / size[2]
                        ratioy = (halfSize[1] - localPos[1]) / size[1]
                    end
                else
                    --Min is prevailing direction and negative
                    if min == localNormal[1] then
                        index = 1
                        ratiox = (halfSize[2] - localPos[2]) / size[2]
                        ratioy = (halfSize[3] - localPos[3]) / size[3]
                    elseif min == localNormal[2] then
                        index = 3
                        ratiox = (halfSize[1] - localPos[1]) / size[1]
                        ratioy = (halfSize[3] - localPos[3]) / size[3]
                    else
                        index = 5
                        ratiox = (halfSize[2] - localPos[2]) / size[2]
                        ratioy = (halfSize[1] - localPos[1]) / size[1]
                    end
                end
                --
                
                u = uvmap[index][2][1] + (uvmap[index][1][1] - uvmap[index][2][1]) * ratiox
                v = uvmap[index][2][2] + (uvmap[index][1][2] - uvmap[index][2][2]) * ratioy
                tangent = uvmap[index][3]
                binormal = uvmap[index][4]
                
                pixelColor, alpha = getPixel(mat, u, v, dist)
                
                --[[if nonormal != true then
                    normalMap = getNormalMap(ogmat, u, v)
                end]]
            end
            
            return pixelColor * Vector(color[1], color[2], color[3]) / 255, alpha * color[4] / 255, u, v, tangent, binormal
        end
        
        local maxBounces = 5
        
        local function phong(trc, mat, dir, bounces, normal, dot, shadow, color, pos, lightData, alpha)
            local phongColor = Vector(0,0,0)
            try(function()
                local phongEnabled = material_getInt(mat, "$phong")
                if phongEnabled == 1 then
                    --dist = dist * dist
                    local reflectColor = Vector(255,255,255)
                    local phongboost = material_getInt(mat, "$phongboost")
                    --local phongmat = material_getTexture(mat, "$$phongexponenttexture")
                    --local phongexponent
                    --if not phongmat then
                    local phongexponent = material_getInt(mat, "$phongexponent")
                    --end
                    local fresnel = material_getVector(mat, "$phongfresnelranges")
                    table_insert(lightData, {sunDir, sunColor * shadow})
                    local specular = 0
                    if dot > 0 then
                        local fresnelDot = 1 - normal:dot(dir)
                        fresnelDot = fresnelDot * fresnelDot
                        local fresnelMult
                        if fresnelDot > 0.5 then fresnelMult = math_lerp(fresnelDot*2-1, fresnel[2], fresnel[3])
                        else fresnelMult = math_lerp(fresnelDot*2, fresnel[1], fresnel[2]) end
                        --[[local halfDir = lightDir + viewDir
                        halfDir:normalize()
                        local specAngle = math_max(halfDir:dot(normal), 0)
                        specular = specAngle ^ (phongexponent / 4)]]
                        local mult = phongboost * 40 * fresnelMult
                        for _, lightSet in ipairs(lightData) do
                            local lightDir = lightSet[1]
                            local reflectDir = -lightDir - 2 * normal:dot(-lightDir) * normal
                            local specAngle = math_max(reflectDir:dot(-dir), 0)
                            specular = specAngle ^ (phongexponent / 4)
                        
                            --phongColor = specular * phongboost * sunColor * 40 * shadow * fresnelMult
                            phongColor = phongColor + specular * mult * lightSet[2]
                        end
                        --[[if bounces < maxBounces then
                            reflectColor = ray(trc.HitPos, (dir - 2 * normal:dot(dir) * normal):getNormalized(), nil, bounces)
                        end
                        phongColor = reflectColor / 255 * specular * phongboost * sunColor * 40 * shadow]]
                    end
                    --[[
                    local reflectDir = dir - 2 * normal:dot(dir) * normal
                    if bounces < maxBounces then
                        reflectColor = ray(trc.HitPos, reflectDir:getNormalized(), nil, bounces)
                    else
                        reflectColor = Vector(255,255,255)
                    end
                    
                    local phongMult = 0.95 ^ phongexponent * phongboost
                    --local phongMult = 0.98 ^ phongexponent * phongboost
                    --local phongMult = 1
                    --local phongColor = color + reflectColor * phongMult
                    phongColor = math_lerpVector(math_clamp(phongMult, 0, 1), color, reflectColor)]]
                end
            end, function()
                phongColor = Vector(0,0,0)
            end)
            return phongColor
        end
        
        function fresnel(I, N, ior)
            local cosI = math_clamp(-1, 1, I:dot(N))
            local etaI, etaT = 1, ior
            local kr = 0
            
            if cosI > 0 then etaT, etaI = etaI, ior end
            
            local sinT = etaI / etaT * math_sqrt(math_max(0, 1 - cosI*cosI))
            
            if sinT >= 1 then
                kr = 1
            else
                local cosT = math_sqrt(math_max(0, 1 - sinT*sinT))
                cosI = math_abs(cosI)
                local Rs = ((etaT * cosI) - (etaI * cosT)) / ((etaT * cosI) + (etaI * cosT))
                local Rp = ((etaI * cosI) - (etaT * cosT)) / ((etaI * cosI) + (etaT * cosT))
                kr = (Rs*Rs + Rp*Rp) * 0.5
            end
            
            return kr
        end
        
        function round(var, decimals)
            if var == nil then
                return nil
            end
            local type = type(var)
            if type == "Vector" then
                return Vector(math_round(var[1], decimals), math_round(var[2], decimals), math_round(var[3], decimals))
            elseif type == "number" then
                return math_round(var, decimals)
            elseif type == "color" then
                return Color(math_round(var[1], decimals), math_round(var[2], decimals), math_round(var[3], decimals), math_round(var[4], decimals))
            end
            return "Rounding error"
        end
        
        function traceWater(trc, ignore, start, dir, stop, dist, bounces, waterEnt)
            if ignore == nil then
                ignore = players
                --ignore = {}
            end
            local reflectiveness = 0.5
            local distDenom = 1000
            local color = Vector(138, 159, 166)
            local normal = worldGetColor("water_normals", trc.HitPos / 2, trc.HitNormal, start, stop, dist, nil, true)
            normal = normal - Vector(127.5)
            normal[3] = math_max(normal[3], 0)
            normal:normalize()
            local reflectColor, reflectPos, reflectDist = ray(stop, (dir - 2 * normal:dot(dir) * normal):getNormalized(), nil, bounces, true)
            local shadow = 1
            local shadowColor = Vector()
            
            local n1 = 1
            local n2 = 1.333
            local n = n1 / n2
            local c1 = -normal:dot(dir)
            local c2 = math_sqrt(1 - n^2 * (1 - c1^2))
            local refractDir = n * dir + (n * c1 - c2) * normal
            refractDir:normalize()
            
            local refractColor = Vector()
            local refractPos, refractDist
            local ior = 1.333
            
            local dot = dir:dot(normal)
            local kr = fresnel(dir, normal, ior)
            
            local refractColor = Vector(), refractPos, refractDist
            
            if kr < 1 then
                local cosi = dot
                local etai = 1
                local etat = 1.333
                local n = normal
                if cosi < 0 then
                    cosi = -cosi
                else
                    local temp = etai
                    etai = etat
                    etat = temp
                    n = -normal
                end
                local eta = etai / etat
                local k = 1 - eta^2 * (1 - cosi^2)
                local rayColor, rayPos, rayDist
                refractDir = eta * dir + (eta * cosi - math_sqrt(k)) * n
                refractDir:normalize()
                refractColor, refractPos, refractDist = ray(stop, refractDir, ignore, bounces, true, waterEnt)
            end
            
            color = reflectColor*kr + refractColor*(1 - kr)
            
            if drawShadows then
                shadowColor, shadow = skyRay(stop, nil, bounces)
                color = color * (shadow * shadowStrength * 0.25 + 1 - shadowStrength * 0.25) + shadowColor * shadow * 0.25
            end
            
            local dot = normal:dot(sunDir)
            color = color * math_max((dot + 1)/2 * 0.25 + 0.75, 0)
            if dot > 0 then
                local reflectDir = -sunDir - 2 * normal:dot(-sunDir) * normal
                local specAngle = math_max(reflectDir:dot(-dir), 0)
                specular = specAngle ^ 5
                color = color + specular * sunColor * 40 * shadow
            end
            color = Vector(math_clamp(color[1], 0, 255), math_clamp(color[2], 0, 255), math_clamp(color[3], 0, 255))
            return color
        end
        
        local function raySphereIntersection(pos, radius, start, delta)
            local localOrig = start - pos
            local a = delta:dot(delta)
            local b = 2 * localOrig:dot(delta)
            local c = localOrig:dot(localOrig) - radius^2
            local discriminant = b^2 - 4*a*c
            if discriminant < 0 then return nil end
            local a2 = a * 2
            local disc = math_sqrt(discriminant)
            local t1 = (-b - disc) / a2
            local t2 = (-b + disc) / a2
            local t
            if t1 < 0 and t2 < 0 then return nil end
            if t1 < 0 then t = t2
            elseif t2 < 0 then t = t1
            else t = math_min(t1, t2) end
            return start + t * delta
        end
        
        local rayIndex = 0
        local waterTextures = {
            --["NATURE/BLENDTOXICTOXIC004A"] = true,
            ["maps/gm_bigcity67d3/building_template/toxicslime002az_-7808_-5952_-10816"] = true,
            ["maps/gm_construct_m3_259/metastruct_2/water_4953_-5701_-13126"] = true,
            ["models/shadertest/predator"] = true,
            ["models/shadertest/shader3"] = true,
            ["maps/gm_construct_m3_259/metastruct_2/water_4953_-5701_-13126"] = true,
            ["maps/gm_construct_m3_261/metastruct_2/water_4953_-5701_-13126"] = true
        }
        
        local function reflect(dir, normal)
            local reflectDir = dir - 2 * normal:dot(dir) * normal
            reflectDir:normalize()
            return reflectDir
        end
        
        function skyRay(start, hitNormal, shadow, bounces)
            rayIndex = rayIndex + 1
            myIndex = rayIndex
            shadow = shadow or 1
            if bounces then
                bounces = bounces + 1
                if bounces > maxBounces then
                    return Vector(0,0,0), 1
                end
            else
                bounces = 1
            end
            local color = Vector(0,0,0)
            local delta = sunDir * traceLength
            --local trc = vistrace.traverseScene(start + hitNormal*0.01, sunDir, 0, 1000000, hitWorld)
            local trc = accel:traverse(start + hitNormal*0.01, sunDir, 0, 1000000)
            local ent = trc.Entity
            local hitEnt = ent and ent:isValid()
            local texture
            local entCol
            if hitEnt then
                texture = ent:getMaterial()
                if texture == "" then
                    texture = ent:getMaterials()[trc.SubmatIndex + 1]
                end
                entCol = ent:getColor()
                if texture then
                    if (trc.HitNormal:dot(sunDir) >= 0 and bit_band(material_getInt(texture, "$flags"), 8192) == 0) or entCol[4] == 0 then
                        -- Cull
                        return skyRay(trc.HitPos + (sunDir - hitNormal) * 0.01, hitNormal, shadow, bounces - 1)
                    end
                end
            else
                texture = trc.HitTexture
            end
            local drawSky = trc.HitSky or not trc.Hit
            local dist = trc.Fraction * traceLength
            local pos = trc.HitPos
            rays[myIndex] = {start = start, stop = pos, sky = true, shadow = shadow}
            if not drawSky then
                --[[if true then
                    rays[myIndex].shadow = 0
                    return Vector(0,0,0), 0
                end]]
                if hitEnt then
                    --[[local sphereData = spheres[trc.Entity:getModel()]
                    if sphereData != nil then
                        local center = trc.Entity:obbCenterW()
                        pos = raySphereIntersection(center, sphereData[1] - 0.1, start, delta)
                        if pos == nil then
                            rays[myIndex] = nil
                            local newIgnore = table.copy(ignore)
                            table_insert(newIgnore, trc.Entity)
                            color, shadow = skyRay(start, newIgnore, shadow, bounces)
                            return color, shadow
                        end
                        normal = pos - center
                        normal:normalize()
                        rays[myIndex].stop = pos
                    end]]
                    
                    local hitShader = trc.HitShader
                    local alphaMult
                    if not hitShader or manualTextures[texture] then
                        local nextColor, alpha = getPixel(texture, trc.HitTexCoord.u, trc.HitTexCoord.v)
                        color = nextColor * Vector(entCol[1], entCol[2], entCol[3]) / 255
                        alphaMult = alpha * entCol[4] / 65025
                    else
                        nextColor = hitShader.Albedo
                        color = nextColor
                        alphaMult = hitShader.Alpha
                    end
                    --color, alpha = getColor(trc.Entity, pos, normal, start, start + delta, dist, sphereData)
                    local i = shadow
                    shadow = shadow * (1 - alphaMult)
                    if shadow <= 0 then
                        rays[myIndex].shadow = 0
                        return Vector(0,0,0), 0
                    else
                        rays[myIndex].shadow = shadow
                        local nextColor, nextShadow = skyRay(pos + (sunDir - hitNormal) * 0.01, hitNormal, shadow, bounces)
                        if nextColor == Vector(0,0,0) then
                            return color, nextShadow
                        else
                            --print(alphaMult, nextColor, color, nextShadow)
                            return math_lerpVector(alphaMult, nextColor, color), nextShadow
                            --return color, shadow
                        end
                    end
                else
                    rays[myIndex].shadow = 0
                    return Vector(0,0,0), 0
                end
            end
            rays[myIndex].shadow = shadow
            return color, shadow
        end
        
        --[[local function makeArrow(pos, dir)
            holograms.create(pos + dir * 3, dir:getAngle(), "models/holograms/cube.mdl", Vector(0.5, 0.01, 0.01))
        end
        
        local arrowQueue = {}
        hook.add("think", "make arrows", function()
            for _, t in ipairs(arrowQueue) do
                makeArrow(t[1], t[2])
            end
            arrowQueue = {}
        end)]]
        
        --local upTrace = vistrace.traverseScene(
        
        local rainUp = math.cos(22.5 * math_pi/180)
        local rainMult = 0.3 * 1 / (1 - rainUp)
        local floor = math_floor
        local dropDensity = 48
        local idropDensity = 1/dropDensity
        local sqrt = math_sqrt
        local dropCutOff = 9.87^2
        local sin = math.sin
        local cos = math.cos
        local pi = math_pi
        local sharedRandom = math.sharedRandom
        local round = math_round
        local dropDenom = 1 / (2 * pi)
        
        local dropCache = {}
        local dropCacheOrder = {}
        local dropCacheSize = 500
        local dropCacheIndex = 1
        local maxRand = 1 / 4294967295

        local function randNumber(x)
            x = bit.bxor(x, bit_lshift(x, 13))
            x = bit.bxor(x, bit_rshift(x, 17))
            x = bit.bxor(x, bit_lshift(x, 5))
            return x * maxRand
        end
        
        local function randNumber2(x)
            x = bit.bxor(x, bit_lshift(x, 13))
            x = bit.bxor(x, bit_rshift(x, 17))
            x = bit.bxor(x, bit_lshift(x, 5))
            x = bit.bxor(x, bit_lshift(x, 13))
            x = bit.bxor(x, bit_rshift(x, 17))
            x = bit.bxor(x, bit_lshift(x, 5))
            return x * maxRand
        end
        
        local floor = math_floor
        
        local function randCoord(x, y, seed)
            seed = seed or 192837
            x = x * seed
            y = y * seed
            local result = sin(x * 12.9898 + y * 78.233) * 43758.5453
            result = result % 1
            return result
        end
        
        function getRand(str, min, max, state)
            local cache = dropCache[str]
            if cache == nil then
                --local result = sharedRandom(str, min, max, seed)
                local result = randNumber(state) * (max - min) + min
                if #dropCacheOrder >= dropCacheSize then
                    dropCache[dropCacheOrder[dropCacheIndex]] = result
                    dropCacheOrder[dropCacheIndex] = str
                    dropCacheIndex = dropCacheIndex + 1
                    if dropCacheIndex > dropCacheSize then
                        dropCacheIndex = 1
                    end
                else
                    table_insert(dropCacheOrder, str)
                    dropCache[str] = result
                end
                return result
            end
            return cache
        end
        
        function getDropNormal(x, y)
            local xi = floor(x * idropDensity)
            local yi = floor(y * idropDensity)
            local x2 = xi * dropDensity - x
            local y2 = yi * dropDensity - y
            local closestx
            local closesty
            local closestDist = math.huge
            --[[local strings = {
                xi-1 .. "," .. yi-1,
                xi-1 .. "," .. yi,
                xi-1 .. "," .. yi+1,
                xi .. "," .. yi-1,
                xi .. "," .. yi,
                xi .. "," .. yi+1,
                xi+1 .. "," .. yi-1,
                xi+1 .. "," .. yi,
                xi+1 .. "," .. yi+1
            }
            
            local cells = {
                getRand(strings[1] .. "x", 0, dropDensity, 123456789) - dropDensity,
                getRand(strings[1] .. "y", 0, dropDensity, 987654321) - dropDensity,
                getRand(strings[2] .. "x", 0, dropDensity, 123456789) - dropDensity,
                getRand(strings[2] .. "y", 0, dropDensity, 987654321),
                getRand(strings[3] .. "x", 0, dropDensity, 123456789) - dropDensity,
                getRand(strings[3] .. "y", 0, dropDensity, 987654321) + dropDensity,
                getRand(strings[4] .. "x", 0, dropDensity, 123456789),
                getRand(strings[4] .. "y", 0, dropDensity, 987654321) - dropDensity,
                getRand(strings[5] .. "x", 0, dropDensity, 123456789),
                getRand(strings[5] .. "y", 0, dropDensity, 987654321),
                getRand(strings[6] .. "x", 0, dropDensity, 123456789),
                getRand(strings[6] .. "y", 0, dropDensity, 987654321) + dropDensity,
                getRand(strings[7] .. "x", 0, dropDensity, 123456789) + dropDensity,
                getRand(strings[7] .. "y", 0, dropDensity, 987654321) - dropDensity,
                getRand(strings[8] .. "x", 0, dropDensity, 123456789) + dropDensity,
                getRand(strings[8] .. "y", 0, dropDensity, 987654321),
                getRand(strings[9] .. "x", 0, dropDensity, 123456789) + dropDensity,
                getRand(strings[9] .. "y", 0, dropDensity, 987654321) + dropDensity
            }]]
            
            local cells = {
                (randCoord(xi-1, yi-1, 1234) - 1) * dropDensity,
                (randCoord(xi-1, yi-1, 4321) - 1) * dropDensity,
                randCoord(xi-1, yi-1, 9865),
                
                (randCoord(xi-1, yi, 1234) - 1) * dropDensity,
                randCoord(xi-1, yi, 4321) * dropDensity,
                randCoord(xi-1, yi, 9865),
                
                (randCoord(xi-1, yi+1, 1234) - 1) * dropDensity,
                (randCoord(xi-1, yi+1, 4321) + 1) * dropDensity,
                randCoord(xi-1, yi+1, 9865),
                
                randCoord(xi, yi-1, 1234) * dropDensity,
                (randCoord(xi, yi-1, 4321) - 1) * dropDensity,
                randCoord(xi, yi-1, 9865),
                
                randCoord(xi, yi, 1234) * dropDensity,
                randCoord(xi, yi, 4321) * dropDensity,
                randCoord(xi, yi, 9865),
                
                randCoord(xi, yi+1, 1234) * dropDensity,
                (randCoord(xi, yi+1, 4321) + 1) * dropDensity,
                randCoord(xi, yi+1, 9865),
                
                (randCoord(xi+1, yi-1, 1234) + 1) * dropDensity,
                (randCoord(xi+1, yi-1, 4321) - 1) * dropDensity,
                randCoord(xi+1, yi-1, 9865),
                
                (randCoord(xi+1, yi, 1234) + 1) * dropDensity,
                randCoord(xi+1, yi, 4321) * dropDensity,
                randCoord(xi+1, yi, 9865),
                
                (randCoord(xi+1, yi+1, 1234) + 1) * dropDensity,
                (randCoord(xi+1, yi+1, 4321) + 1) * dropDensity,
                randCoord(xi+1, yi+1, 9865)
            }
            
            local count = 0
            local normal = Vector()
            for i = 1, 9 do
                local posx = cells[i * 3 - 2] + x2
                local posy = cells[i * 3 - 1] + y2
                --local shift = getRand(strings[i] .. "p", 0, 9.87, 5647382910)
                local shift = cells[i * 3] * 9.87
                local maxDist = 9.87 + shift * 2
                --local maxDist = shift
                local dist = posx * posx + posy * posy
                --dropCutOff
                if dist <= maxDist * maxDist then
                    dist = sqrt(dist)
                    local idist = 1 / dist
                    --local power = round(getRand(strings[i] .. "p", 1.6, 2.4, 5647382910))
                    /*local power = -2
                    local mult = sin(dist + power * pi) / ((dist + pi) * 4)^power
                    if power <= 0 then 
                        power = power - 1
                        mult = mult * dist * dropDenom * (power - pi)^power
                    end
                    local nx = posx * mult * idist
                    local ny = posy * mult * idist
                    normal = normal + Vector(nx, ny, 1):getNormalized()
                    count = count + 1*/
                    local mult = cos(dist) * cos((dist - shift) * dropDenom)
                    local nx = posx * mult * idist
                    local ny = posy * mult * idist
                    normal = normal + Vector(nx, ny, 2):getNormalized()
                    count = count + 1
                end
                --[[if dist < closestDist then
                    closestDist = dist
                    closestx = posx
                    closesty = posy
                end]]
            end
            if count == 0 then
                return Vector(0,0,1)
            end
            --normal:normalize()
            --[[if closestDist > dropCutOff then
                return Vector(0,0,1)
            end
            closestDist = sqrt(closestDist)
            local iclosestDist = 1 / closestDist
            local mult = sin(closestDist) / ((closestDist + pi) * 4)
            --local mult = 1
            local nx = closestx * mult
            local ny = closesty * mult
            --nx * nx + ny * ny
            --local normal = Vector(nx, ny, dropDensity)
            local normal = Vector(nx, ny, 0.75)
            normal:normalize()]]
            return normal / count
        end
        
        local l255 = Vector(255):getLength()
        function lightRay(start, dir, bounces, maxDist, lightColor, shadow)
            --{rgb, brightness, radiusSqr, pos, ent}
            bounces = bounces+1
            if bounces > maxBounces or maxDist <= 0 then return lightColor, shadow end
            while quotaAverage() >= maxCPU do
                coroutine.yield()
            end
            rayIndex = rayIndex + 1
            myIndex = rayIndex
            local trc = accel:traverse(start, dir, 0, maxDist)
            if not trc.Hit then
                local pos = trc.HitPos
                maxDist = maxDist - trc.Fraction * maxDist - 0.01
                rays[myIndex] = {start = start, stop = pos, light = true, rgb = lightColor}
                return lightColor, shadow
            end
            local ent = trc.Entity
            local hitEnt = ent and ent:isValid()
            if hitEnt then
                texture = ent:getMaterial()
                if texture == "" then
                    texture = ent:getMaterials()[trc.SubmatIndex + 1]
                end
                local entCol = ent:getColor()
                local alpha = entCol[4]
                
                if (trc.HitNormal:dot(dir) >= 0 and bit_band(material_getInt(texture, "$flags"), 8192) == 0) or alpha == 0 then
                    -- Cull
                    local pos = trc.HitPos
                    maxDist = maxDist - trc.Fraction * maxDist - 0.01
                    rays[myIndex] = {start = start, stop = pos, light = true, rgb = lightColor}
                    return lightRay(pos + dir * 0.01, dir, bounces-1, maxDist, lightColor, shadow)
                end
                
                -- Hit ent
                local entColV = Vector(entCol[1], entCol[2], entCol[3])
                local tcolor, talpha-- = getPixel(texture, trc.HitTexCoord.u, trc.HitTexCoord.v)
                local hitShader = trc.HitShader
                if hitShader then
                    tcolor = hitShader.Albedo * 255
                    talpha = hitShader.Alpha * 255
                else
                    tcolor, baseAlpha = getPixel(texture or "", trc.HitTexCoord.u, trc.HitTexCoord.v)
                    tcolor = color * entColV / 255
                    talpha = baseAlpha * entCol[4] / 255
                end
                alpha = alpha * talpha / 255
                if alpha > 254.5 then
                    local pos = trc.HitPos
                    maxDist = maxDist - trc.Fraction * maxDist - 0.01
                    rays[myIndex] = {start = start, stop = pos, light = true, rgb = Vector()}
                    return Vector(), 0
                end
                if alpha < 0.5 then
                    local pos = trc.HitPos
                    maxDist = maxDist - trc.Fraction * maxDist - 0.01
                    rays[myIndex] = {start = start, stop = pos, light = true, rgb = lightColor}
                    return lightRay(pos + dir * 0.01, dir, bounces, maxDist, lightColor, shadow)
                end
                
                entColV = entColV * tcolor / 255
                --local alpha1 = 1 - alpha / 255
                local alpha1 = alpha / 255
                --lightColor = lightColor * alpha1 + entColV
                
                --lightColor = alpha1 * (lightColor + alpha1 * entColV)
                --lightColor = math_lerpVector(alpha1, lightColor * alpha1, alpha1 * alpha1 * entColV)
                lightColor = math_lerpVector(alpha / 255, lightColor, entColV * lightColor:getLength() / l255)
                shadow = shadow * (1 - alpha1)
                
                local pos = trc.HitPos
                maxDist = maxDist - trc.Fraction * maxDist - 0.01
                rays[myIndex] = {start = start, stop = pos, light = true, rgb = lightColor}
                return lightRay(pos + dir * 0.01, dir, bounces, maxDist, lightColor, shadow)
            else
                -- Hit worlrd
                local pos = trc.HitPos
                maxDist = maxDist - trc.Fraction * maxDist - 0.01
                rays[myIndex] = {start = start, stop = pos, light = true, rgb = Vector()}
                return Vector(), 0
            end
        end
        
        local l255 = Vector(255):getLength()
        local il255 = 1 / l255
        
        --ray(start, dir, ignore, bounces, ignoreWater, shadowIgnore, windowReflection, dist)
        function ray(start, dir, bounces, ignoreWater, windowReflection, dist)
            rayIndex = rayIndex + 1
            myIndex = rayIndex
            dist = dist or 0
            if bounces then
                bounces = bounces + 1
                if bounces > maxBounces then
                    return Vector(255), start, 1
                end
            else
                bounces = 1
            end
            --local delta = dir * traceLength
            --local rayEnd = start + delta
            --[[local mask
            if ignoreWater ~= true then
                mask = bit.bor(MASK.WATER, MASK.SHOT)
            end]]

            local trc = accel:traverse(start, dir, 0, 1000000.01)
            local ent = trc:Entity()
            local hitEnt = ent and ent:isValid()
            local geomnormal = trc.HitNormalGeometric
            print(geomnormal)
            print(trc:HitNormalGeometric())
            local normal = trc.HitNormal
            local entCol
            local texture
            local matFlags = 0
            local pos = trc.HitPos
            local shadowStart = trc.HitPos
            local sunDotNormal = normal
            if hitEnt then
                texture = ent:getMaterial()
                if texture == "" then
                    texture = ent:getMaterials()[trc.SubmatIndex + 1]
                end
                entCol = ent:getColor()
                local dot = normal:dot(dir)
                if texture then
                    matFlags = material_getInt(texture, "$flags")
                    if (dot >= 0 and bit_band(matFlags, 8192) == 0) or entCol[4] == 0 then
                        -- Cull
                        return ray(trc.HitPos + dir * 0.01, dir, bounces-1, ignoreWater, windowReflection, dist + trc.Fraction * 1000000 + 0.01)
                    end
                    if dot > 0 then
                        shadowStart = shadowStart + geomnormal * 0.02
                        normal = -normal
                        geomnormal = -geomnormal
                    end
                end
            else
                texture = trc.HitTexture
            end
            local notFullbright = texture != "lights/white001"
            --[[while hitEnt and trc.HitNormalGeometric:dot(dir) > 0 do
                dist = dist + trc.Fraction * 1000000
                start = trc.HitPos
                trc = vistrace.traverseScene(start, dir, 0.1, 1000000.1, hitWorld)
                hitEnt = trc.Entity and trc.Entity:isValid()
                while quotaAverage() >= maxCPU do coroutine.yield() end
            end]]
            --[[local ent
            if hitEnt then*
                ent = props[trc.Entity:entIndex()]
            end]]
            dist = dist + trc.Fraction * 1000000
            local color = Vector(0,0,0)
            local alpha
            local dot = 1
            local shadow = 1
            local shadowColor
            rays[myIndex] = {start = start, stop = pos, sky = false}
            
            --[[if ignoreWater ~= true and waterTextures[texture] then
                local waterIgnore = table.copy(ignore)
                if hitEnt then
                    table_insert(waterIgnore, trc.Entity)
                end
                color = traceWater(trc, waterIgnore, start, dir, pos, dist, bounces, trc.Entity)
                return color, pos, dist
            end]]
            
            local phongColor = Vector(0,0,0)
            local lightColor, lightData, cum_shadow = Vector(), {}, 0
            
            if hitEnt then
                local entColV = Vector(entCol[1], entCol[2], entCol[3])
                
                local u, v = trc.HitTexCoord.u, trc.HitTexCoord.v
                local normalmap, normalAlpha, baseAlpha
                --HIT ENTITY
                --[[local sphereData = spheres[trc.Entity:getModel()]
                if sphereData != nil then
                    local center = trc.Entity:obbCenterW()
                    pos = raySphereIntersection(center, sphereData[1], start, delta)
                    if pos == nil then
                        rays[myIndex] = nil
                        color, pos, dist = ray(start, dir, bounces, nil, windowReflection)
                        return color, pos, dist
                    end
                    rays[myIndex].stop = pos
                    normal = pos - center
                    normal:normalize()
                end]]
                --if trc.Entity:getMaterial() == "debug/env_cubemap_model" then
                if texture == "debug/env_cubemap_model" then
                    --Mirror
                    if drawShadows then
                        shadowColor, shadow = skyRay(shadowStart, geomnormal, nil, bounces)
                    end
                    local reflectDir = dir - 2 * normal:dot(dir) * normal
                    local reflectColor = ray(pos + reflectDir * 0.01, reflectDir, bounces, nil, windowReflection, dist)
                    color = math_lerpVector(0.9, 0.501960784 * entColV * sunColor, reflectColor)
                    --color = Vector(128) + (reflectColor - Vector(128)) * 0.9
                    --alpha = trc.Entity:getColor()[4]
                    alpha = entCol[4]
                elseif texture == "models/player/shared/gold_player" then
                    --Gold
                    if drawShadows then
                        shadowColor, shadow = skyRay(shadowStart, geomnormal, nil, bounces)
                    end
                    local reflectDir = dir - 2 * normal:dot(dir) * normal
                    local reflectColor = ray(pos + reflectDir * 0.01, reflectDir, bounces, nil, windowReflection, dist)
                    color = Vector(219, 164, 13)/255 * entColV * sunColor * 0.65 + reflectColor * 0.35
                    alpha = entCol[4]
            elseif texture and material_getString(texture, "$envmap") == "env_cubemap" then
                -- Reflective
                if drawShadows then
                    shadowColor, shadow = skyRay(shadowStart, geomnormal, nil, bounces)
                end
                
                if bit_band(matFlags, 0x100000) == 0x100000 then
                    color, baseAlpha = getPixel(texture or "", u, v)
                    color = color * entColV / 255 * sunColor
                    alpha = entCol[4]
                    
                    --if baseAlpha ~= 255 then
                        local reflectDir = dir - 2 * normal:dot(dir) * normal
                        local reflectColor = ray(pos + reflectDir * 0.01, reflectDir, bounces, nil, windowReflection, dist)
                        local tint = material_getVector(texture, "$envmaptint")
                        if tint then
                            reflectColor = reflectColor * tint
                        end
                        color = math_lerpVector(1 - baseAlpha / 280.5, color, entColV / 255 * sunColor * reflectColor)
                    --end
                else
                    local reflectDir = dir - 2 * normal:dot(dir) * normal
                    local reflectColor = ray(pos + reflectDir * 0.01, reflectDir, bounces, nil, windowReflection, dist)
                    local tint = material_getVector(texture, "$envmaptint")
                    if tint then
                        reflectColor = reflectColor * tint
                    end
                    local hitShader = trc.HitShader
                    if hitShader and not manualTextures[texture] then
                        color = hitShader.Albedo * 255 * sunColor
                        alpha = hitShader.Alpha * 255
                    else
                        color, baseAlpha = getPixel(texture or "", u, v)
                        color = color * entColV / 255 * sunColor
                        alpha = baseAlpha * entCol[4] / 255
                    end
                    color = (color + (entColV / 255 * sunColor * reflectColor)) * 0.5
                end
            else
                    --[[local u, v, tangent, binormal
                    color, alpha, u, v, tangent, binormal = getColor(trc.Entity, pos, normal, start, start + delta, dist, sphereData)]]
                    --getPixel(mat, u, v, dist, useThisMat, noSmoothing, xyNotuv)
                    --print(trc.Entity)
                    
                    local hitShader = trc.HitShader
                    if hitShader and not manualTextures[texture] then
                        color = hitShader.Albedo * 255 * sunColor
                        alpha = hitShader.Alpha * 255
                    else
                        color, baseAlpha = getPixel(texture or "", u, v)
                        color = color * entColV / 255 * sunColor
                        alpha = baseAlpha * entCol[4] / 255
                    end
                    
                    if alpha < 0.5 then
                        return ray(pos + dir * 0.01, dir, bounces-1, nil, windowReflection, dist)
                    end
                    if drawShadows and notFullbright then
                        shadowColor, shadow = skyRay(shadowStart+geomnormal*0.01, geomnormal, nil, bounces)
                    end
                    
                    --color = color * sunColor
                    --normal = getNormalMap(texture, u, v, normal, trc.HitTangent, trc.HitBinormal, ent)
                    
                    -- Normal map
                    --[[if texture then
                        normalmap = material_getTexture(texture, "$bumpmap")
                        if normalmap ~= "error" and normalmap ~= "null-bumpmap" then
                            local tangent, binormal = trc.HitTangent, trc.HitBinormal
                            local normal2
                            normal2, normalAlpha = getPixel(normalmap, u, v, nil, true)
                            normal2 = normal2 / 127.5 - Vector(1)
                            local normal3 = Vector(
                                normal2[1]*tangent[1] + normal2[2]*binormal[1] + normal2[3]*normal[1],
                                normal2[1]*tangent[2] + normal2[2]*binormal[2] + normal2[3]*normal[2],
                                normal2[1]*tangent[3] + normal2[2]*binormal[3] + normal2[3]*normal[3]
                            )
                            normal3:normalize()
                            normal = normal3:dot(normal) < 0 and -normal3 or normal3
                        end
                    end]]
                    
                    --[[if normal:dot(dir) > 0 then
                        normal = -normal
                    end]]
                    --color = (normal + Vector(1)) * 127.5
                    --alpha = 255
                    dot = sunDotNormal:dot(sunDir)
                    
                    if texture == "metal4" or texture == "phoenix_storms/metal_plate" then
                        local reflectDir = dir - 2 * normal:dot(dir) * normal
                        local reflectColor = ray(pos + reflectDir * 0.01, reflectDir, bounces, nil, windowReflection, dist)
                        color = math_lerpVector(0.25, color, reflectColor)
                    elseif texture and string_find(texture, "glass", 1, true) then
                        local reflectDir = dir - 2 * normal:dot(dir) * normal
                        local reflectColor = ray(pos + reflectDir * 0.01, reflectDir, bounces, nil, windowReflection, dist)
                        color = (reflectColor + color) * 0.5
                    end
                    
                    --color = math_lerpVector(dot*0.5+0.5, Vector(255,0,255), Vector(0,255,255))
                    --alpha = 255
                    --normal = getNormalMap(mat, u, v, normal, tangent, binormal, trc.Entity)
                end
                --Normal maps
                --local normal = getNormalMap(mat, u, v, normal, tangent, binormal, trc.Entity)
                --table_insert(arrowQueue, {pos, normal})
                --[[if normalmap[3] != 1 then
                    normal = localToWorld(normalmap, Angle(), Vector(), normal:getAngle())
                end]]
                --
                if notFullbright then
                    for _, light in ipairs(lights) do
                        local pos2 = pos + geomnormal * 0.01
                        local lightDist = pos2:getDistanceSqr(light[4])
                        if lightDist <= light[3] then
                            local lightDistSqrt = math_sqrt(lightDist)
                            local lightDir = (light[4] - pos2) / lightDistSqrt
                            --local lightDistLog = math_log(lightDistSqrt, lightLog)
                            local lightColor2 = light[2] / lightDist * math_max(0, normal:dot(lightDir))
                            local lightShadow
                            lightColor2, lightShadow = lightRay(pos2, lightDir, 0, lightDistSqrt, lightColor2, 1)
                            if lightShadow ~= 0 then
                                table_insert(lightData, {lightDir, lightColor2})
                                lightColor = lightColor + lightColor2 * lightShadow
                            end
                        end
                    end
                    
                    if lightColor ~= Vector() then
                        cum_shadow = math_clamp(shadow, lightColor:getLength() * il255, 1)
                    else cum_shadow = shadow end
                    
                    if cum_shadow ~= 0 and texture then
                        --phongColor = phong(trc, texture, dir, bounces, normal, dot, shadow, nil, nil, lightData)
                        --phong(trc, mat, dir, bounces, normal, dot, shadow, color, pos, lightData, alpha)
                        -- Phong
                        local phongColor = Vector(0,0,0)
                        local phongEnabled = material_getInt(texture, "$phong")
                        if phongEnabled == 1 then
                            local reflectColor = Vector(255,255,255)
                            local phongboost = material_getInt(texture, "$phongboost")
                            local phongmat = material_getTexture(texture, "$phongexponenttexture")
                            local phongexponent
                            if phongmat then
                                if phongmat == normalmap then
                                    phongexponent = normalAlpha or material_getInt(texture, "$phongexponent")
                                else
                                    local _
                                    _, phongexponent = getPixel(phongmat, u, v, nil, true)
                                end
                            elseif bit_band(material_getInt(texture, "$flags"), 1048576) == 1048576 then
                                phongexponent = baseAlpha or material_getInt(texture, "$phongexponent")
                            else
                                phongexponent = material_getInt(texture, "$phongexponent")
                            end
                            local fresnel = material_getVector(texture, "$phongfresnelranges")
                            table_insert(lightData, {sunDir, sunColor * shadow})
                            local specular = 0
                            if dot > 0 then
                                local fresnelDot = 1 - normal:dot(dir)
                                fresnelDot = fresnelDot * fresnelDot
                                local fresnelMult
                                if fresnelDot > 0.5 then fresnelMult = math_lerp(fresnelDot*2-1, fresnel[2], fresnel[3])
                                else fresnelMult = math_lerp(fresnelDot*2, fresnel[1], fresnel[2]) end
                                local mult = phongboost * 40 * fresnelMult
                                for _, lightSet in ipairs(lightData) do
                                    local lightDir = lightSet[1]
                                    local reflectDir = -lightDir - 2 * normal:dot(-lightDir) * normal
                                    local specAngle = math_max(reflectDir:dot(-dir), 0)
                                    specular = specAngle ^ (phongexponent / 4)
                                
                                    phongColor = phongColor + specular * mult * lightSet[2]
                                end
                            end
                        end
                    end
                end
            else
                if trc.HitSky then
                    --HIT SKY
                    color, alpha = drawSky(dir)
                else
                    --HIT WORLD
                    if drawShadows then
                        --[[local shadowIgnoreT
                        if shadowIgnore then
                            shadowIgnoreT = table.copy(players)
                            table_insert(shadowIgnoreT, shadowIgnore)
                        end]]
                        shadowColor, shadow = skyRay(shadowStart, geomnormal, nil, bounces)
                    end
                    local u, v
                    if texture == "**displacement**" and displacementMat then
                        texture = displacementMat
                    end
                    color, alpha, u, v = worldGetColor(texture, pos, normal, start, start + dir*1000000, dist)
                    color = color * sunColor
                    --Normal maps
                    --normal = localToWorld(getNormalMap(trc.HitTexture, u, v), Angle(), Vector(), normal:getAngle())
                    --
                    dot = normal:dot(sunDir)
                    --[[if shadow != 0 then
                        phongColor = phong(trc, texture, dir, bounces, normal, dot, shadow)
                    end]]
                    
                    for _, light in ipairs(lights) do
                        local pos2 = pos + geomnormal * 0.01
                        local lightDist = pos2:getDistanceSqr(light[4])
                        if lightDist <= light[3] then
                            local lightDistSqrt = math_sqrt(lightDist)
                            local lightDir = (light[4] - pos2) / lightDistSqrt
                            --local lightDistLog = math_log(lightDistSqrt, lightLog)
                            --local lightColor2 = light[1] * (1 - lightDistLog / light[7]) * light[2] * (normal:dot(lightDir) + 1) * 0.5
                            local lightColor2 = light[2] / lightDist * (normal:dot(lightDir) + 1) * 0.5
                            local lightShadow
                            lightColor2, lightShadow = lightRay(pos2, lightDir, 0, lightDistSqrt, lightColor2, 1)
                            if lightShadow ~= 0 then
                                table_insert(lightData, {lightDir, lightColor2})
                                lightColor = lightColor + lightColor2 * lightShadow
                            end
                        end
                    end
                    
                    if lightColor ~= Vector() then
                        cum_shadow = math_clamp(shadow, lightColor:getLength() * il255, 1)
                    else cum_shadow = shadow end
                end
                if alpha < 255 or (color[1] == 0 and color[2] == 0 and color[3] == 0) then
                    if alpha == 255 then alpha = 0 end
                    if bounces < maxBounces and windowReflection ~= true then
                        local reflectDir = dir - 2 * normal:dot(dir) * normal
                        reflectDir:normalize()
                        local reflectColor, reflectAlpha = ray(pos + reflectDir*0.01, reflectDir, bounces, nil, true, dist)
                        reflectColor = math_lerpVector(0.5, reflectColor, windowColor)
                        color = math_lerpVector(alpha / 255, reflectColor, color)
                    else
                        color = math_lerpVector(alpha / 255, windowColor, color)
                    end
                    alpha = 255
                end
            end
            

            if not trc.HitSky and notFullbright then
                --dot = normal:dot(sunDir)
                --color = color * math_max(maxDarkening, (dot * dotStrength + 1 - dotStrength) * (shadow * shadowStrength + 1 - shadowStrength))
                color = color * (dot * dotStrength + 1 - dotStrength)
                if drawShadows then
                    --color = color * ((1 - shadow) * shadowStrength + 1 - shadowStrength) * shadowColor / 255
                    --color = color * ((1 - shadow) * shadowStrength + 1 - shadowStrength) * math_lerpVector(shadowStrength, shadowColor, Vector(255,255,255)) / 255
                    --[[color = color * (shadow * shadowStrength + 1 - shadowStrength)
                    if shadow < 1 then
                        color =  color + shadowColor * shadow
                        --color =  color + shadowColor * 0.75
                    end]]
                    if cum_shadow == 0 then
                        color = color * (1 - shadowStrength)
                    elseif cum_shadow < 1 then
                        --color = math_lerpVector(shadow, color * (shadow * shadowStrength + 1 - shadowStrength), shadow * shadow * shadowColor)
                        --color = color * (shadow * shadowStrength + 1 - shadowStrength) + shadow * shadow * shadowColor
                        local mult = cum_shadow * shadowStrength + 1 - shadowStrength
                        color = color * mult + shadowColor * sunColor * (1 - mult)
                    end
                end
                
                --{rgb, brightness, radiusSqr, pos, ent, size, log size}
                --color = color + phongColor + lightColor
                --color = color + phongColor + lightColor - Vector(math_min(lightColor[1], lightColor[2], lightColor[3]))
                color = color + phongColor + lightColor
            end
            
            --color = Vector(math_clamp(color[1], 0, 255), math_clamp(color[2], 0, 255), math_clamp(color[3], 0, 255))
            
            --if rainy and not trc.HitSky and normal[3] > rainUp then
            if rainy then
                if not trc.HitSky and normal[3] > 0 then
                    local rainDir
                    if hitEnt or normal[3] < rainUp then
                        rainDir = dir - 2 * normal:dot(dir) * normal
                    else
                        local rainNormal = getDropNormal(pos[1], pos[2])
                        if rainNormal[3] == 1 then
                            rainDir = dir - 2 * normal:dot(dir) * normal
                        else
                            rainDir = dir - 2 * rainNormal:dot(dir) * rainNormal
                        end
                        --local rainColor = ray(pos, rainDir, newIgnore, bounces, nil, nil, windowReflection, dist)
                        --color = color + (rainColor - color) * (normal[3] - rainUp) * rainMult
                        --color = Vector(rainNormal[1
                    end
                    --color = (rainNormal + Vector(1,1,1)) * 127.5
                    --color = rainNormal * 127.5 + Vector(127.5)
                    local rainColor = ray(pos, rainDir, bounces, nil, windowReflection, dist)
                    --color = color + (rainColor - color) * (normal[3] - rainUp) * rainMult
                    color = color + (rainColor - color) * (normal[3] * 0.75 + 0.25) * 0.25
                end
                
                
            end
            
            if alpha >= 255 then
                return color, pos, dist
            else
                if trc.Entity != nil and trc.Entity:isValid() then
                    if bounces < maxBounces then
                        local nextColor, pos = ray(pos + dir * 0.01, dir, bounces, nil, windowReflection, dist)
                        color = math_lerpVector(alpha / 255, nextColor, color)
                        return color, pos, dist
                    else
                        return color, pos, dist
                    end
                else
                    return color, pos, dist
                end
            end
        end
        
        file.createDir("textures")
        
        local stop = false
        local running = false
        
        local curx = 0
        local cury = 0
        
        local function save()
            print("Saving...")
            file.createDir("renders")
            local index = 281
            while file.exists("renders/render_" .. index .. ".txt") do
                index = index + 1
            end
            local path = "renders/render_" .. index .. ".txt"
            print("Writing to " .. path)
            file_write(path, res.x .. "x" .. res.y .. ":")
            local line = ""
            local saveCor = coroutine.wrap(function()
                for _, row in ipairs(renderData) do
                    for _, pixel in ipairs(row) do
                        line = line .. string_char(pixel[1], pixel[2], pixel[3])
                    end
                    file_append(path, line)
                    line = ""
                    while quotaAverage() >= maxCPU do coroutine.yield() end
                end
                return true
            end)
            hook.add("think", "save trace", function()
                if saveCor() == true then
                    print("Saved")
                    hook.remove("think", "save trace")
                end
            end)
        end
        
        local function endFunc()
            print("Rendered in " .. timer.systime() - startTime .. " seconds")
            --holo:setNoDraw(true)
            removeHolos()
            rays = {}
            print("Finished")
            running = false
            hook.remove("renderoffscreen", "tracer")
            hook.remove("think", "tracer ease quota")
            net.start("status")
            net.writeBool(false)
            net.send()
            save()
        end
        
        local rainZSeed, rainPosSeed, rainShiftSeed, rainMinZ, rainMaxZ
        local v1275 = Vector(127.5)
        local main = coroutine.wrap(function()
            while not running do
                coroutine.yield()
            end
            stop = false
            while true do
                while quotaAverage() >= maxCPU do coroutine.yield() end
                for y = 0, res.y - 1 do
                    cury = y
                    newLine(y)
                    for x = 0, res.x - 1 do
                        curx = x
                        while quotaAverage() > maxCPU do coroutine.yield() end
                        rays = {}
                        rayIndex = 1
                        
                        local rayDir = localToWorld(Vector(rayDirPre[1], rayDirPre[2] - x, rayDirPre[3] - y), Angle(0,0,0), Vector(0,0,0), traceAngle):getNormalized()
                        local color, pos, dist = ray(traceOrigin, rayDir)
                        
                        if rainy then
                            local rain_y = math_floor(y * pixelSize * 0.03)
                            local rain_x = math_floor(x * pixelSize * 0.5)
                            rain_y = randCoord(rain_x, rain_y, rainShiftSeed) * 33.333333333333 - 16.666666666667 + rain_y
                            local drawRain = randCoord(rain_x, rain_y, rainZSeed) > 0.95
                            if drawRain then
                                local rainDist = randCoord(rain_x, rain_y, rainPosSeed) * 500
                                if rainDist < dist then
                                    local rainPos = traceOrigin + rayDir * rainDist
                                    local rainDir = (rayDir + Vector(math.rand(-0.25, 0.25), math.rand(-0.25, 0.25), math.rand(-0.25, 0.25))):getNormalized()
                                    color = color + (ray(rainPos, rainDir) - color) * 0.25
                                    --color = color + (Vector(180) - color) * 0.25
                                end
                            end
                        end
                                
                        
                        finalHitPos = pos
                        --local color = Color(color[1], color[2], color[3], 255)
                        --render.setColor(color)
                        color = (color - v1275) * contrast + v1275
                        color[1] = math_clamp(color[1], 0, 255)
                        color[2] = math_clamp(color[2], 0, 255)
                        color[3] = math_clamp(color[3], 0, 255)
                        render.setRGBA(color[1], color[2], color[3], 255)
                        render.drawRect(x * pixelSize, y * pixelSize, pixelSize, pixelSize)
                        
                        if #lines ~= 0 then
                            table_insert(lines[#lines].data, color)
                        end
                        
                        if stop then
                            break
                        end
                    end
                    if stop then
                        table_remove(lines)
                        break
                    else
                        table_insert(renderData, lines[#lines])
                        lines[#lines].done = true
                    end
                end
                --[[net.start("status")
                net.writeBool(false)
                net.send()]]
                if stop then
                    stop = false
                    net.start("status")
                    net.writeBool(false)
                    net.send()
                else
                    --
                    --[[local maxx = math_min(targetRes.x, maxResBuildUp)
                    local maxy = math_min(targetRes.y, maxResBuildUp)
                    if res.x >= targetRes.x and res.y >= targetRes.y then
                        endFunc()
                    else
                        if res.x >= maxx and res.y >= maxy then
                            res.x = targetRes.x
                            res.y = targetRes.y
                        else
                            if res.x < maxx then
                                res.x = math_min(res.x * 2, maxx)
                            end
                            if res.y < maxy then
                                res.y = math_min(res.y * 2, maxy)
                            end
                        end
                        calcPixelSize()
                        rayDirPre = Vector(res.x / 2 / math.tan(fovrad / 2), res.x / 2, res.y / 2)
                        printTable(res)
                        startFunc()
                    end]]
                    --
                    endFunc()
                end
                while not running do
                    coroutine.yield()
                end
                if stop then
                    stop = false
                end
            end
            return false
        end)
        
        local sentStopMessage = false
        
        function startFunc()
            rainMinZ = traceOrigin[3] - 1000
            rainMaxZ = traceOrigin[3] + 1000
            rainZSeed = math.rand(0, 10000)
            rainPosSeed = math.rand(0, 10000)
            rainShiftSeed = math.rand(0, 10000)
            
            for _, ID in ipairs(lineNets) do
                net.cancel(ID)
            end
            lineNets = {}
            
            renderData = {}
            curx = 0
            cury = 0
            oldx = 0
            oldy = 0
            lines = {}
            net.start("clear lines")
            net.send()
            net.start("status")
            net.writeBool(true)
            net.send()
            hook.remove("renderoffscreen", "tracer")
            hook.remove("think", "tracer ease quota")
            hook.remove("think", "save trace")
            if running then
                stop = true
            else
                running = true
            end
            
            local ready = true
            maxCPU = 0
            
            --Find props
            props = {}
            --[[local findProps = coroutine.wrap(function()
                local t = find.byClass("prop_physics", function(ent) return ent:getOwner() == owner() end)
                coroutine.yield()
                while quotaAverage() > maxCPU do coroutine.yield() end
                for _, ent in ipairs(t) do
                    vistrace.rebuildAccel({ent})
                    local unyield = timer.curtime() + 5
                    while timer.curtime() < unyield or quotaAverage() > maxCPU do coroutine.yield() end
                    local origin = ent:obbCenterW()
                    local trc = vistrace.traverseScene(origin, Vector(math.rand(-1,1), math.rand(-1,1), math.rand(-1,1)), nil, nil)
                    while not trc.Entity or not trc.Entity:isValid() do
                        trc = vistrace.traverseScene(origin, Vector(math.rand(-1,1), math.rand(-1,1), math.rand(-1,1)), nil, nil)
                        while quotaAverage() > maxCPU do coroutine.yield() end
                    end
                    print(trc.Entity)
                    props[trc.Entity:entIndex()] = ent
                end
                vistrace.rebuildAccel(t)
                return true
            end)]]
            
            --vistrace.rebuildAccel(find.byClass("prop_physics", function(ent) return ent:getOwner() == owner() end))
            --local t = {}
            --{rgb, bright, radius, radius^2, pos, ent}
            net.start("find lights")
            net.send()
            net.receive("found lights", function()
                --{rgb, brightness, radiusSqr, pos, ent}
                lights = net.readTable()
                local everything = {}
                if findOwnerOnly then
                    for _, class in ipairs(hitClasses) do
                        if class == "gmod_wire_expression2" then
                            table.add(everything, find.byClass(class, function(ent)
                                if ent:getOwner() ~= owner() then return false end
                                for _, light in ipairs(lights) do
                                    if ent == light[5] then return false end
                                end
                                return true
                            end))
                        else
                            table.add(everything, find.byClass(class, function(ent)
                                return ent:getOwner() == owner()
                            end))
                        end
                    end
                else
                    for _, class in ipairs(hitClasses) do
                        if class == "gmod_wire_expression2" then
                            table.add(everything, find.byClass(class, function(ent)
                                for _, light in ipairs(lights) do
                                    if ent == light[5] then return false end
                                end
                                return true
                            end))
                        else
                            if onlyFindOwnerProps then
                                table.add(everything, find.byClass(class, function(ent) return ent:getOwner() == owner() end))
                            else
                                table.add(everything, find.byClass(class))
                            end
                        end
                    end
                end
            --local everything = find.all()
                print("Checking " .. #everything .. " entities")
            --print(#t .. " entities to trace")
            --vistrace.rebuildAccel(t)
                local checkEnts
                checkEnts = coroutine.wrap(function()
                    --local vistrace_createAccel = vistrace.rebuildAccel
                    local vistrace_createAccel = vistrace.createAccel
                    local run = true
                    while run do
                        local i = 1
                        local count = #everything
                        while i <= count do
                            try(function()
                                if everything[i]:getColor()[4] == 0 then
                                    table_remove(everything, i)
                                    count = count - 1
                                else
                                    accel = vistrace_createAccel({everything[i]})
                                    i = i + 1
                                end
                            end, function()
                                table_remove(everything, i)
                                count = count - 1
                            end)
                            while quotaAverage() > maxCPU do coroutine.yield() end
                        end
                        try(function()
                            accel = vistrace_createAccel(everything)
                            run = false
                        end, function()
                            print("Build failed. Retrying...")
                        end)
                        print("Tracing " .. #everything .. " entities")
                        if #everything == 0 then
                            accel = vistrace_createAccel({})
                            run = false
                        end
                    end
                    return true
                end)
            
                hook.add("think", "find props", function()
                --[[while quotaUsed() <= maxCPU do
                    local n = 1 + 2
                end]]
                
                    if checkEnts() == true then
                        hook.remove("think", "find props")
                        hook.add("think", "tracer ease quota", function()
                            if not running and not sentStopMessage and #lines == 0 then
                                net.start("status")
                                net.writeBool(false)
                                net.send()
                            end
                    
                            if ready then
                                print("Tracer started")
                                startTime = timer.systime()
                                --holo:setNoDraw(false)
                                hook.remove("think", "tracer ease quota")
                                hook.add("renderoffscreen", "tracer",function()
                                    render.selectRenderTarget("screen")
                                    if quotaAverage() < maxCPU then
                                        if main() == true then
                                            print("Done")
                                            endFunc()
                                        end
                                    end
                                    --if quotaAverage() >= maxCPU or minFPS > 1 / timer.frametime() then
                                        adjustCPU()
                                    --end
                                    if running and not stop then
                                        --aimHolo(holo, traceOrigin, finalHitPos)
                                        aimHolos()
                                    end
                                end)
                            end
                        end)
                    end
                end)
            end)
        end
        
        print("Tracer Commands:\nstart\nstop\nfps <number>\nres <number> <number>\nfov <number>\nshadows\nsunColor <number> <number> <number>\nsunDir <number> <number> <number>")
        
        local function startsWith(haystack, needle)
            return string_sub(haystack, 1, #needle) == needle
        end
        
        local function endsWith(haystack, needle)
            return string_sub(haystack, #haystack - #needle + 1, 1000000) == needle
        end
        
        render.createRenderTarget("screen")
        
        local gradient = material.create("UnlitGeneric")
        gradient:setTexture("$basetexture", "gui/gradient")
        
        local oldx = 0
        local oldy = 0
        
        hook.add("render","",function()
            if not capturingNewTexture then
                render.setRenderTargetTexture("screen")
                render.drawTexturedRect(0,0,512,512)
                if running then
                    local y = cury
                    local length = (cury - oldy) * res.x * 2 - oldx - 1 + curx
                    render.setRGBA(255,0,0,255)
                    render.drawRect(curx * pixelSize * 0.5, cury * pixelSize * 0.5, pixelSize * 0.5, pixelSize * 0.5)
                    render.setMaterial(gradient)
                    render.drawTexturedRect(curx * pixelSize * 0.5, (cury + 1) * pixelSize * 0.5, -length * pixelSize * 0.5, -pixelSize * 0.5)
                    if cury ~= oldy then
                        render.drawTexturedRect((oldx + length) * pixelSize * 0.5, (oldy + 1) * pixelSize * 0.5, -length * pixelSize * 0.5, -pixelSize * 0.5)
                        for i = cury - 1, oldy + 1, -1 do
                            render.drawTexturedRect((curx + length + res.x * (i - cury - 1)) * pixelSize * 0.5, (i + 1) * pixelSize * 0.5, -length * pixelSize * 0.5, -pixelSize * 0.5)
                        end
                    end
                    oldx = curx
                    oldy = cury
                end
            end
        end)
        
        calcPixelSize()
        
        -- Chat commands
        local useAlternateFuncs = string.startWith(game.getHostname(), "Meta Construct")
        addChatCommand(nil, "start", -1, true, true, function()
            if running then
                print("Restarting tracer")
            else
                print("Starting tracer")
            end
            traceOrigin = eyePos()
            traceAngle = eyeAngles()
            startFunc()
        end)
        
        addChatCommand(nil, "stop", -1, true, true, function()
            if running then
                print("Stopping tracer")
            end
            stop = true
            running = false
        end)
        
        addChatCommand(nil, useAlternateFuncs and "fpss" or "fps", -1, true, true, function(args)
            local n = tonumber(args)
            if n != nil then
                minFPS = n
                print("Target fps set to " .. minFPS)
            end
            saveSettings()
        end)
        
        addChatCommand(nil, "res", -1, true, true, function(args)
            local space = string_find(args, " ", 1, true)
            if space != nil then
                local x = tonumber(string_sub(args, 1, space - 1))
                local y = tonumber(string_sub(args, space + 1))
                if x != nil and y != nil then
                    res.x = x
                    res.y = y
                    targetRes.x = x
                    targetRes.y = y
                    --res.x = 1
                    --res.y = 1
                    calcPixelSize()
                    rayDirPre = Vector(res.x / 2 / math.tan(fovrad / 2), res.x / 2, res.y / 2)
                    if running then
                        print("Resolution set to " .. x .. "x" .. y .. "\nRestarting tracer")
                        startFunc()
                    else
                        print("Resolution set to " .. x .. "x" .. y)
                    end
                end
            end
            saveSettings()
        end)
        
        addChatCommand(nil, useAlternateFuncs and "fovv" or "fov", -1, true, true, function(args)
            local n = tonumber(args)
            if n != nil then
                fov = n
                fovrad = math.rad(fov)
                rayDirPre = Vector(res.x / 2 / math.tan(fovrad / 2), res.x / 2, res.y / 2)
                if running then
                    print("FOV set to " .. fov .. "\nRestarting tracer")
                    startFunc()
                else
                    print("FOV set to " .. fov)
                end
            end
            saveSettings()
        end)
        
        addChatCommand(nil, "retrace", -1, true, true, startFunc)
        
        addChatCommand(nil, "skyDir", -1, true, true, function(args)
            local s = "cubemap skies/" .. args .. "/"
            if file.exists("textures/" .. s) then
                skyDir = s
                saveSettings()
                print("Sky dir set to \"" .. skyDir .. "\"")
                if running then
                    print("Restarting tracer")
                    startFunc()
                end
            end
        end)
        
        addChatCommand(nil, "shadows", -1, true, true, function()
            drawShadows = not drawShadows
            if drawShadows then
                print("Enabled shadows")
            else
                print("Disabled shadows")
            end
            if running then
                print("Restarting tracer")
                startFunc()
            end
            saveSettings()
        end)
        
        addChatCommand(nil, "sunDir", -1, true, true, function(args)
            local t = string.explode(" ", args)
            try(function()
                sunDir = Vector(tonumber(t[1]), tonumber(t[2]), tonumber(t[3])):getNormalized()
                print("Sun dir set to " .. sunDir[1] .. ", " .. sunDir[2] .. ", " .. sunDir[3])
                if running then
                    print("Restarting tracer")
                    startFunc()
                end
                saveSettings()
            end)
        end)
        
        addChatCommand(nil, "sunColor", -1, true, true, function(args)
            if args == "day" then
                local c = Vector(235, 251, 255)
                sunColor = c / 255
                print("Sun color set to " .. c[1] .. ", " .. c[2] .. ", " .. c[3])
                saveSettings()
            elseif args == "night" then
                local c = Vector(80)
                sunColor = c / 255
                print("Sun color set to " .. c[1] .. ", " .. c[2] .. ", " .. c[3])
                saveSettings()
            else
                local t = string.explode(" ", args)
                try(function()
                    local c = Vector(tonumber(t[1]), tonumber(t[2]), tonumber(t[3]))
                    sunColor = c / 255
                    print("Sun color set to " .. c[1] .. ", " .. c[2] .. ", " .. c[3])
                    if running then
                        print("Restarting tracer")
                        startFunc()
                    end
                    saveSettings()
                end)
            end
        end)
        
        hook.add("think", "tracer", function()
            networkLine()
            adjustCPU()
        end)
    end
end