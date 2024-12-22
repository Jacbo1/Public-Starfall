--@name Easy Chat Print Fix
--@author Jacbo
--@include safenet.txt

require("safenet.txt")
if SERVER then
    safeNet.receive("print", function()
        print(safeNet.readType())
    end, "pf")
    
    safeNet.receive("printTable", function()
        printTable(safeNet.readTable())
    end, "pf")
elseif player() == owner() then
    function print(...)
        safeNet.start("print", "pf")
        safeNet.writeType(...)
        safeNet.send()
    end
    
    function printTable(...)
        safeNet.start("printTable", "pf")
        safeNet.writeTable(...)
        safeNet.send()
    end
end