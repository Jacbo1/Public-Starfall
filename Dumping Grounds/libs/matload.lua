--@name Matload
--@author Jacbo
--@client
--@include libs/print2.txt

require("libs/print2.txt")

if CLIENT then
    local matMethods = getMethods("Material")
    local setFloat = 1
    local setInt = 2
    local setMatrix = 3
    local setString = 4
    local setTexture = 5
    local setVector = 6
    
    local setLookup = {
        matMethods.setFloat,
        matMethods.setInt,
        matMethods.setMatrix,
        matMethods.setString,
        matMethods.setTexture,
        matMethods.setVector
    }
    
    local getLookup = {
        material.getFloat,
        material.getInt,
        material.getMatrix,
        material.getString,
        material.getTexture,
        material.getVector
    }
    
    local lookup = {
        ["$flags"] = setInt,
        --["$flags2"] = setInt,     -- blocked
        ["$flags_defined"] = setInt,
        ["$flags_defined2"] = setInt,
        ["$basetexture"] = setTexture,
        ["$basetexturetransform"] = setMatrix,
        --["$frame"] = setInt,      -- blocked
        ["$basetexture2"] = setTexture,
        ["$basetexturetransform2"] = setMatrix,
        ["$frame2"] = setInt,
        ["$surfaceprop"] = setString,
        ["$detail"] = setTexture,
        ["$detailtexturetransform"] = setMatrix,
        ["$detailscale"] = setFloat,
        ["$detailblendfactor"] = setFloat,
        ["$detailblendmode"] = setInt,
        ["$detailtint"] = setMatrix,
        ["$detailframe"] = setInt,
        ["$blendmodulatetexture"] = setTexture,
        ["$blendmasktransform"] = setMatrix,
        ["$maskedblending"] = setInt,
        ["$alpha"] = setFloat,
        ["$alphatest"] = setInt,
        ["$alphatestreference"] = setFloat,
        ["$allowalphatocoverage"] = setInt,
        ["$ambientocclusion"] = setFloat,
        ["$AmbientOcclColor"] = setMatrix,
        ["$AmbientOcclTexture"] = setTexture,
        ["$blendtintbybasealpha"] = setInt,
        ["$blendtintcoloroverbase"] = setFloat,
        ["$bumpbasetexture2withbumpmap"] = setTexture,
        ["$bumpmap"] = setTexture,
        ["$bumptransform"] = setMatrix,
        ["$bumpframe"] = setInt,
        ["$nodiffusebumplighting"] = setInt,
        ["$ssbump"] = setInt,
        ["$SSBumpMathFix"] = setInt,
        ["$forcebump"] = setInt,
        ["$bump_force_on"] = setInt,
        ["$addbumpmaps"] = setInt,
        ["$bumpmap2"] = setTexture,
        ["$bumpframe2"] = setInt,
        ["$bumptransform2"] = setMatrix,
        ["$bumpmask"] = setTexture,
        ["$bumpdetailscale1"] = setFloat,
        ["$burning"] = setInt,
        ["$color"] = setVector,
        ["$color2"] = setVector,
        ["$tintmasktexture"] = setTexture,
        ["$allowdiffusemodulation"] = setInt,
        ["$notint"] = setInt,
        ["$decaltexture"] = setTexture,
        ["$decalblendmode"] = setInt,
        ["$modeldecalignorez"] = setInt,
        ["$displacementmap"] = setTexture,
        ["$displacementwrinkle"] = setInt,
        ["$distancealpha"] = setFloat,
        ["$softedges"] = setFloat,
        ["$scaleedgesoftnessbasedonscreenres"] = setInt,
        ["$glow"] = setFloat,
        ["$glowcolor"] = setMatrix,
        ["$glowalpha"] = setFloat,
        ["$glowx"] = setFloat,
        ["$glowy"] = setFloat,
        ["$glowstart"] = setFloat,
        ["$glowend"] = setFloat,
        ["$outline"] = setFloat,
        ["$outlinecolor"] = setMatrix,
        ["$outlinealpha"] = setFloat,
        ["$outlinestart0"] = setFloat,
        ["$outlinestart1"] = setFloat,
        ["$outlineend0"] = setFloat,
        ["$outlineend1"] = setFloat,
        ["$scaleoutlinesoftnessbasedonscreenres"] = setFloat,
        ["$emissiveblend"] = setFloat,
        ["$emissiveblendenabled"] = setInt,
        ["$emissiveblendtexture"] = setTexture,
        ["$emissiveblendbasetexture"] = setTexture,
        ["$emissiveblendtint"] = setMatrix,
        ["$emissiveblendstrength"] = setFloat,
        ["$emissiveblendscrollvector"] = setVector,
        ["$envmap"] = setTexture,
        ["$envmapmask"] = setTexture,
        ["$envmaptint"] = setMatrix,
        ["$envmapcontrast"] = setFloat,
        ["$envmapsaturation"] = setFloat,
        ["$envmapframe"] = setInt,
        ["$envmapmode"] = setInt,
        ["$fresnelreflection"] = setFloat,
        ["$envmapfresnel"] = setFloat,
        ["$envmapfresnelminmaxexp"] = setVector,
        ["$envmaplightscale"] = setFloat,
        ["$envmapmasktransform"] = setMatrix,
        ["$envmapmaskscale"] = setFloat,
        ["$envmapmaskframe"] = setInt,
        ["$basealphaenvmapmask"] = setInt,
        ["$normalmapalphaenvmapmask"] = setInt,
        ["$selfillum_envmapmask_alpha"] = setFloat,
        ["$halflambert"] = setInt,
        ["$ignorez"] = setInt,
        --["$lightwarptexture"] = setTexture,
        ["$masks1"] = setTexture,
        ["$masks2"] = setTexture,
        ["$warpindex"] = setTexture,
        ["$maxfogdensityscalar"] = setFloat,
        ["$model"] = setInt,
        ["$layertint1"] = setMatrix,
        ["$layertint2"] = setMatrix,
        ["$no_draw"] = setInt,
        ["$nocull"] = setInt,
        ["$nodecal"] = setInt,
        ["$nofog"] = setInt,
        ["$receiveflashlight"] = setInt,
        ["$phong"] = setInt,
        ["$basemapalphaphongmask"] = setInt,
        ["$basemapluminancephongmask"] = setInt,
        ["$phongexponent"] = setInt,
        ["$phongexponent2"] = setInt,
        ["$phongexponenttexture"] = setTexture,
        ["$phongexponentfactor"] = setInt,
        ["$invertphongmask"] = setInt,
        ["$forcephong"] = setInt,
        ["$phongboost"] = setFloat,
        ["$phongfresnelranges"] = setMatrix,
        ["$phongdisablehalflambert"] = setInt,
        ["$phongalbedotint"] = setInt,
        ["$phongalbedoboost"] = setFloat,
        ["$phongtint"] = setMatrix,
        ["$phongwarptexture"] = setTexture,
        ["$pointsamplemagfilter"] = setInt,
        ["$reflectivity"] = setMatrix,
        ["$rimlight"] = setInt,
        ["$rimlightexponent"] = setInt,
        ["$rimlightboost"] = setFloat,
        ["$rimmask"] = setInt,
        ["$fresnelrangestexture"] = setTexture,
        ["$metalness"] = setFloat,
        ["$seamless_scale"] = setFloat,
        ["$seamless_detail"] = setInt,
        ["$treesway"] = setInt,
        ["$treeswayheight"] = setFloat,
        ["$treeswaystartheight"] = setFloat,
        ["$treeswayradius"] = setFloat,
        ["$treeswaystartradius"] = setFloat,
        ["$treeswayspeed"] = setFloat,
        ["$treeswaystrength"] = setFloat,
        ["$treeswayscrumblespeed"] = setFloat,
        ["$treeswayscrumblestrength"] = setFloat,
        ["$treeswayscrumblefrequency"] = setFloat,
        ["$treeswayfalloffexp"] = setFloat,
        ["$treeswayscrumblefalloffexp"] = setFloat,
        ["$treeswayspeedhighwindmultipler"] = setFloat,
        ["$treeswayspeedlerpstart"] = setFloat,
        ["$treeswayspeedlerpend"] = setFloat,
        ["$treeswaystatic"] = setFloat,
        
        ["$minsize"] = setFloat,
        ["$maxsize"] = setFloat,
        ["$minfadesize"] = setFloat,
        ["$maxfadesize"] = setFloat,
        ["$maxdistance"] = setFloat,
        ["$farfadeinterval"] = setFloat,
        ["$blendframes"] = setInt,
        ["$dualsequence"] = setInt,
        ["$maxlumframeblend1"] = setInt,
        ["$maxlumframeblend2"] = setInt,
        ["$zoomanimateseq2"] = setFloat,
        ["$addoverblend"] = setInt,
        ["$addself"] = setFloat,
        ["$addbasetexture2"] = setFloat,
        ["$depthblend"] = setInt,
        ["$depthblendscale"] = setFloat,
        ["$inversedepthblend"] = setInt,
        ["$orientation"] = setInt,
        ["$orientationmatrix"] = setMatrix,
        ["$overbrightfactor"] = setFloat,
        ["$ramptexture"] = setTexture,
        ["$mod2x"] = setInt,
        ["$opaque"] = setInt,
        ["$muloutputbyalpha"] = setInt,
        ["$intensity"] = setFloat,
        ["$vertexcolor"] = setInt,
        ["$vertexalpha"] = setInt,
        ["$lerpcolor1"] = setMatrix,
        ["$lerpcolor2"] = setMatrix,
        ["$vertexfogamount"] = setFloat,
        ["$extractgreenalpha"] = setInt,
        ["$splinetype"] = setInt,
        ["$useinstancing"] = setInt,
        ["$alphatrailfade"] = setFloat,
        ["$radiustrailfade"] = setFloat,
        ["$shadowdepth"] = setInt,
        ["$cropfactor"] = setMatrix,
        ["$perparticleoutline"] = setInt,
        
        ["$translucent"] = setInt,
        ["$additive"] = setInt,
        ["$writeZ"] = setInt,
        
        ["$hueshiftamount"] = setFloat,
        ["$warpindex"] = setFloat,
        ["$anisotropyamount"] = setFloat,
        ["$shadowcontrast"] = setFloat,
        ["$shadowsaturation"] = setFloat,
        ["$shadowrimboost"] = setFloat,
        ["$ambientreflectionbouncecenter"] = setMatrix,
        ["$ambientreflectionbouncecolor"] = setMatrix,
        ["$ambientreflectionboost"] = setFloat,
        ["$rimhaloboost"] = setFloat,
        ["$fakerimtint"] = setMatrix,
        ["$fakerimboost"] = setFloat,
        ["$rimlighttint"] = setMatrix,
        ["$rimlightalbedo"] = setFloat,
        ["$phongalbedoboost"] = setFloat,
        ["$envmaplightscaleminmax"] = setVector,
        ["$envmaplightscale"] = setFloat,
        
        ["$ambientonly"] = setInt,
        ["$cloakcolortint"] = setVector,
        ["$cloakfactor"] = setFloat,
        ["$cloakpassenabled"] = setInt,
        ["$linearwrite"] = setInt,
        ["$srgbtint"] = setVector,
        ["$selfillumtint"] = setVector,
        ["$treeswayspeedhighwindmultiplier"] = setFloat,
        ["$time"] = setFloat,
        ["$flashlightnolambert"] = setInt,
        ["$seamless_base"] = setInt,
        ["$selfillumfresnel"] = setInt,
        ["$separatedetailuvs"] = setInt,
        ["$flashlighttextureframe"] = setInt,
        ["$refractamount"] = setFloat,
        ["$selfillumfresnelminmaxexp"] = setVector,
        ["$selfillum"] = setInt
    }

    function material.load2(path)
        local m = material.create(material.getShader(path))
        
        for k, v in pairs(lookup) do
            try(function()
                local val = getLookup[v](path, k)
                --local val = material.getString(path, k)
                if val then
                    --print2(k, " = ", val)
                    setLookup[v](m, k, val)
                    --m:setString(k, val)
                    --print2(k, " = ", val)
                    --print2(m:getString(k))
                end
            end, function(...)
                printTable2(...)
                print2("Could not get \"" .. k .. "\" .. from \"" .. path .. "\"")
            end)
        end
        
        local lightwarptexture = material.getTexture(path, "$lightwarptexture")
        if lightwarptexture then
            --m:setTexture("$lightwarptexture", lightwarptexture)
        end
        
        --m:recompute()
        
        return m
    end
end