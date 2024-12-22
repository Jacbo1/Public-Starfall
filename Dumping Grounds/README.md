## Dumping Grounds
I stopped playing gmod a while ago so instead of letting all my code sit and gather dust, I figured I'd upload most of it here if anyone wanted to check it out or use the code/chips. Files will be .lua for syntax highlighting purposes while viewing them on GitHub but must be changed to .txt to actually use them in-game. Some files also require libraries and should ideally be changed to use the actively maintained files found in https://github.com/Jacbo1/Public-Starfall/tree/main via URL if available. See below for how to do this.

Full permission is given to use and reference the code in this repo as long as you aren't claiming you made it.

Some of the code you will see may be old and bad and some will be "new" and good. **This folder is called the "Dumping Grounds" for a reason.** Do not expect a high standard of recollection or testing. This folder is lower effort than anything else I publish.

**Note:** I don't plan on maintaining anything in this folder and only most stuff is functional. **For libraries I will still be maintaining, see https://github.com/Jacbo1/Public-Starfall/tree/main.**

---
Libraries can be loaded via URL by adapting the following example:
```lua
--@include https://raw.githubusercontent.com/Jacbo1/Public-Starfall/main/SafeNet/safeNet.lua as SafeNet

require("SafeNet")
```
To get this URL, go to the file on GitHub, click the "Raw" button in the top right of the code pane, and this will open the raw file where you can use the link of that page in the `--@include`.

---
**Note:** A few files have `libs\autoinjector.txt` as a dependency. Please read [libs\autoinjector files\README.md](libs/autoinjector%20files/README.md) before using this as it requires a small amount of first time setup.