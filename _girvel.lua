local fnl = require "fnl"
local yaml = require "lyaml"
local exception = require "exception"

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
			last = #t + last + 1
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

_girvel.inspect = 
	fnl.docs{} ..
	fnl.pipe() ..
	require "inspect"

_girvel.file_container =
	fnl.docs{
		type='function',
		description='creates a table to read & write a file'
	} ..
	function(path)
		local folder_path = path / "/"
			/ _girvel.slice(1, -2)
			/ _girvel.separate("/")
			/ _girvel.join() or "."

		return {
			path=path,
			folder_path=folder_path,
			get=function(self)
				local file = io.open(self.path, "r")

				if not file then
					exception.throw{message="file %s does not exist" % self.path}
				end
				
				local result = file:read("*a")
				file:close()
				return result
			end,
			set=function(self, content)
				print(mkdir("-p " .. self.folder_path))
				local file = io.open(self.path, "w")
				file:write(content)
				file:close()
			end
		}
	end

_girvel.yaml_container = 
	fnl.docs{
		type='function',
		description='creates a table to read & write to yaml file',
		args={'path to the file'}
	} ..
	function(path)
		local file_container = _girvel.file_container(path)

		file_container.get_yaml = function(self)
			return yaml.load(self:get())
		end

		file_container.set_yaml = function(self, t)
			self:set(yaml.dump{t}:sub(5, -5))
		end
	
		return setmetatable(file_container, {
			__index=function(self, index)
				return self:get_yaml()[index]
			end,
			__newindex=function(self, index, value)
				local content = self:get_yaml()
				content[index] = value
				self:set_yaml(content)
			end
		})
	end

_girvel.property_container = 
	fnl.docs{} ..
	function(t)
		-- TODO tk.copy(t, true)
		return setmetatable(t, {
			__index=function(self, index)
				return self["get_" .. index](self)
			end,
			__newindex=function(self, index, value)
				return self["set_" .. index](self, value)
			end
		})
	end

return _girvel
