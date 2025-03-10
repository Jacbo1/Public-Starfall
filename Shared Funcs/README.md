# Shared Funcs
**THIS IS NOT MEANT TO BE TAKEN SERIOUSLY NOR IS IT A GOOD WAY TO CODE**  
**Shared Funcs requires [SafeNet](https://github.com/Jacbo1/Public-Starfall/tree/main/SafeNet) and [Coroutine Wrapper](https://github.com/Jacbo1/Public-Starfall/tree/main/Coroutine%20Wrapper)**  
Shared Funcs aims to let you use client side functions and metamethods on the server and vice versa. It supports anything that was not already shared and its inputs and outputs could be networked by SafeNet. This means you can do things like spawning props client side or writing a file from the server. Almost every client command run from the server is run on the owner. There are some exceptions when using player metamethods, mostly for methods that just return a value.  
**Note: There are some inconsistent issues with creating entities from the client. Sometimes the client will not actually receive the entity.**

## Usage
The original syntax remains entirely unchanged except for requirements enforced by Coroutine Wrapper due to limitations. See the [README in Coroutine Wrapper](https://github.com/Jacbo1/Public-Starfall/tree/main/Coroutine%20Wrapper) to learn more.

## Example
This example spawns a table above each player's head and breaks it. Because of the spawn burst rate limit it will not work on every player of course.
```lua
--@include https://raw.githubusercontent.com/Jacbo1/Public-Starfall/refs/heads/main/Shared%20Funcs/shared_funcs.lua as SharedFuncs
--@shared

require("SharedFuncs")
corWrap(function()
    if CLIENT then
        local ent = prop.create(player():getPos() + Vector(0,0,100), Angle(), "models/props_c17/FurnitureTable001a.mdl")
        ent:breakEnt()
    end
end)
```
The same example but with [Spawn Blocking](https://github.com/Jacbo1/Public-Starfall/tree/main/Spawn%20Blocking) will spawn all props.
```lua
--@include https://raw.githubusercontent.com/Jacbo1/Public-Starfall/main/SafeNet/safeNet.lua as SafeNet
--@include https://raw.githubusercontent.com/Jacbo1/Public-Starfall/refs/heads/main/Spawn%20Blocking/spawn_blocking.lua as SpawnBlocking
--@include https://raw.githubusercontent.com/Jacbo1/Public-Starfall/refs/heads/main/Shared%20Funcs/shared_funcs.lua as SharedFuncs
--@shared

require("SafeNet")
require("SpawnBlocking")
require("SharedFuncs")
corWrap(function()
    if CLIENT then
        local ent = prop.create(player():getPos() + Vector(0,0,100), Angle(), "models/props_c17/FurnitureTable001a.mdl")
        ent:breakEnt()
    end
end)
```
