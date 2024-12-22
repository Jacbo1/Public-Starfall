local inf = math.huge

local checkLuaType = SF.CheckLuaType
local debug_getmetatable = debug.getmetatable

SF.Permissions.registerPrivilege("client inject phys obj", "Phys Obj Init", "Allows the user to init physics objects on the client", { client = {default = 1} })
SF.Permissions.loadPermissions()

SF.Modules.jacboPhysObj = {injected = {init = function(instance)
	local checkPermission = instance.player ~= SF.Superuser and SF.Permissions.check or function() end
	--local checkPermission = SF.Permissions.check

	local unwrapEnt, unwrapVec, wrapObj = instance.Types.Entity.Unwrap, instance.Types.Vector.Unwrap, instance.WrapObject
	local entMetaTable, vecMetaTbl = instance.Types.Entity, instance.Types.Vector
	local entMethods = instance.Types.Entity.Methods

	--- Sets the physics object
	-- @param table Table of vectors
	function entMethods:physicsInitMultiConvex(tbl)
		checkPermission(instance, nil, "client inject phys obj")
		checkLuaType(tbl, TYPE_TABLE)

		local table_insert = table.insert
		local unwrapped = {}
		for k, subtbl in ipairs(tbl) do
			local tbl2 = {}
			for k, v in ipairs(subtbl) do
				table_insert(tbl2, unwrapVec(v))
			end
			table_insert(unwrapped, tbl2)
		end
		unwrapEnt(self):PhysicsInitMultiConvex(unwrapped)
	end

	function entMethods:enableCustomCollisions(bool)
		checkPermission(instance, nil, "client inject phys obj")
		unwrapEnt(self):EnableCustomCollisions(bool)
	end
end}}

require("inject_sf_docs")
jacbo.sfDocInject(function()
	SF.Docs.Types.Entity.methods.physicsInitMultiConvex = {
		class = "function",
		description = "Sets the physics object of the entity on the client",
		name = "physicsInitMultiConvex",
		realm = "client",
		params = {
			{
				type = "table",
				name = "vertices",
				description = "Sequential list of vectors to use as vertices"
			}
		}
	}

	SF.Docs.Types.Entity.methods.enableCustomCollisions = {
		class = "function",
		description = "Enables or disables custom clientside collisions for the entity",
		name = "enableCustomCollisions",
		realm = "client",
		params = {
			{
				type = "boolean",
				name = "enabled",
				description = "True to enable custom collisions or false to disable them"
			}
		}
	}
end)