local g = require "_girvel"
local fnl = require "fnl"
local yaml = require "lyaml"
require "strong"

local sh = require "sh"
-- TODO dependencies
-- TODO .gitignore
-- TODO cd to root directory

local prompt, config, keychain, state

behaviour = {
	init=function()
		print(git("init"))

		config:set{
			name=prompt("project name", tostring(basename("$PWD"))),
			version=prompt("version", "0.1-0"),
			type=prompt("type (lua|love)"),
			platforms=prompt("platforms (git, luarocks)"):split("%s*,%s*") / g.set()
		}
		keychain:set{}

		if config.platforms["git"] then
			config.git_origin = prompt("git repository")
			git("remote add origin " .. config.git_origin)

			echo(keychain.path):tee(".gitignore")
		end

		if config.platforms["luarocks"] then
			keychain.luarocks = prompt("luarocks API key")
			local file = io.open("%s-%s.rockspec" % {config.name, config.version}, "w")
			file:write([[
package="%s"
version="%s"
source={
	url="%s",
	tag="%s"
}
description={
	summary="none",
	license="MIT"
}
build={
	type="builtin",
	modules={
		
	}
}
			]] % {config.name, config.version, config.git_origin, config.version})
			file:close()
		end
	end,
	commit=function(name)
		print(git("add ."))
		print(git('commit -m "%s"' % name))
		print(git('push origin master'))
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
keychain = g.yaml_container('.crater/keychain.yaml')
state = g.property_container{}

behaviour[arg[1]](arg / g.slice(2) / g.unpack())
