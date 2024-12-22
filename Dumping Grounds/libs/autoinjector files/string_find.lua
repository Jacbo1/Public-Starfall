SF.Modules.jacboStringFind = {injected = {init = function(instance)
	instance.Libraries.string.gfind = string.find
end}}

require("inject_sf_docs")
jacbo.sfDocInject(function()
	SF.Docs.Libraries.string.methods.gfind = {
		class = "function",
		description = "Unrestricted glua string.find. Attempts to find the specified substring in a string.",
		name = "gfind",
		realm = "client",
		params = {
			{
				type = "string",
				name = "haystack",
				description = "The string to search in"
			},
			{
				type = "string",
				name = "needle",
				description = "The string to find, can contain patterns if enabled"
			},
			{
				type = "number?",
				name = "startPos",
				description = "The position to start the search from, can be negative start position will be relative to the end position"
			},
			{
				type = "boolean?",
				name = "noPatterns",
				description = "Disable patterns"
			}
		}
	}
end)