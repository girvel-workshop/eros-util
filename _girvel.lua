local fnl = require "fnl"

local _girvel = {}

_girvel.slice = 
	fnl.docs{
		type='pipe function',
		returns='slice of the sequence'
	} ..
	fnl.pipe() ..
	function(t, first, last, step)
		local result = {}
		for i = first or 1, last or #t, step or 1 do
			result[#result + 1] = t[i]
		end
		return result
	end

-- TODO pipe functions as normal functions
_girvel.unpack =
	fnl.docs{
		type='pipe function',
		description='pipe function for table.unpack / unpack'
	} ..
	fnl.pipe() ..
	table.unpack or unpack

_girvel.set =
	fnl.docs{
		type='pipe function',
		description='transforms the sequence to a set'
	} ..
	fnl.pipe() ..
	function(t)
		local result = {}
		for _, v in ipairs(t) do
			result[v] = true
		end
		return result
	end

return _girvel
