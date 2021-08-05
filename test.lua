inspect = require "inspect"
g = require "_girvel"

print(inspect(
	{"1", "2"} / g.join()
))
