# Sprite Sheet Manager
Let's you draw sprites from sprite sheets easily. Allows usage of multiple images that make up a full sprite sheet when combined (because you can only load images up to 1024x1024).  
The Java program is not needed and is used for converting gifs into sprite sheets. This is discussed at the bottom.

## Functions
* `manager.loadURL(string url, number columns, number rows, function or nil callback)` - Creates a sprite sheet manager and loads the image from the URL. If a callback is provided, it will be ran when the manager finishes loading all images. Returns a sprite sheet manager object.
* `manager:appendURL(string url)` - Appends another image to the sprite sheet set.
* `manager:setCallback(function or nil callback)` - Sets the sprite sheet manager's callback function. If provided, it will be ran when all images are loaded.
* `manager:drawSprite(number x, number y, number width, number height, number index)` - Draws a sprite from the sprite sheet specified by `index` in a rectangle specified by `x`, `y`, `width`, and `height`.
* `manager:getSpriteWidth()` - Gets the width of one sprite.
* `manager:getSpriteHeight()` - Gets the height of one sprite.
* `manager:isLoading()` - Checks if the sprite sheet manager is loading images.

## Example usage
```lua
--@name Sprite Manager Example
--@author Jacbo
--@client
--@include https://raw.githubusercontent.com/Jacbo1/Public-Starfall/refs/heads/main/Sprite%20Sheet%20Manager/Sprite%20Sheet%20Manager.lua as SpriteManager

local manager = require("SpriteManager")
local delay = 0.05
local frameCount = 8^2*3

local sprite_sheet = manager.loadURL("https://cdn.discordapp.com/attachments/607371740540305424/871456722873618442/1.png", 8, 8)
sprite_sheet:appendURL("https://cdn.discordapp.com/attachments/607371740540305424/871456756759404584/2.png")
sprite_sheet:appendURL("https://cdn.discordapp.com/attachments/607371740540305424/871456772580335737/3.png")

sprite_sheet:setCallback(function()
    hook.add("render", "", function()
        sprite_sheet:drawSprite(
            0, 0, 512, 512,
            math.floor(timer.systime() / delay) % frameCount + 1
        )
    end)
end)
```

## Converting gifs to sprite sheets
The included java file will convert gifs into sprite sheet pngs. It can load gifs from a file path or a url but not all gifs will work. It is not an executable and is just for running within a java IDE. The settings are hard coded at the top of the class.  
**Note: The program saves sprite sheets to the output directory as 1.png, 2.png, etc. and will overwrite any files with identical names.**

---
![Demo GIF](https://github.com/Jacbo1/Public-Starfall/blob/main/Sprite%20Sheet%20Manager/demo.gif?raw=true)
