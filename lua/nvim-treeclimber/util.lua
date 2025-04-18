---@class treeclimber.Util
local Util = {}

---@param how "warning"|"error"|"exception"
---@param str string the formatting string
---@param ... any
function Util.notify(how, str, ...)
	str = string.format("Treeclimber: " .. str, ...)
	if how == "exception" then
		error(str)
	else
		vim.api.nvim_echo({{str , how == "warning" and "WarningMsg" or "ErrorMsg"}},
			true, {})
	end
end

function Util.warn(str, ...)
	Util.notify("warning", str, ...)
end

function Util.error(str, ...)
	Util.notify("error", str, ...)
end


return Util
