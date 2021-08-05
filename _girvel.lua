local fnl = require "fnl"
local yaml = require "lyaml"
local inspect = require "inspect"

local _girvel = {}

-- TODO piped inspect
-- TODO optimization: pipe + ipairs
_girvel.slice = 
	fnl.docs{
		type='pipe function',
		returns='slice of the sequence'
	} ..
	fnl.pipe() ..
	function(t, first, last, step)
		if last and last < 0 then
			last = #t - last + 1
		end
	
		local result = {}
		for i = first or 1, last or #t, step or 1 do
			table.insert(result, t[i])
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

_girvel.map = 
	fnl.docs{} ..
	fnl.pipe() ..
	function(t, f)
		local result = {}
		for ix, it in ipairs(t) do
			table.insert(result, f(it))
		end
		return result
	end

_girvel.separate = 
	fnl.docs{
		type='pipe function'
	} ..
	fnl.pipe() ..
	function(t, separator)
		if #t == 0 then return {} end
	
		local result = {t[1]}
		for i = 2, #t do
			table.insert(result, separator)
			table.insert(result, t[i])
		end
		return result
	end

_girvel.join = 
	fnl.docs{} ..
	fnl.pipe() ..
	function(t, metamethod)
		metamethod = metamethod or "__add"
		
		if #t == 0 then return end

		local result = t[1]
		
		for i = 2, #t do
			result = getmetatable(result)[metamethod](result, t[i])
		end
		return result
	end

_girvel.yaml_container = 
	fnl.docs{
		type='function',
		description='reads & writes to yaml file',
		args={'path to the file'}
	} ..
	function(path)
		local folder_path = (path / "/") / _girvel.slice(nil, -2)
	
		return setmetatable({
			get=function()
				local file = io.open(".crater/config.yaml", "r")
				local result = file:read("*a")
				file:close()
				return yaml.load(result)
			end,
			set=function(t)
				print(mkdir("-p .crater"))
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
	end

return _girvel
