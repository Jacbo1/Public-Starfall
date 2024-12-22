-- This script is for injecting cslua into starfall.
-- IMPORTANT: Read Dumping Grounds\libs\autoinjector files\README.md

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