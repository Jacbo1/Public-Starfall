# Coroutine Wrapper
This is a library for other libraries. It is used to keep all code inside coroutines so libraries can make functions that block until execution is finished while still being able to yield.

## Usage
It will automatically wrap anything run by
* hook.add
* timer.simple
* timer.create
* timer.adjust
* bass.loadURL
* net.receive
* safeNet.receive (only if safeNet is included and required before this Coroutine Wrapper. It is not required)
For anything not in the above cases, `corWrap(function func, args ...)` or `corWrapHook(function func, string hookname, args ...)` must be used. `corWrap` will resume in a think hook while `corWrapHook` will resume in whatever hook is specified.

## Example
This example uses [Spawn Blocking](https://github.com/Jacbo1/Public-Starfall/tree/main/Spawn%20Blocking)  
**Note: SafeNet is not required**
```lua
--@name Coroutine Wrapper and Spawn Blocking Example
--@author Jacbo
--@shared
--@include https://raw.githubusercontent.com/Jacbo1/Public-Starfall/main/SafeNet/safeNet.lua as SafeNet
--@include https://raw.githubusercontent.com/Jacbo1/Public-Starfall/refs/heads/main/Spawn%20Blocking/spawn_blocking.lua as SpawnBlocking

local net = require("SafeNet")
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
