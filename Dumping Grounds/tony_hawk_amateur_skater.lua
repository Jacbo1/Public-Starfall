-- I want to say something might be wrong with this but I don't remember what and it might just be minor animation issues.

--@name Tony Hawk Amateur Skater
--@author Jacbo
--@shared
--@include spawn_blocking.txt
--@include safeNet.txt

local net = require("safeNet.txt")

if SERVER then
    --[[require("spawn_blocking.txt")
    corWrap(function()
    
    local scout = holograms.create(chip():getPos(), Angle(), "models/player/scout.mdl")
    
    scout:setBodygroup(1, 1) -- hat
    scout:setBodygroup(2, 1) -- headphones
    scout:setBodygroup(3, 1) -- calves
    --scout:setBodygroup(4, 1) -- dogtag
    --scout:setSubMaterial(0, "particle/warp1_warp")
    
    local board = holograms.create(chip():getPos(), Angle(), "models/workshop/player/items/scout/taunt_the_boston_boarder/taunt_the_boston_boarder.mdl")
    
    board:setParent(scout)
    board:addEffects(EF.BONEMERGE)
    
    local cosmetics = {
        --"models/player/items/scout/bit_trippers_scout.mdl",
        "models/player/items/scout/boombox.mdl",
        --"models/player/items/scout/pep_bag.mdl"
        --"models/player/items/scout/rebel_cap.mdl",
        "models/player/items/scout/scout_earbuds.mdl",
        "models/player/items/scout/summer_shades.mdl",
        --"models/workshop/player/items/all_class/brotherhood_2/brotherhood_2_scout.mdl"
        "models/workshop/player/items/all_class/cc_summer2015_the_rotation_sensation/cc_summer2015_the_rotation_sensation_scout.mdl",
        "models/workshop/player/items/all_class/fall2013_weight_room_warmer/fall2013_weight_room_warmer_scout.mdl",
        --"models/workshop/player/items/scout/fall17_jungle_jersey/fall17_jungle_jersey.mdl",
        --"models/workshop/player/items/scout/dec15_hot_heels/dec15_hot_heels.mdl",
        "models/workshop/player/items/scout/scout_gloves_leather_open/scout_gloves_leather_open.mdl",
        "models/workshop/player/items/scout/spr18_blizzard_britches/spr18_blizzard_britches.mdl"
    }
    
    local cosmeticHolos = {}
    
    for _, cosmetic in ipairs(cosmetics) do
        local holo = holograms.create(chip():getPos(), Angle(), cosmetic)
        holo:setParent(scout)
        --holo:addEffects(EF.BONEMERGE)
        table.insert(cosmeticHolos, holo)
    end
    
    net.init(function(ply)
        timer.simple(1, function()
            net.start("init")
            net.writeHologram(scout)
            net.writeHologram(board)
            net.writeUInt8(#cosmeticHolos)
            for _, holo in ipairs(cosmeticHolos) do
                net.writeHologram(holo)
            end
            net.send(ply)
        end)
    end)   
    
    local oldTime, newTime, oldPos, curPos, oldAng, curAng
    local posDelta = Vector()
    local angDelta = Angle():getQuaternion()
    local scoutPredictPos = scout:getPos()
    local scoutPredictAng = Angle():getQuaternion()
    local delayedCurPos, delayedCurAng
    local changed = false
    local vel = Vector()]]
    
    net.receive("tick", function()
        --[[delayedCurPos = net.readVector()
        delayedCurAng = net.readAngle()
        vel = net.readVector()
        onRail = net.readBool()
        changed = true
    
        net.start("tick")
        net.writeVector(delayedCurPos)
        net.writeAngle(delayedCurAng)
        net.writeVector(vel)
        net.writeBool(onRail)
        net.send()]]
    
        net.start("tick")
        net.writeVector(net.readVector())
        net.writeAngle(net.readAngle())
        net.writeVector(net.readVector())
        net.writeBool(net.readBool())
        net.send()
    end)
    
    --[[hook.add("think", "predict", function()
        if changed then
            changed = false
            oldPos = curPos
            oldAng = curAng
            oldTime = newTime
            curPos = delayedCurPos
            curAng = delayedCurAng
            newTime = timer.systime()
        
            local quat = curAng:getQuaternion()
            scoutPredictAng = quat
            scoutPredictPos = curPos
            
            if oldPos and curPos then
                local timeDelta = (newTime - oldTime)
                --posDelta = (curPos - oldPos) / timeDelta
                angDelta = (quat - oldAng:getQuaternion()) / timeDelta
            end
        end
    
        scoutPredictPos = scoutPredictPos + vel * timer.frametime()
        scoutPredictAng = scoutPredictAng + angDelta * timer.frametime()
        
        scout:setPos(scoutPredictPos)
        scout:setVel(vel)
        scout:setAngles(scoutPredictAng:getEulerAngle())
    end)
    end)]]
else -- CLIENT
    require("spawn_blocking.txt")
    corWrap(function()
    
    local user = owner()
    local scout = holograms.create(chip():getPos(), Angle(), "models/player/scout.mdl")
    
    scout:setBodygroup(1, 1) -- hat
    scout:setBodygroup(2, 1) -- headphones
    scout:setBodygroup(3, 1) -- calves
    --scout:setBodygroup(4, 1) -- dogtag
    --scout:setSubMaterial(0, "particle/warp1_warp")
    
    local board = holograms.create(chip():getPos(), Angle(), "models/workshop/player/items/scout/taunt_the_boston_boarder/taunt_the_boston_boarder.mdl")
    
    board:setParent(scout)
    board:addEffects(EF.BONEMERGE)
    
    scout:setAnimation("layer_taunt_the_boston_boarder")
    --scout:setAnimation("layer_taunt_the_boston_boarder_trickB", 0.2841, 1)
    
    local cosmetics = {
        --"models/player/items/scout/bit_trippers_scout.mdl",
        "models/player/items/scout/boombox.mdl",
        --"models/player/items/scout/pep_bag.mdl"
        --"models/player/items/scout/rebel_cap.mdl",
        "models/player/items/scout/scout_earbuds.mdl",
        "models/player/items/scout/summer_shades.mdl",
        --"models/workshop/player/items/all_class/brotherhood_2/brotherhood_2_scout.mdl"
        "models/workshop/player/items/all_class/cc_summer2015_the_rotation_sensation/cc_summer2015_the_rotation_sensation_scout.mdl",
        "models/workshop/player/items/all_class/fall2013_weight_room_warmer/fall2013_weight_room_warmer_scout.mdl",
        --"models/workshop/player/items/scout/fall17_jungle_jersey/fall17_jungle_jersey.mdl",
        --"models/workshop/player/items/scout/dec15_hot_heels/dec15_hot_heels.mdl",
        "models/workshop/player/items/scout/scout_gloves_leather_open/scout_gloves_leather_open.mdl",
        "models/workshop/player/items/scout/spr18_blizzard_britches/spr18_blizzard_britches.mdl"
    }
    
    for _, cosmetic in ipairs(cosmetics) do
        local holo = holograms.create(chip():getPos(), Angle(), cosmetic)
        holo:setParent(scout)
        holo:addEffects(EF.BONEMERGE)
    end
    
    scout:setAnimation("layer_taunt_the_boston_boarder")
    
    local targetSpeed = 400
    local targetSpeedFast = 1000
    local targetSpeedSlow = 100
    local earlyPushThreshold = 200
    local earlyPushFastThreshold = 700
    local earlyPushSlowThreshold = 50
    local pushForce = 600
    
    local flatScoutAng = Angle()
    local scoutAng = Angle()
    local targetScoutAng = Angle()
    local scoutPos = chip():getPos()
    local camAng = flatScoutAng
    local vel = Vector()
    local gravity = -physenv.getGravity()
    local hullSize = Vector(40, 40, 88.525550842284, 88.525550842284)
    local hullMin = Vector(-hullSize[1] * 0.5, -hullSize[2] * 0.5, 18)
    local hullMax = Vector(hullSize[1] * 0.5, hullSize[2] * 0.5, hullSize[3])
    local frictionMult = Vector(0.1, 0.1, 0)
    local onRail = false
    
    local anim1Duration = scout:sequenceDuration(scout:lookupSequence("layer_taunt_the_boston_boarder"))
    local anim1LerpSpeed = 1 / anim1Duration
    
    local anim2Duration = scout:sequenceDuration(scout:lookupSequence("layer_taunt_the_boston_boarder_trickB"))
    local anim2LerpSpeed = 1 / anim2Duration
    
    local anim3Duration = scout:sequenceDuration(scout:lookupSequence("layer_taunt_the_boston_boarder_trickA"))
    local anim3LerpSpeed = 1 / anim3Duration
    
    local animLerp = 0
    local animDir = 1
    
    local inAir = false
    local landing = false
    
    -- push from 0.28775 to 0.32
    
    --print(scout:sequenceDuration(scout:lookupSequence("layer_taunt_the_boston_boarder")) * 0.28775)
    
    local userClient = player() == user
    
    if not userClient then
        local oldTime, newTime, oldPos, curPos, oldAng, curAng
        local posDelta = Vector()
        local angDelta = Angle():getQuaternion()
        local scoutPredictPos = scout:getPos()
        local scoutPredictAng = Angle():getQuaternion()
        
        local delayedCurPos, delayedCurAng
        
        local changed = false
        
        net.receive("tick", function()
            delayedCurPos = net.readVector()
            delayedCurAng = net.readAngle()
            vel = net.readVector()
            onRail = net.readBool()
            changed = true
        end)
        
        hook.add("think", "predict", function()
            if changed then
                changed = false
                oldPos = curPos
                oldAng = curAng
                oldTime = newTime
                curPos = delayedCurPos
                curAng = delayedCurAng
                newTime = timer.systime()
            
                local quat = curAng:getQuaternion()
                scoutPredictAng = quat
                scoutPredictPos = curPos
                
                if oldPos and curPos then
                    local timeDelta = (newTime - oldTime)
                    --posDelta = (curPos - oldPos) / timeDelta
                    angDelta = (quat - oldAng:getQuaternion()) / timeDelta
                end
            end
        
            --scoutPredictPos = scoutPredictPos + vel * timer.frametime()
            scoutPredictAng = scoutPredictAng + angDelta * timer.frametime()
            
            --scout:setPos(scoutPredictPos)
            scout:setAngles(scoutPredictAng:getEulerAngle())
        end)
    end
    
    --if player() == user then
    local rails
    local railsCompiled = false
    local compiledRails = {}
    local railChunkSize = 256
    local maxRailDist = 40
    local minRailVelSqr = 150^2
    local railFlip = Angle()
    if userClient then
        local rails = {
            -- Meta construct
            -- Meta concrete
            --[[{Vector(927.937, 3072.031, -12527.969), Vector(1952.004, 3072.031, -12783.969)},
            {Vector(927.937, 3072.031, -12527.969), Vector(-2496.006, 3072.031, -12527.969)},
            {Vector(1952.004, 3072.031, -12783.969), Vector(15055.969, 3072.031, -12783.969)},
            {Vector(-2496.004, 3072.031, -12527.969), Vector(-3520.005, 3072.031, -12783.969)},
            {Vector(-3520.005, 3072.031, -12783.969), Vector(-3904.013, 3072.031, -12783.969)},
            {Vector(-3904.013, 3072.031, -12783.969), Vector(-4496.031, 2480.012, -12783.969)},
            {Vector(-4496.031, 2480.012, -12783.969), Vector(-4496.031, 1952.031, -12783.969)},
            {Vector(-4496.031, 1952.031, -12783.969), Vector(-6662, 1952.031, -12783.969)},
            {Vector(-6662, 1952.031, -12783.969), Vector(-8709.995, 1952.031, -13295.969)},
            
            {Vector(-6693.859, 3072.031, -12783.969), Vector(-15311.969, 3072.031, -12783.969)},
            
            {Vector(-14352.031, 208.031, -13279.969), Vector(-14352.031, -3167.969, -13279.969)},
            {Vector(-14352.031, -3167.969, -13279.969), Vector(-14879.969, -3167.969, -13279.969)},
            {Vector(-15007.969, -3175.969, -13311.969), Vector(-15007.969, -0.031, -13311.969)},
            
            {Vector(-8592.031, -10640.031, -4575.969), Vector(-8592.031, -11887.969, -4575.969)},
            {Vector(-8592.031, -11887.969, -4575.969), Vector(-9839.969, -11887.969, -4575.969)},
            {Vector(-9839.969, -11887.969, -4575.969), Vector(-9839.969, -10640.031, -4575.969)},
            {Vector(-9839.969, -10640.031, -4575.969), Vector(-8592.031, -10640.031, -4575.969)},
            
            -- Meta tower
            {Vector(-9375.969, -11136.031, -4607.969), Vector(-9375.969, -11391.969, -4607.969)},
            {Vector(-9343.969, -11423.969, -4607.969), Vector(-9088.031, -11423.969, -4607.969)},
            {Vector(-9056.031, -11391.969, -4607.969), Vector(-9056.031, -11136.031, -4607.969)},
            {Vector(-9088.031, -11104.031, -4607.969), Vector(-9343.969, -11104.031, -4607.969)},
            
            {Vector(-9838.969, -10641.031, -4383.969), Vector(-8593.031, -10641.031, -4383.969)},
            {Vector(-8593.031, -11886.969, -4383.969), Vector(-8593.031, -10641.031, -4383.969)},
            {Vector(-8593.031, -11886.969, -4383.969), Vector(-9838.969, -11886.969, -4383.969)},
            {Vector(-9838.969, -10641.031, -4383.969), Vector(-9838.969, -11886.969, -4383.969)},
            
            {Vector(-9375.969, -11104.031, -4399.969), Vector(-9056.031, -11104.031, -4399.969)},
            {Vector(-9056.031, -11423.969, -4399.969), Vector(-9056.031, -11104.031, -4399.969)},
            {Vector(-9056.031, -11423.969, -4399.969), Vector(-9375.969, -11423.969, -4399.969)},
            {Vector(-9375.969, -11104.031, -4399.969), Vector(-9375.969, -11423.969, -4399.969)},
            
            -- Bunker
            {Vector(-1343.988, -2368.009, -13095.969), Vector(-1343.994, 576.012, -13095.969)},
            {Vector(-4800.012, 576.01, -13095.969), Vector(-1343.994, 576.012, -13095.969)},
            {Vector(-4800.012, 576.01, -13095.969), Vector(-4800.009, -2368.013, -13095.969)},
            {Vector(-1343.988, -2368.01, -13095.969), Vector(-4800.009, -2368.013, -13095.969)},
            
            -- Bridge
            {Vector(3587.992, 1289, -13309.969), Vector(3663.991, 1289, -13271.969)},
            {Vector(6064.01, 1289, -13271.969), Vector(3663.991, 1289, -13271.969)},
            {Vector(6064.01, 1289, -13271.969), Vector(6140.01, 1289, -13309.969)},
            
            {Vector(6140.009, 1721, -13309.969), Vector(6064.009, 1721, -13271.969)},
            {Vector(3663.977, 1721, -13271.969), Vector(6064.009, 1721, -13271.969)},
            {Vector(3663.977, 1721, -13271.969), Vector(3588.034, 1721, -13309.969)},
            
            -- Cave building
            {Vector(10052, -140, -13026.969), Vector(10052, -900, -13026.969)},
            {Vector(11516, -900, -13026.969), Vector(10052, -900, -13026.969)},
            {Vector(11516, -900, -13026.969), Vector(11516, -140, -13026.969)},
            {Vector(10052, -140, -13026.969), Vector(11516, -140, -13026.969)},
            
            {Vector(11448.507, -263.252, -13004.874), Vector(11448.485, -356.113, -13068.063)},
            {Vector(11448.397, -715.621, -13133.354), Vector(11448.128, -808.771, -13196.032)},
            
            {Vector(10991.969, -280.031, -13169.969), Vector(10192.031, -280.031, -13169.969)},
            {Vector(10192.031, -791.969, -13169.969), Vector(10192.031, -280.031, -13169.969)},
            {Vector(10192.031, -791.969, -13169.969), Vector(10991.969, -791.969, -13169.969)},
            {Vector(10192.031, -791.969, -13169.969), Vector(10991.969, -280.031, -13169.969)},
            
            {Vector(10991.969, -751.969, -13295.969), Vector(10512.031, -751.969, -13295.969)},
            {Vector(10512.031, -288.031, -13295.969), Vector(10512.031, -751.969, -13295.969)},
            {Vector(10512.031, -288.031, -13295.969), Vector(10991.969, -288.031, -13295.969)},
            {Vector(10991.969, -751.969, -13295.969), Vector(10991.969, -288.031, -13295.969)},
            
            --
            {Vector(12288.543, -5231.969, -13311.948), Vector(10105.309, -5231.969, -13311.788)}
            
            
            
            -- Skate testing build
            --{Vector(756.412, 4588.726, -12503.642), Vector(301.162, 4588.726, -12503.642)},
            --{Vector(895.537, 4533.544, -12498.179), Vector(1803.602, 4533.544, -12746.254)},]]
        }
        local modelRails = {
            ["models/props_c17/handrail04_medium.mdl"] = {{Vector(-0.05, -32.488, 19.989), Vector(-0.05, 32.495, 19.989)}},
            ["models/props_c17/handrail04_short.mdl"] = {{Vector(-0.092, 16.455, 20.017), Vector(-0.095, -16.558, 20.017)}},
            ["models/props_c17/handrail04_singlerise.mdl"] = {{Vector(0.056, 45.48, 51.648), Vector(0.056, -46.837, -12.21)}},
            ["models/props_c17/handrail04_doublerise.mdl"] = {{Vector(0, 93.248, 84.598), Vector(0, -93.483, -44.494)}},
            ["models/props_c17/handrail04_long.mdl"] = {{Vector(-0.085, 62.725, 19.991), Vector(-0.085, -64.382, 19.991)}},
            ["models/props_c17/handrail04_corner.mdl"] = {{Vector(16.896, -18.258, 40.004), Vector(-15.061, -18.258, 40.004)}, {Vector(-15.061, -18.258, 40.004), Vector(-15.061, 13.957, 40.004)}},
            ["models/props_forest/fence_trail_128.mdl"] = {{Vector(-0.191, -65.614, 64.07), Vector(-0.191, 69.092, 64.07)}},
            ["models/props_forest/fence_trail_256.mdl"] = {{Vector(-0.179, -126.618, 64.069), Vector(-0.179, 127.654, 64.069)}},
            ["models/props_forest/fence_trail_512.mdl"] = {{Vector(-0.253, -250.131, 64.076), Vector(-0.253, 265.203, 64.076)}},
            ["models/props_forest/railing_large.mdl"] = {{Vector(-0.011, -63.986, 43.376), Vector(-0.011, 64.015, 43.376)}},
            ["models/props_interiors/handrailcluster01b_corner.mdl"] = {{Vector(-78.245, -15.807, 43.528), Vector()}, {Vector(-78.245, 80.445, 43.528), Vector(17.713, 80.445, 43.528)}},
            ["models/props_interiors/handrailcluster03a.mdl"] = {{Vector(-0.119, 106.942, -59.853), Vector(-0.119, -82.484, 74.906)}},
            ["models/props_powerhouse/powerhouse_railing_fix01.mdl"] = {{Vector(57.429, -0.024, 15.934), Vector(-57.616, -0.024, 15.934)}},
            ["models/props_powerhouse/powerhouse_railing_fix02.mdl"] = {{Vector(81.609, -0.016, 15.918), Vector(-82.93, -0.016, 15.918)}},
            ["models/props_rooftop/railing01a.mdl"] = {{Vector(0.19, -64.011, 15.977), Vector(0.19, 63.989, 15.977)}},
            ["models/props_silo/handrail_alley-upperdeck.mdl"] = {{Vector(-0.006, -130.023, 40.636), Vector(-0.006, 130.125, 40.636)}},
            ["models/props_silo/handrail_singlespan_128.mdl"] = {{Vector(-0.001, -66.009, 40.975), Vector(-0.001, 66.09, 40.975)}},
            ["models/props_spytech/spytech_railing02.mdl"] = {{Vector(65.18, 2.037, 37.639), Vector(-70.85, 2.037, 37.639)}},
            ["models/props_spytech/spytech_railing03a.mdl"] = {{Vector(247.979, 1.854, 37.446), Vector(-248.021, 1.854, 37.446)}},
            ["models/props_spytech/spytech_railing01.mdl"] = {{Vector(66.048, 2.366, 37.687), Vector(-66.197, 2.366, 37.687)}, {Vector(-66.197, 2.366, 37.687), Vector(-66.197, 60.533, 37.687)}},
            ["models/props_spytech/spytech_railing01b.mdl"] = {{Vector(66.027, -2.379, 37.69), Vector(-66.216, -2.379, 37.69)}, {Vector(-66.216, -2.379, 37.69), Vector(-66.216, -60.545, 37.69)}},
            ["models/props_spytech/spytech_railing04a.mdl"] = {{Vector(54.904, 2.24, 7.289), Vector(-52.669, 2.24, 78.459)}},
            ["models/props_spytech/spytech_railing04b.mdl"] = {{Vector(54.885, -2.259, 7.315), Vector(-52.688, -2.259, 78.484)}},
            ["models/props_swamp/railing_128.mdl"] = {{Vector(-4.012, -0.007, 61.277), Vector(128.333, -0.007, 61.277)}},
            ["models/props_swamp/railing_64.mdl"] = {{Vector(63.152, -0.029, 61.28), Vector(-4.011, -0.029, 61.28)}},
            ["models/props_swamp/railing_corner.mdl"] = {{Vector(63.625, -0.008, 60.906), Vector(-3.862, -0.008, 60.906)}, {Vector(-3.862, -0.008, 60.906), Vector(-3.862, -64.024, 60.906)}},
            ["models/props_trainstation/handrail_64decoration001a.mdl"] = {{Vector(-0.001, -32.282, 19.082), Vector(-0.001, 32.192, 19.082)}},
            ["models/props_trainyard/handrail128.mdl"] = {{Vector(-0.004, -64.704, 32.626), Vector(-0.004, 63.998, 32.626)}},
            ["models/props_trainyard/handrail216.mdl"] = {{Vector(-0.016, 106.705, 32.644), Vector(-0.016, -106.696, 32.644)}},
            ["models/props_trainyard/handrail28.mdl"] = {{Vector(-0.005, 27.972, 32.625), Vector(-0.005, -0.733, 32.625)}},
            ["models/props_trainyard/handrail480.mdl"] = {{Vector(-0.012, 239.678, 32.642), Vector(-0.012, -237.846, 32.642)}},
            ["models/props_trainyard/handrail608.mdl"] = {{Vector(-0.004, -304.587, 32.642), Vector(-0.004, 304.735, 32.642)}},
            ["models/props_trainyard/handrail_stairs.mdl"] = {{Vector(48.729, -0.671, 65.322), Vector(-48.381, -0.671, 0.844)}},
            ["models/props_trainyard/handrail_stairs01.mdl"] = {{Vector(-0.763, -117.843, -159.157), Vector(-0.763, 257.906, 28.719)}},
            ["models/props_urban/urban_trainrails001.mdl"] = {{Vector(-215.948, 5.579, 57.961), Vector(216.785, 5.579, 57.961)}},
            ["models/props_well/bridge_railing.mdl"] = {{Vector(137.278, -0.023, 35.992), Vector(-137.29, -0.023, 35.992)}},
            ["models/props/cs_assault/rustyrailing02.mdl"] = {{Vector(-0.011, 208.748, 39.996), Vector(-0.011, -209.672, 39.996)}},
            ["models/props/de_inferno/railing04.mdl"] = {{Vector(-0.128, -66.906, 40.938), Vector(-0.128, 61.566, 40.938)}},
            ["models/props/de_inferno/railing04long.mdl"] = {{Vector(-0.004, 192.318, 40.94), Vector(-0.004, -191.235, 40.94)}},
            ["models/props_phx/trains/monorail1.mdl"] = {{Vector(-233.893, 0.212, 27.272), Vector(234.878, 0.212, 27.272)}},
            ["models/props_phx/trains/monorail2.mdl"] = {{Vector(0.215, -467.64, 27.261), Vector(0.215, 469.881, 27.261)}},
            ["models/props_phx/trains/monorail3.mdl"] = {{Vector(0.238, -939.162, 27.259), Vector(0.238, 935.859, 27.259)}},
            ["models/props_phx/trains/monorail4.mdl"] = {{Vector(0.213, -1872.156, 27.264), Vector(0.213, 1877.865, 27.264)}}
        }
        
        local compileRails = coroutine.wrap(function()
            local maxCPU = math.min(0.01, quotaMax() * 0.75)
            
            print("Finding model rails")
            local modelCount = 0
            
            local table_insert = table.insert
            for model, railGroup in pairs(modelRails) do
                while quotaAverage() > maxCPU do coroutine.yield() end
                for _, ent in ipairs(find.byModel(model)) do
                    modelCount = modelCount + 1
                    while quotaAverage() > maxCPU do coroutine.yield() end
                    for _, rail in ipairs(railGroup) do
                        table_insert(rails, {ent:localToWorld(rail[1]), ent:localToWorld(rail[2])})
                    end
                end
            end
            
            print("Found " .. modelCount .. " model rails")
            print("Compiling rails")
            
            local function addToChunk(rail, pos)
                local x = compiledRails[pos[1]]
                if not x then
                    compiledRails[pos[1]] = {}
                    x = compiledRails[pos[1]]
                end
                
                local y = x[pos[2]]
                if not y then
                    x[pos[2]] = {}
                    y = x[pos[2]]
                end
                
                local z = y[pos[3]]
                if not z then
                    y[pos[3]] = {}
                    z = y[pos[3]]
                end
                
                if not table.hasValue(z, rail) then
                    table_insert(z, rail)
                end
            end
            
            for _, railCoords in ipairs(rails) do
                local railDir = railCoords[2] - railCoords[1]
                local length = railDir:getLength()
                local delta = math.min(1, 10 / length)
                
                local a = railCoords[1]
                local b = railCoords[2]
                
                local math_round = math.round
                
                for lerp = 0, 1, delta do
                    while quotaAverage() > maxCPU do coroutine.yield() end
                    local pos = math.lerpVector(lerp, a, b)
                    local rounded = pos / railChunkSize
                    rounded[1] = math_round(rounded[1])
                    rounded[2] = math_round(rounded[2])
                    rounded[3] = math_round(rounded[3])
                    for x = -1, 1 do
                        for y = -1, 1 do
                            for z = -1, 1 do
                                addToChunk(railCoords, rounded + Vector(x, y, z))
                            end
                        end
                    end
                end
            end
            print("Finished compiling rails")
            return true
        end)
        
        hook.add("think", "compile rails", function()
            if compileRails() == true then
                hook.remove("think", "compile rails")
                railsCompiled = true
            end
        end)
    end
        
        local players = find.allPlayers()
        timer.create("find players", 10, 0, function()
            players = find.allPlayers()
        end)
        
        local railSound = sounds.create(board, "physics/metal/canister_scrape_smooth_loop1.wav")
        local rollSound = sounds.create(board, "vo/taunts/skateboard_loop_01.wav")
        
        local minRailDot = math.cos((-90 + 45) * math.pi / 180)
        --local minRailDot = 0.5
        local minRailDotStart = 0.1
        
        local firstPush = true
        local turnLeftPressed = false
        local turnRightPressed = false
        local speedPressed = false
        local backPressed = false
        
        local earlyPush = false
        local pushing = false
        local pushQueued = true
        local stopPushQueued = false
        local groundNormal = Vector(0, 0, 1)
        local onGround = false
        local nearGround = true
        local nearGroundShort = true
        local lean = 0
        
        local function leaveRail()
            animLerp = 0.28775
            animDir = 1
            stopPushQueued = false
            pushQueued = true
            onRail = false
            
            railSound:stop()
            if onGround then
                rollSound:play()
                rollSound:setVolume(1)
            end
            
            flatScoutAng = Angle(0, eyeAngles()[2], 0)
        end
        
        local animMin = 0
        local animMax = 1
        local reversing = false
        local reverseLerp = 0
        local reverseLerpDuration = anim3Duration * (0.25 - 0.175)
        local angChange = Angle()
        
        hook.add("think", "", function()
            if not userClient or not railsCompiled then return end
            rollSound:setVolume(math.clamp(vel:getLength() / 500, 0, 1), 0.25)
        
            local scoutForward = flatScoutAng:getForward()
            local scoutRight = flatScoutAng:getRight()
            local forwardSpeedDir = vel:dot(scoutForward)
            
            angChange = Angle()
        
            -- Handle animation and pushing
            if onRail then
                if animDir > 0 then
                    if animLerp >= animMax then
                        animMin = math.rand(0, 0.035 * 0.5)
                        animDir = -0.25
                        scout:setAnimation("layer_taunt_the_boston_boarder_trickB", animLerp, animDir)
                    end
                elseif animLerp <= animMin then
                    animMax = math.rand(0.035 * 0.5, 0.035)
                    animDir = 0.25
                    scout:setAnimation("layer_taunt_the_boston_boarder_trickB", animLerp, animDir)
                end
                animLerp = animLerp + anim2LerpSpeed * animDir * timer.frametime()
            else
                if not nearGroundShort and not inAir and not landing then
                    -- Start air anim
                    reversing = false
                    inAir = true
                    scout:setAnimation("layer_taunt_the_boston_boarder_trickB", 0, 1)
                    animDir = 1
                    animLerp = 0
                    leftNearGroundShort = false
                end
                
                if inAir and not nearGroundShort then
                    leftNearGroundShort = true
                end
                    
                if inAir and nearGroundShort and (leftNearGroundShort or onGround) then
                    -- Start landing anim
                    inAir = false
                    landing = true
                    pushing = false
                    if animDir ~= 1 then
                        animDir = 1
                        animLerp = math.max(animLerp, 0.13)
                    end
                    scout:setAnimation("layer_taunt_the_boston_boarder_trickB", animLerp, 1)
                end
                
                if inAir and animDir == 1 and animLerp >= 0.13 then -- 0.065
                    animDir = 0.25 * (math.rand(0, 1) > 0.5 and 1 or -1)
                    animMin = math.rand(0.005, 0.0125)
                    animMax = math.rand(0.0125, 0.02)
                    animLerp = math.rand(0.005, 0.02)
                    scout:setAnimation("layer_taunt_the_boston_boarder_trickB", animLerp, animDir)
                end
                
                if inAir and animDir ~= 1 then
                    if animDir > 0 then
                        if animLerp >= animMax then
                            animDir = -animDir
                            animMin = math.rand(0.005, 0.0125)
                            scout:setAnimation("layer_taunt_the_boston_boarder_trickB", animLerp, animDir)
                        end
                    else
                        if animLerp <= animMin then
                            animDir = -animDir
                            animMax = math.rand(0.0125, 0.02)
                            scout:setAnimation("layer_taunt_the_boston_boarder_trickB", animLerp, animDir)
                        end
                    end
                end
                
                if inAir or landing then
                    animLerp = animLerp + anim2LerpSpeed * animDir * timer.frametime()
                end
                
                if not inAir and reversing then
                        -- Turn around animation
                        reverseLerp = reverseLerp + timer.frametime() / reverseLerpDuration
                        if reverseLerp >= 1 then
                            -- Stop turning around
                            reversing = false
                            animLerp = 0.28775
                            stopPushQueued = true
                            pushQueued = true
                        else
                            -- Turn around
                            angChange[2] = angChange[2] + 180 * (1 - reverseLerp)
                            local val = math.cos(reverseLerp * 2 * math.pi) * 0.0375 + 0.2125
                            local derivative = -0.075 * math.pi * math.sin(2 * math.pi * reverseLerp)
                            scout:setAnimation("layer_taunt_the_boston_boarder_trickA", val, derivative)
                        end
                    elseif onGround and forwardSpeedDir <= -10 then
                        -- Start turning around
                        -- 0.12 to 0.25
                        reversing = true
                        reverseLerp = 0
                        scout:setAnimation("layer_taunt_the_boston_boarder_trickA", 0.25, 0)
                        flatScoutAng[2] = flatScoutAng[2] + 180
                        angChange[2] = angChange[2] + 180
                elseif landing then
                    -- Play landing animation
                    if animLerp >= 0.2841 then
                        landing = false
                        animLerp = animLerp - 0.2841 + 0.28775
                        pushing = false
                        stopPushQueued = false
                        pushQueued = true
                        animDir = 1
                        scout:setAnimation("layer_taunt_the_boston_boarder", animLerp)
                    end
                elseif not inAir then
                    if earlyPush then
                        -- Early push start
                        earlyPush = false
                        animLerp = 0.28775
                        animDir = 1
                        scout:setAnimation("layer_taunt_the_boston_boarder", animLerp)
                        pushing = true
                        stopPushQueued = true
                        pushQueued = false
                    else
                        -- Normal progression
                        animLerp = animLerp + anim1LerpSpeed * animDir * timer.frametime()
                        if animLerp >= 1 then
                            pushQueued = false
                            stopPushQueued = true
                            animLerp = 0.28775 + animLerp - 1
                            pushing = true
                            scout:setAnimation("layer_taunt_the_boston_boarder", animLerp)
                        end
                        if animDir == -1 then
                            -- Repush
                            if animLerp <= 0.288 then
                                -- Start push
                                firstPush = false
                                scout:setAnimation("layer_taunt_the_boston_boarder", animLerp)
                                animDir = 1
                                pushing = true
                                stopPushQueued = true
                                pushQueued = false
                            end
                        elseif animDir == 1 then
                            if pushQueued and animLerp >= 0.28775 then
                                -- Start push
                                firstPush = false
                                pushing = true
                                pushQueued = false
                                stopPushQueued = true
                            end
                            if stopPushQueued and animLerp >= 0.32 then
                                -- Stop push
                                pushing = false
                                pushQueued = false
                                stopPushQueued = false
                                
                                local scoutForward = flatScoutAng:getForward()
                                local dot = vel:dot(scoutForward)
                                local velForward = dot * scoutForward
                                if dot < 0 or velForward:getLength() < (backPressed and targetSpeedSlow or (speedPressed and targetSpeedFast or targetSpeed)) then
                                    -- Prepare for repush
                                    animDir = -1
                                    scout:setAnimation("layer_taunt_the_boston_boarder", animLerp, -1)
                                end
                            end
                        end
                    end
                end
            end
        
            if userClient then
                local forwardSpeed = math.abs(forwardSpeedDir)
                local targetLean = 0
                if turnLeftPressed then
                    flatScoutAng = flatScoutAng + Angle(0, (nearGround and 60 or 360) * timer.frametime(), 0)
                    if onGround then
                        targetLean = math.sign(forwardSpeedDir) * math.sqrt(forwardSpeed / targetSpeedFast) * -25
                    end
                end
                if turnRightPressed then
                    flatScoutAng = flatScoutAng + Angle(0, -(nearGround and 60 or 360) * timer.frametime(), 0)
                    if onGround then
                        targetLean = math.sign(forwardSpeedDir) * math.sqrt(forwardSpeed / targetSpeedFast) * 25
                    end
                end
                lean = lean + (targetLean - lean) * timer.frametime() * 10
            end
        
            vel = vel - gravity * timer.frametime()
            vel = vel * (Vector(1) - frictionMult * timer.frametime())
            
            local railDir, railDirN, railVel, railUp
            local oldOnRail = onRail
            local closestRail
            local closestRailPoint = Vector()
            local minRailDist = math.huge
            if userClient then
                -- Handle rails
                -- Find rails
                local railFrac
                if vel:getLengthSqr() >= minRailVelSqr then
                    local rails = {}
                    
                    local chunk = scoutPos / railChunkSize
                    local arr = compiledRails[math.round(chunk[1])]
                    if arr then
                        arr = arr[math.round(chunk[2])]
                        if arr then
                            arr = arr[math.round(chunk[3])]
                            if arr then
                                rails = arr
                            end
                        end
                    end
                    
                    for k, rail in ipairs(rails) do
                        local v1 = rail[2] - rail[1]
                        local v2 = rail[1] - scoutPos
                        railFrac = math.clamp(-v1:dot(v2) / v1:dot(v1), 0, 1)
                        local closestPoint = math.lerpVector(railFrac, rail[1], rail[2])
                        
                        local distSqr = closestPoint:getDistanceSqr(scoutPos)
                        if distSqr < minRailDist then
                            minRailDist = distSqr
                            closestRail = rail
                            closestRailPoint = closestPoint
                        end
                    end
                end
                
                -- Check if player should snap to rail
                if closestRail then
                    railDir = closestRail[2] - closestRail[1]
                    local railRight = railDir:cross(Vector(0, 0, 1))
                    railUp = railDir:cross(railRight):getNormalized()
                    railRight:normalize()
                    railVel = vel - vel:dot(railRight) * railRight - vel:dot(railUp) * railUp
                
                    railDirN = (closestRailPoint - scoutPos):getNormalized()
                end
                if closestRail and railVel:getLengthSqr() >= minRailVelSqr and
                    minRailDist <= (maxRailDist + (vel * timer.frametime()):dot(railDirN))^2 then
                    if onRail then
                        -- Check if player should stay on rail
                        local dot = railDir:dot(vel)
                        if (railFrac == 1 and dot > 0) or (railFrac == 0 and dot < 0) then
                            onRail = false
                        else
                            if railDir:dot(vel) < 0 then
                                railDir = -railDir
                            end
                            
                            if vel:getNormalized():dot(railDir:getNormalized()) >= minRailDot then
                                onRail = true
                            else
                                onRail = false
                            end
                        end
                    else
                        -- Check if player should get on rail
                        local velN = vel:getNormalized()
                        if railDir:dot(vel) < 0 then
                            railDir = -railDir
                        end
                        if velN:dot(railDirN) >= minRailDotStart and velN:dot(railDir:getNormalized()) >= minRailDot then
                            onRail = true
                        else
                            onRail = false
                        end
                    end
                else
                    onRail = false
                end
            end
            
            -- Handle some velocity stuff
            if onRail then
                -- On rail
                if not oldOnRail then
                    animLerp = math.rand(0, 0.035)
                    animDir = math.rand(0, 1) > 0.5 and 0.25 or -0.25
                    scout:setAnimation("layer_taunt_the_boston_boarder_trickB", animLerp, animDir)
                    railFlip = math.rand(0, 1) > 0.5 and Angle() or Angle(0, 180, 0)
                    
                    animMin = math.rand(0, 0.035 * 0.5)
                    animMax = math.rand(0.035 * 0.5, 0.035)
                    
                    railSound:play()
                    rollSound:stop(0.25)
                end
                
                if userClient then
                    if userClient then
                        scoutPos = closestRailPoint
                    end
                    if railUp[3] < 0 then
                        railUp = -railUp
                    end
                    groundNormal = railUp
                    vel = railVel
                end
            else
                -- Not on rail
                if oldOnRail then leaveRail() end
                
                -- Handle forward and side movement
                if onGround then
                    if pushing then
                        vel = vel + scoutForward * pushForce * timer.frametime()
                    end
                    vel = vel - vel:dot(scoutRight) * scoutRight * timer.frametime() * 10
                end
            end
            
            local velf = vel * timer.frametime()
            local velfLength = velf:getLength()
            
            -- Handle collisions
            local hullTrace = trace.traceHull(scoutPos, scoutPos + velf, hullMin, hullMax, players)
            local dist = hullTrace.Fraction * velfLength
            scoutPos = scoutPos + dist * velf / velfLength
            
            local dot = vel:dot(hullTrace.HitNormal)
            if dot < 0 then
                vel = vel - dot * hullTrace.HitNormal
            end
            
            nearGround = trace.traceHull(scoutPos, scoutPos - Vector(0, 0,  58), hullMin, hullMax, players).Hit
            nearGroundShort = trace.traceHull(scoutPos, scoutPos - Vector(0, 0,  38), hullMin, hullMax, players).Hit
            local downHullTrace = trace.traceHull(scoutPos, scoutPos - Vector(0, 0, 18), hullMin, hullMax, players)
            if onGround and not downHullTrace.Hit then
                rollSound:stop(0.25)
            elseif not onGround and downHullTrace.Hit then
                rollSound:play()
                rollSound:setVolume(1)
            end
            onGround = downHullTrace.Hit
            scoutPos = scoutPos + Vector(0, 0, (1 - downHullTrace.Fraction) * 18)
            
            dot = vel:dot(downHullTrace.HitNormal)
            if dot < 0 then
                vel = vel - dot * downHullTrace.HitNormal
            end
            
            local downTrace = trace.trace(scoutPos + Vector(0, 0, 1), scoutPos  - Vector(0, 0, 100000), players)
            if not onRail and onGround and downTrace.Hit then
                groundNormal = downTrace.HitNormal
            end
            
            -- Calculate angles
            local flatAng = flatScoutAng
            if onRail then
                local railDir = closestRail[2] - closestRail[1]
                local railDirSign = math.sign(railDir:dot(vel))
                flatAng = Vector(railDir[2], railDir[1], 0):getAngle() + railFlip + angChange
            end
            if lean ~= 0 then
                flatAng = (flatAng + angChange):rotateAroundAxis(scoutForward, lean)
            end
            
            if groundNormal == Vector(0, 0, 1) then
                targetScoutAng = flatAng
            else
                local axis = Vector(0, 0, 1):cross(groundNormal)
                if axis == Vector() then
                    targetScoutAng = flatAng
                else
                    local dotAng = math.acos(groundNormal[3])
                    targetScoutAng = flatAng:rotateAroundAxis(axis:getNormalized(), nil, dotAng)
                end
            end
            
            local _, delta = worldToLocal(Vector(), targetScoutAng, Vector(), scoutAng)
            _, scoutAng = localToWorld(Vector(), delta * timer.frametime() * 10, Vector(), scoutAng)
            
            if not earlyPush and not firstPush and not pushing and animDir == 1 and not inAir and not landing then
                dot = vel:dot(scoutForward)
                local velForward = dot * scoutForward
                if dot < 0 or velForward:getLength() < (backPressed and earlyPushSlowThreshold or (speedPressed and earlyPushFastThreshold or earlyPushThreshold)) then
                    timer.pause("push_stop")
                    timer.pause("push_anim")
                    timer.adjust("push_start", 0)
                    earlyPush = true
                end
            end
            
            scout:setPos(scoutPos)
            if userClient then
                scout:setAngles(scoutAng)
            
                net.start("tick")
                net.writeVector(scoutPos)
                net.writeAngle(scoutAng)
                net.writeVector(vel)
                net.writeBool(onRail)
                net.send()
            end
        end)
        
    if userClient then
        local turnLeftKey = input.lookupBinding("+moveleft")
        local turnRightKey = input.lookupBinding("+moveright")
        local speedKey = input.lookupBinding("+speed")
        local jumpKey = input.lookupBinding("+jump")
        local backKey = input.lookupBinding("+back")
        hook.add("inputPressed", "", function(key)
            if key == turnLeftKey then
                turnLeftPressed = true
            elseif key == turnRightKey then
                turnRightPressed = true
            elseif key == speedKey then
                speedPressed = true
            elseif key == jumpKey and (onGround or onRail) then
                vel = vel + Vector(0, 0, 300)
                inAir = true
                leftNearGroundShort = false
                if onRail then
                    leaveRail()
                    vel = vel + (eyeVector() * Vector(1, 1, 0)):getNormalized() * 200
                end
                animDir = 1
                scout:setAnimation("layer_taunt_the_boston_boarder_trickB")
                animLerp = 0
            elseif key == backKey then
                backPressed = true
            end
        end)
        
        hook.add("inputReleased", "", function(key)
            if key == turnLeftKey then
                turnLeftPressed = false
            elseif key == turnRightKey then
                turnRightPressed = false
            elseif key == speedKey then
                speedPressed = false
            elseif key == backKey then
                backPressed = false
            end
        end)
    
        hook.add("calcview", "", function(_, ogCamAng)
            -- Control camera
            local scoutCenter = scout:localToWorld(Vector(0, 0, 44.262775421142))
            camAng = ogCamAng
            local camForward = camAng:getForward()
            local camTrace = trace.trace(scoutCenter, scoutCenter - camForward * 101)
            local camPos = camTrace.HitPos + camForward
            return {
                origin = camPos,
                angles = camAng
            }
        end)
        
        enableHud(user, true)
        timer.create("why do my controls stop unlocking", 2, 0, function()
            if not input.isControlLocked() then
                input.lockControls(true)
            end
        end)
    end
    end)
    
    --[[net.init()
    net.receive("init", function()
        net.readHologram(function(ent)
            scout = ent
            if board then
                main()
            end
        end)
        net.readHologram(function(ent)
            board = ent
            if scout then
                main()
            end
        end)
        local cosmeticCount = net.readUInt8()
        for i = 1, cosmeticCount do
            net.readHologram(function(ent)
                if ent and ent:isValid() then
                    ent:setParent(scout)
                    ent:addEffects(EF.BONEMERGE)
                end
            end)
        end
    end)]]
end