SF.Modules.jacboStringGmatch = {injected = {init = function(instance)
	instance.Libraries.string.ggmatch = string.gmatch
end}}

require("inject_sf_docs")
jacbo.sfDocInject(function()
	SF.Docs.Libraries.string.methods.ggmatch = {
		class = "function",
		description = "Unrestricted glua string.gmatch. Using Patterns, returns an iterator which will return either one value if no capture groups are defined, or any capture group matches.",
		name = "ggmatch",
		realm = "client",
		params = {
			{
				type = "string",
				name = "data",
				description = "The string to search in"
			},
			{
				type = "string",
				name = "pattern",
				description = "The pattern to search for"
			}
		}
	}
end)