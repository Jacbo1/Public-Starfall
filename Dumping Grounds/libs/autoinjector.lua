-- This script is for injecting cslua into starfall.
-- IMPORTANT: You must add the following to autoexec.cfg:
--    alias "sfinject" "lua_openscript_cl sfinject/inject.lua"
-- This is because concmd blocks the lua_openscript_cl command

--@name Autoinjector
--@author Jacbo
--@shared

if SERVER then
    net.receive("self destruct", function()
        chip():remove()
        net.receive("self destruct")
    end)
elseif player() == owner() then
    function injectLua(name, test)
        if test ~= nil then return false end
        file.write("inject.txt", name)
        concmd("sfinject")
        net.start("self destruct")
        net.send()
        print("Please respawn the chip to inject " .. name)
        return true
    end
end