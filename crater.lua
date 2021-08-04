local g = require "_girvel"
local sh = require "sh"

behaviour = {
	init=function()
		print(git("init"))
	end
}

behaviour[arg[1]](arg / g.slice(2) / g.unpack())
