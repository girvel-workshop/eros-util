local g = require "_girvel"
local yaml = require "lyaml"
require "strong"

local sh = require "sh"
-- TODO dependencies

local prompt

behaviour = {
	init=function()
		print(git("init"))
		print(mkdir("-p .crater"))

		local config = io.open(".crater/config.yaml", "w")
		config:write(yaml.dump{{
			name=prompt("project name")
		}}:sub(5, -5))
		config:write("\n")
		config:close()
	end
}

function prompt(query, default_value)
	io.write(query)

	if default_value then
		io.write(" [%s]" % default_value)
	end
	print(":")

	io.write("  ")
	input = io.read()

	if input == "" and default_value then
		return default_value
	end

	return input
end

behaviour[arg[1]](arg / g.slice(2) / g.unpack())
