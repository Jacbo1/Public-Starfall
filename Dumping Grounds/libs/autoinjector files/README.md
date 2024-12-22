This folder contains files needed for or used by `libs\autoinjector.txt`.  
**LEAVE ALL FILES IN THIS FOLDER AS `.lua`!**  
These files should be placed in `GarrysMod\garrysmod\lua\sfinject\`.  
`inject.lua` is required and all other files are injectors which `inject.lua` is able to call.

---
**IMPORTANT**  
You must add the following to `GarrysMod\garrysmod\cfg\autoexec.cfg`:
```
alias "sfinject" "lua_openscript_cl sfinject/inject.lua"
```
This is because `concmd()` blocks the `lua_openscript_cl` command. If your game is already running, just run this command in the console but still add it to your autoexec.cfg too.

---
**IMPORTANT**  
Move `libs\autoinjector files\lua\includes\modules\inject_sf_docs.lua` to `GarrysMod\garrysmod\lua\includes\modules\inject_sf_docs.lua`.