local g = require "_girvel"

behaviour = {
	init=function(dummy_argument)
		print(dummy_argument)
	end
}

behaviour[arg[1]](arg / g.slice(2) / g.unpack())
