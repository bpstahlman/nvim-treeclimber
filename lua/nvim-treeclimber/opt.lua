---@class treeclimber.Opt
---@field private defaults table<string,any>
---@field private current? table<string,any>
local Opt = {}

local dbg = require'dp':get('treeclimber')

---@param how "warning"|"error"|"exception"
---@param str string the formatting string
---@param ... any
local function notify(how, str, ...)
	str = string.format(str, ...)
	if how == "exception" then
		error(str)
	else
		vim.api.nvim_echo({{str , how == "warning" and "hl-WarningMsg" or "hl-ErrorMsg"}},
			true, {})
	end
end

---@param fqn string|string[]
---@return string[]
function Opt:parse_fqn(fqn)
	-- TODO: More validation for table?
	if type(fqn) == "string" then
		fqn = vim.split(fqn, "[.]")
	end
	-- Validate name components all look like normal keys.
	assert(vim.iter(fqn):all(function(x) return x:match("[%w_]+") end),
		"Bad fully-qualified option name: " .. vim.inspect(fqn))
	return fqn
end

---@package
---@param opt? table Table to override defaults
function Opt:merge_current(opt)

	dbg:logf("merging %s over %s", opt and vim.inspect(opt) or "nilly", vim.inspect(self.defaults))
	self.current = vim.tbl_deep_extend('force', self.defaults, opt or {})
	dbg:logf("After merge, current=%s", vim.inspect(self.current))
end

-- TODO: Decide whether to allow opt to be supplied at construction.
---@param defaults table
---@param opt? table
function Opt:new(defaults, opt)
	-- Note: current may be undefined.
	local obj = { defaults = defaults }
	self.__index = self
	setmetatable(obj, {__index = self})
	-- Defer override of current until we have opt.
	if opt then
		obj:merge_current(opt)
	end
	return obj
end

-- TODO: Perhaps rename to set()
---@param fqn string|string[]
---@param value any
function Opt:__newindex(fqn, value)
	local keyarr = self:parse_fqn(fqn)
	if not keyarr or #keyarr == 0 then
		-- Shouldn't happen, but nothing to do.
		return
	end
	--assert(self.current, "Internal error: Attempt to assign to nil current table")
	if not self.current then
		self:merge_current()
	end
	local last = vim.iter(keyarr)
		:take(#keyarr - 1)
		:fold(self.current, function (acc, k)
			if acc[k] == nil then
				acc[k] = {}
			end
			return acc[k]
		end)
	last[keyarr[#keyarr]] = value
end


-- TODO: Consider always returning multiple values (overridden, default)
---@param fqn string|string[] Fully-qualified option name string, either as array of components or dot-separated string
---@param missing? {notify: "warning"|"error"|"assert", want_default: boolean, repair: boolean, fallback: boolean}
---@param default? any
function Opt:get(fqn, missing, default)
	missing = vim.tbl_deep_extend("force",
		{notify = "error", want_default = false, repair = true, fallback = true}, missing or {})
	-- FIXME: Streamline validation.
	assert(not missing.notify or vim.list_contains({"warning", "error", "assert"}, missing.notify),
		"Invalid value provided for missing.notify: " .. vim.inspect(missing.notify))
	-- Subsequent logic needs an options table, either user's current override (if one exists
	-- and defaults not explicitly requested) or the defaults
	local opt = not missing.want_default and self.current or self.defaults
	-- Input fqn can be in either of two forms: make sure we have it in valid array form.
	local keyarr = self:parse_fqn(fqn)
	-- Validate name components all look like normal keys.
	assert(vim.iter(keyarr):all(function(x) return x:match("[%w_]+") end),
		"Bad fully-qualified option name: " .. fqn)
	local v = vim.tbl_get(opt, unpack(keyarr))
	if missing.notify == "assert" then
		assert(v ~= nil, "Requested option not found: %s", fqn)
	end
	if v == nil then
		-- Option not found
		-- This should never happen if user hasn't overridden config.
		assert(opt ~= self.defaults, "Internal error: Requested option not defined: " .. fqn)
		-- User's override must have clobbered something.
		if missing.notify then
			-- TODO: err() function, possibly renaming.
			notify(missing.notify, "Requested option not defined: %s", fqn)
		end
		-- Has caller supplied a default? If so, return it, without regard to missing.fallback.
		local dvalue
		if default ~= nil then
			dvalue = default
		elseif missing.fallback then
			-- Return plugin-defined default (which should definitely exist).
			dvalue = vim.tbl_get(self.defaults, unpack(keyarr))
			assert(dvalue ~= nil, "Internal error: requested option not defined: " .. fqn)
		end
		if missing.repair and dvalue ~= nil then
			-- We have a fallback and repair is enabled.
			-- Assumption: An earlier assert() ensures we arrive here only when user
			-- has overridden defaults.
			self[keyarr] = dvalue
		end
	end
	return v
end

return Opt
