-- Gets a direct Dropbox or Google Drive URL from the provided one.
-- Replace the url string and spawn the chip. The new URL will be copied to your clipboard.
-- You can use the direct URL with Starfall, E2, PAC3, etc.

--@name URL Fix
--@author Jacbo
--@shared

if SERVER then
    net.receive("", function()
        chip():remove()
    end)
else
    if player() ~= owner() then return end
    local url = "https://www.dropbox.com/s/ru2jty3ju766sjy/Mee%2B%2B_Intro_Sound.mp3?dl=1"
    if string.find(url, "dropbox", 1, true) then
        url = "https://dl.dropboxusercontent.com/s/" .. string.sub(url, 27, #url - 5)
    elseif string.find(url, "drive.google", 1, true) then
        url = "https://drive.google.com/uc?export=download&id=" .. string.sub(url, 33, string.find(url, "/", 33, true) - 1)
    else
        print("Unsupported source")
    end
    print(url)
    setClipboardText(url)
    net.start("")
    net.send()
end