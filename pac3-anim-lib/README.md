# Pac3 Animation Library
Parse Pac3 animations and play them on holograms.
## How to use
```lua
--@name Anim Lib Test
--@include anim_lib.txt
--@client

require("anim_lib.txt")

local holo = holograms.create(chip():getPos(), Angle(), "models/player/barney.mdl")
local myAnim = anim.create(holo, json.decode(file.read("myAnim.txt")))
myAnim:play()
```
## Functions
* `anim.create(entity, table)` Creates an animation from the table and associates it with the entity. Returns an anim object.
* `anim:play()` Starts/resume an animation. Calling it while an animation is already running does nothing.
* `anim:destroy()` Destroys the animation. Automatically called if the entity becomes invalid and an error occurs while attempting to play the animation. Without this, the animation (and its data) will not be garbage collected.
* `anim:pause()` Pauses an animation
* `anim:stop()` Stops an animation and resets the progress
* `anim:restart()` Resets the progress. Does not stop or start playing the animation.
* `anim:setRate(rate)` Sets the animation rate. Can also use `anim[4]` to get or set the rate.
* `anim:setFrame(frame, time or nil)` Sets the frame and time. `time` defaults to 0. The time determines how far along in the frame the animation is. If the frame has a duration of 0.5 seconds, then time should be set to 0.25 to be halfway through. It is not the time ellapsed for the entire animation. `frame` is alternatively `anim[5]` and `time` is alternatively `anim[2]`.
