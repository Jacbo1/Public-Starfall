--@name Orthocam
--@author Jacbo
--@client

setupPermissionRequest({ "render.renderscene", "render.renderView" }, "See in orthographic", true)
local permissionSatisfied = hasPermission("render.renderView")

local rtName = "cam"
render.createRenderTarget(rtName)

local mat = material.create("gmodscreenspace")
mat:setTextureRenderTarget("$basetexture", rtName)

local scrW = 1920
local scrH = 1080
local screenEnt

hook.add("ComponentLinked","",function(ent)
    hook.add("drawhud","",function()
        --[[if not permissionSatisfied then
            render.setColor(Color(255, 255, 255))
            render.setFont("DermaLarge")
            render.drawText(256, 256 - 32, "Use me", 1)
            return
        end
    
        if render.isInRenderView() then
            render.setColor(Color(0, 0, 0))
            render.drawRect(0, 0, 512, 512)
            render.setColor(Color(255, 255, 0))
            render.setFont("DermaLarge")
            render.drawText(256, 256 - 32, "RenderView", 1)
            return
        end]]
    
        scrW, scrH = render.getGameResolution()
    
        render.pushViewMatrix({ type = "2D" })
        render.setMaterial(mat)
        render.setColor(Color(255, 255, 255))
        render.drawTexturedRect(scrW, 0, -scrW, scrH)
        render.popViewMatrix()
    end)
    
    hook.add("hudconnected","",function()
            hook.add("renderscene", "render_view", function()
                if not permissionSatisfied then return end
                
                render.selectRenderTarget(rtName)
                
                render.enableClipping(true)
                
                local clipNormal = eyeVector()
                --render.pushCustomClipPlane(clipNormal, (eyePos() + clipNormal):dot(clipNormal))
                
                render.renderView({
                    origin = eyePos(),
                    angles = eyeAngles() * Angle(1, -1, 1),
                    aspectratio = scrW / scrH,
                    x = 0,
                    y = 0,
                    w = scrW,
                    h = scrH,
                    drawviewmodel = false,
                    drawviewer = false,
                    ortho = {
                        left = -45,
                        right = 45,
                        top = -45,
                        bottom = 45
                    }
                })
                
                --render.popCustomClipPlane()
                
                render.selectRenderTarget()
            end)
        end)
        
        hook.add("huddisconnected","",function()
            hook.remove("renderscene", "render_view")
        end)
end)

hook.add("permissionrequest", "", function()
    permissionSatisfied = hasPermission("render.renderView")
end)