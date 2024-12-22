if not CLIENT then return end

if not jacbo then jacbo = {} end
if jacbo.sfDocInject then return end
include("starfall/editor/editor.lua")

local queue = {}
local waiting = false
function jacbo.sfDocInject(cb)
	table.insert(queue, cb)
	if waiting then return end
	waiting = true
	hook.Add("Think", "jacbo:sf inject", function()
		if not SF.Docs then return end
		hook.Remove("Think", "jacbo:sf inject")
		waiting = false

		-- Run callbacks
		for _, cb in ipairs(queue) do
			pcall(cb)
		end
		queue = {}
		
		-- Reload Starfall editor
		pcall(function()
			if SF.Editor.initialized then
				SF.Editor.editor:Close()
				for k, v in pairs(SF.Editor.TabHandlers) do
					if v.Cleanup then v:Cleanup() end
				end
				SF.Editor.initialized = false
				--SF.Editor.editor:Remove()
				--SF.Editor.editor = nil
			end
		end)
	end)
end