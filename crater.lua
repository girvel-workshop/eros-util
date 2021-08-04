local g = require "_girvel"
local yaml = require "lyaml"
require "strong"

local sh = require "sh"
-- TODO dependencies

local prompt, config, state

behaviour = {
	init=function()
		print(git("init"))
		print(mkdir("-p .crater"))

		config.set{
			name=prompt("project name", tostring(basename("$PWD"))),
			version=prompt("version", "0.1-0")
		}
	end
}

function prompt(query, default_value)
	io.write(query)

	if default_value then
		io.write(" [", default_value, "]")
	end
	print(":")

	io.write("  ")
	input = io.read()

	if input == "" and default_value then
		return default_value
	end

	return input
end

config = setmetatable({
	get=function()
		local file = io.open(".crater/config.yaml", "r")
		local result = file:read("*a")
		file:close()
		return result
	end,
	set=function(t)
		local file = io.open(".crater/config.yaml", "w")
		file:write(yaml.dump{t}:sub(5, -5))
		file:write("\n")
		file:close()
	end
}, {
	__index=function(_, index)
		return config.get()[index]
	end,
	__newindex=function(_, index, value)
		local content = config.get()
		content[index] = value
		config.set(content)
	end
})

-- TODO property container
state = setmetatable({
	
}, {
	__index=function(self, index)
		return self["get_" .. index]()
	end,
	__newindex=function(self, index, value)
		return self["set_" .. index](value)
	end
})

behaviour[arg[1]](arg / g.slice(2) / g.unpack())
