# Public Starfall
Home to my Starfall code that I've made public. All code is freely available to use or reference in any project including published projects.

## Directory
* [Better Coroutines](Better%20Coroutines) - Essentially a `coroutine.wrap()` that automatically restarts and can be manually restarted prematurely.
* [Coroutine Wrapper](Coroutine%20Wrapper) - Used to automatically make most default callback functions run as a coroutine to allow code to block execution. Useful for things like [Spawn Blocking](Spawn%20Blocking) for example that blocks execution until an action can be performed.
* [Dumping Grounds](Dumping%20Grounds) - All of my Starfall chips and files worth uploading. **Not actively maintained**
* [ReadWriteType](ReadWriteType) - Read and write more data types to and from files.
* [SafeNet](SafeNet) - A backwards compatible replacement for the built-in `net` functions that automatically sends data in chunks based on the amount of bytes still available to network. Also allows reading and writing more data types including varargs and tables. Includes additional QoL functions like a function to handle client initialization and variables that are synchronized between the server and clients.
* [Shared Funcs](Shared%20Funcs) - A joke library that allows running server-only functions from the client and vice versa. **This is not recommended to be used seriously.**
* [Spawn Blocking](Spawn%20Blocking) - Makes spawning functions like `prop.create()` and `holograms.create()` block execution until the entity can be created.
* [Sprite Sheet Manager](Sprite%20Sheet%20Manager) - Allows simple usage of sprite sheets by specifying the number of rows and columns in the sprite sheet during creation and specifying a sprite/frame index when drawing. Allows loading multiple images in a sprite sheet set. Can be used to, for example, play GIFs after converting the GIF to sprite sheets externally.
* [pac3-anim-lib](pac3-anim-lib) - Allows playing custom animations created with [PAC3](https://github.com/CapsAdmin/pac3) on holograms.