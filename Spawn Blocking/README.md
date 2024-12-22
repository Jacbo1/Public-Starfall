## Spawn Blocking
**[Coroutine Wrapper](https://github.com/Jacbo1/Public-Starfall/tree/main/Coroutine%20Wrapper) is required.**  
When trying to spawn/create something, execution will be blocked until it can be created.
### Usage
It will overwrite
* prop.create
* prop.createComponent
* prop.createCustom
* prop.createRagdoll
* prop.createSeat
* prop.createSent
* prop2mesh.create (if it exists)
* effect.create
* holograms.create
* sounds.create  

with blocking versions.
### Example
```lua
--@name Coroutine Wrapper and Spawn Blocking Example
--@author Jacbo
--@shared
--@include https://raw.githubusercontent.com/Jacbo1/Public-Starfall/main/SafeNet/safeNet.lua as SafeNet
--@include https://raw.githubusercontent.com/Jacbo1/Public-Starfall/refs/heads/main/Spawn%20Blocking/spawn_blocking.lua as SpawnBlocking
require("SafeNet")
local net = safeNet
require("SpawnBlocking")

if SERVER then
    corWrap(function()
        local pos = chip():getPos()
        for i = 1, 10 do
            prop.create(pos + Vector(0,0,i*6), Angle(), "models/sprops/cuboids/height06/size_1/cube_6x6x6.mdl", true)
        end
    end)

    timer.simple(5, function()
        local pos = chip():getPos() + Vector(6,0,0)
        for i = 1, 10 do
            prop.create(pos + Vector(0,0,i*6), Angle(), "models/sprops/cuboids/height06/size_1/cube_6x6x6.mdl", true)
        end
    end)

    hook.add("think", "", function()
        local pos = chip():getPos() + Vector(12,0,0)
        for i = 1, 10 do
            prop.create(pos + Vector(0,0,i*6), Angle(), "models/sprops/cuboids/height06/size_1/cube_6x6x6.mdl", true)
        end
        hook.remove("think", "")
    end)
    
    net.receive("", function()
        net.receive("")
        local pos = chip():getPos() + Vector(18,0,0)
        for i = 1, 10 do
            prop.create(pos + Vector(0,0,i*6), Angle(), "models/sprops/cuboids/height06/size_1/cube_6x6x6.mdl", true)
        end
    end)
else -- CLIENT
    net.start("")
    net.send()
end
```
