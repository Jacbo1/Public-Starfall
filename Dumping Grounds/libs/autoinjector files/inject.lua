if not file.Exists("sf_filedata/inject.txt", "DATA") then return end
local name = file.Read("sf_filedata/inject.txt", "DATA")
if file.Exists("lua/sfinject/" .. name .. ".lua", "MOD") then
	RunString(file.Read("lua/sfinject/" .. name .. ".lua", "MOD"))
end