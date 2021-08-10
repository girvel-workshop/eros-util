local g = require "_girvel"
local fnl = require "fnl"
local yaml = require "lyaml"
require "strong"

local sh = require "sh"
-- TODO dependencies
-- TODO .gitignore
-- TODO cd to root directory
-- TODO upload to luarocks

local behaviour, prompt, config, keychain, state, rockspec, control

behaviour = {
	init=fnl.docs[[make current directory a crate]] .. function(self)
		print(git("init"))

		config:set_yaml{
			name=prompt("project name", tostring(basename("$PWD"))),
			version=prompt("version", "0.1-0"),
			build_systems=prompt("build systems (love, luarocks, dpkg)", "luarocks")
				:split("%s*,%s*") / g.set(),
			luarocks=prompt("luarocks support (yes/no)", "yes") ~= "no"
		}
		keychain:set_yaml{}

		config.git_origin = prompt("git repository", tostring(git("remote get-url origin")))
		git("remote add origin " .. config.git_origin)

		gitignore:set(
			{keychain.path, ".crater/build*", ".crater/source*"}
				/ g.separate("\n") 
				/ g.join()
		)

		if config.luarocks then
			keychain.luarocks = prompt("luarocks API key")
		end

		if config.build_systems.luarocks then
			rockspec = g.file_container("%s-%s.rockspec" % {config.name, config.version})
			rockspec:set([[
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
		end

		if config.build_systems.dpkg then
			control:set([[
Package: %s
Version: %s
Section: custom
Prority: optional
Architecture: all
Essential: no
Installed-Size: 1024
Maintainer: girvel
Description: Launcher for a rock %s
			]] % {config.name, config.version, config.name})
		end
	end,
	
	commit=fnl.docs[[alias for git add, commit & push]] .. function(self, name)
		print(git("add ."))
		print(git('commit -m "%s"' % name))
		print(git('push origin master'))
	end,
	
	stat=fnl.docs[[show crate statistics]] .. function(self)
		print("crate", config.name)
		local content = find("./ -name '*.lua' -print0") : xargs("-0 cat")
		print("Lines:", content : wc("-l"))
		print("Words:", content : wc("-w"))
		print("Chars:", content : wc("-m"))
	end,
		
	build=fnl.docs[[builds]] .. function(self, type)
		type = type or "build"
		
		local index = ({major=1, minor=2, build=3})[type]
		local version = state.get_version()
		version[index] = version[index] + 1
		state.set_version(version)

		for build_type, _ in pairs(config.build_systems) do
			behaviour["build_" .. build_type](self)
		end
	end,

	build_dpkg=function(self)
		g.file_container(".crater/source-dpkg/usr/bin/" .. config.name):set(
			'#!/usr/bin/bash\nlua $(luarocks which %s | head -n 1) "$@"'
				% config.name
		)
		chmod("+x .crater/source-dpkg/usr/bin/" .. config.name)
		mkdir("-p .crater/source-dpkg/DEBIAN")
		cp("control", ".crater/source-dpkg/DEBIAN/")
		
		print(sh.command('dpkg-deb')("--build .crater/source-dpkg"))
		mkdir("-p .crater/build-dpkg")
		mv(
			".crater/source-dpkg.deb", 
			'.crater/build-dpkg/%s.deb' % state.get_full_name()
		)
	end,

	build_luarocks=function(self)
		print(git("add ."))
		print(git("commit -m 'source for build %s'" % config.version))
		print(git("tag -a '%s' -m 'version %s'" % {config.version, config.version}))
		
		print(git("push origin master"))
		print(git("push origin --tags"))
		
		print(luarocks("pack %s.rockspec" % state.get_full_name()))
		mkdir("-p .crater/build-luarocks")
		mv("*.rock .crater/build-luarocks/")
	end,

	install=function(self)
		for build_type, _ in pairs(config.build_systems) do
			behaviour["install_" .. build_type](self)
		end
	end,

	install_dpkg=function(self)
		sudo("dpkg --install .crater/build-dpkg/%s.deb" % state.get_full_name())
	end,

	install_luarocks=function(self)
		luarocks("install .crater/build-luarocks/%s.src.rock --local" % state.get_full_name())
	end,
	
	help=fnl.docs[[show help]] .. function(self)
		for name, f in pairs(behaviour) do
			if fnl.docs[f] then
				print(name, "-", fnl.docs[f])
			else
				print(name)
			end
		end
	end,

	["--version"]=fnl.docs[[show version]] .. function(self)
		print(config.version)
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
rockspec = g.file_container(tostring(ls('*.rockspec')))
control = g.file_container("control")
gitignore = g.file_container(".gitignore")

state = {
	get_version=function()
		return config.version:gsub("-", ".") / "." / g.map(tonumber)
	end,
	set_version=function(value)
		local old_version = config.version
		config.version = "%s.%s-%s" % value

		if config.build_systems.luarocks then
			rockspec.path = "%s-%s.rockspec" % {config.name, config.version}
			mv("*.rockspec", rockspec.path)
			rockspec:set(rockspec:get()
				:gsub('version="%S*"', 'version="%s"' % config.version)
				:gsub('tag="%S*"', 'tag="%s"' % config.version)
			)
		end

		if config.build_systems.dpkg then
			control:set(control:get()
				:gsub('Version: %S*', 'Version: ' .. config.version)
			)
		end
	end,
	get_full_name=function()
		return config.name .. "-" .. config.version
	end
}

method = behaviour[arg[1]] or behaviour["help"]
method(behaviour, arg / g.slice(2) / g.unpack())
