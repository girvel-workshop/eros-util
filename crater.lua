local g = require "_girvel"
local fnl = require "fnl"
local yaml = require "lyaml"
require "strong"

local http = require "socket.http"
local ltn12 = require "ltn12"

local sh = require "sh"
-- TODO dependencies
-- TODO .gitignore
-- TODO cd to root directory

local prompt, config, state

behaviour = {
	init=function()
		print(git("init"))

		config:set{
			name=prompt("project name", tostring(basename("$PWD"))),
			version=prompt("version", "0.1-0"),
			type=prompt("type (lua|love)"),
			platforms=prompt("platforms (git, luarocks)"):split("%s*,%s*") / g.set()
		}

		if config.platforms["git"] then
			
		end
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

config = g.yaml_container('.crater/config.yaml')
state = g.property_container{}

behaviour[arg[1]](arg / g.slice(2) / g.unpack())
