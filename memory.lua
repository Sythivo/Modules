--[=[
	memory.lua
	
	light-weight collection management and cleaner

	author: Sythivo
--]=]

local memory = ({});

local IDisposable_Keys = ({
	'Dispose'; 'dispose';
});

local get_next = function(table, keys)
	for _, key in keys do
		local value = table[key];
		if (value) then
			return value;
		end
	end
end;

local super_dispose = function(object : any)
	local method = (memory.methods[typeof(object)]);

	if (method and type(method) == "function") then
		local success, err = pcall(method, object);
		if (not success) then
			warn(("[Memory] Failed to CleanUp : %s"):format(err))
		end
		return (true);
	end
	return (false);
end

memory.methods = ({
	["table"] = function(table : {any})
		local IDisposable = (get_next(table, IDisposable_Keys));
		if (type(IDisposable) == "function") then
			return IDisposable(table);
		end
		
		for index, value in table do
			super_dispose(value);
			table[index] = (nil);
		end
	end,
	["Instance"] = function(Instance : Instance)
		if (Instance:IsA("Tween")) then
			Instance:Cancel();
		end
		Instance:Destroy();
	end,
	["RBXScriptConnection"] = function(RBXScriptConnection : RBXScriptConnection)
		RBXScriptConnection:Disconnect();
	end,
});

function memory.new()
	local self = ({});
	
	self.collection = ({});

	function self:Add<T...>(... : T...) : (T...)
		local request = ({...});
		
		for _, value in next, (request) do
			table.insert(self.collection, value);
		end
		
		return ...;
	end
	function self:Remove(index : number): ()
		if (self.collection[index]) then
			self.collection[index] = nil
		end
	end
	function self:Get(index : number): (any)
		return self.collection[index];
	end
	function self:Clean(index : number?)
		if (index) then
			if (self.collection[index]) then
				super_dispose(self.collection[index]);
				self:Remove(index);
			end
		else
			for index : number, value : any in ipairs(self.collection) do
				super_dispose(value);
				self:Remove(index);
			end
		end
	end
	
	return self;
end

return memory;
