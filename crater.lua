local g = require "_girvel"
local fnl = require "fnl"
local yaml = require "lyaml"
require "strong"

local sh = require "sh"
-- TODO dependencies
-- TODO .gitignore
-- TODO cd to root directory

local behaviour, prompt, config, keychain, state

behaviour = {
	init=fnl.docs[[make current directory a crate]] .. function()
		print(git("init"))

		config:set_yaml{
			name=prompt("project name", tostring(basename("$PWD"))),
			version=prompt("version", "0.1-0"),
			type=prompt("type (lua|love|unix)"),
			platforms=prompt("platforms (git, luarocks)"):split("%s*,%s*") / g.set()
		}
		keychain:set_yaml{}

		if config.platforms["git"] then
			config.git_origin = prompt("git repository", git("remote get-url origin"))
			git("remote add origin " .. config.git_origin)

			echo(keychain.path):tee("-a .gitignore")
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
	
	commit=fnl.docs[[alias for git add, commit & push]] .. function(name)
		print(git("add ."))
		print(git('commit -m "%s"' % name))
		print(git('push origin master'))
	end,
	
	stat=fnl.docs[[show crate statistics]] .. function()
		print("crate", config.name)
		local content = find("./ -name '*.lua' -print0"):xargs("-0 cat")
		print("Lines:", content:wc("-l"))
		print("Words:", content:wc("-w"))
		print("Chars:", content:wc("-m"))
	end,
		
	build=fnl.docs[[builds]] .. function()
		return behaviour["build." .. config.type]
	end,

	["build.unix"]=function()
		
	end,
	
	help=fnl.docs[[show help]] .. function()
		for name, f in pairs(behaviour) do
			if fnl.docs[f] then
				print(name, "-", fnl.docs[f])
			else
				print(name)
			end
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
keychain = g.yaml_container('.crater/keychain.yaml')
state = g.property_container{
	get_version=function(self)
		return config.version:gsub("-") / "." / g.map(tonumber)
	end,
	set_version=function(self, value)
		config.version = "%s.%s-%s" % value
		mv("*.rockspec", "%s-%s.rockspec" % {config.name, config.version})
		
	end
}

method = behaviour[arg[1]] or behaviour["help"]
method(arg / g.slice(2) / g.unpack())
