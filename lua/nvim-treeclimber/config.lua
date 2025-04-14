---@class treeclimber.Config
---@field private opt? treeclimber.Opt
local Config = {}

-- The Config instance is a singleton, which holds a single Opt at a time.
local Opt = require"nvim-treeclimber.opt"

-- Create some type aliases for configuration parameters.

-- ** Keymaps **
---@alias treeclimber.KeymapEntryTable
---| [(string|string[]), string]

---@alias treeclimber.KeymapEntry
---| boolean
---| string
---| treeclimber.KeymapEntryTable
---| treeclimber.KeymapEntryTable[]

---@alias treeclimber.KeymapEntryCanon
---| treeclimber.KeymapEntryTable[]

-- ** Highlights **
---@alias treeclimber.HighlightEntry
---| fun(normal: HSLUVHighlight, visual: HSLUVHighlight) : vim.api.keyset.highlight
---| vim.api.keyset.highlight
---| boolean
---| nil

---@alias treeclimber.HighlightEntryCanon
---| fun(normal: HSLUVHighlight, visual: HSLUVHighlight) : vim.api.keyset.highlight
---| vim.api.keyset.highlight

-- TODO: Move this to config.lua, having it passed to constructor.
-- The default option table
local defaults = {
	keys = {
		show_control_flow = { "n", "<leader>k"},
		select_current_node = {
			{"n", "<A-k>"},
			{{ "x", "o" }, "i."}},
		-- TODO: These two seem to be misnamed.
		select_siblings_backward = {{ "n", "x", "o" }, "<M-[>"},
		select_siblings_forward = {{ "n", "x", "o" }, "<M-]>"},
		select_top_level = {{ "n", "x", "o" }, "<M-g>"},
		select_forward = {{ "n", "x", "o" }, "<M-l>"},
		select_backward = {{ "n", "x", "o" }, "<M-h>"},
		select_forward_end = {{ "n", "x", "o" }, "<M-e>"},
		select_grow_forward = {{ "n", "x", "o" }, "<M-L>"},
		select_grow_backward = {{ "n", "x", "o" }, "<M-H>"},
		select_expand = {
			{{"x", "o"}, "a."},
			{{"n", "x", "o"}, "<M-k>"}
		},
		select_shrink = {{ "n", "x", "o" }, "<M-j>"},
	},
	highlights = {
		TreeClimberHighlight = function(_, visual) return { bg = visual.bg.hex } end,
		TreeClimberSiblingBoundary = function(normal, visual) return { bg = visual.bg.mix(normal.bg, 50).hex } end,
		TreeClimberSibling = function(normal, visual) return { bg = visual.bg.mix(normal.bg, 50).hex } end,
		TreeClimberParent = function(normal, visual) return { bg = visual.bg.mix(normal.bg, 50).hex } end,
		TreeClimberParentStart = function(normal, visual) return { bg = visual.bg.mix(normal.bg, 50).hex } end,
	},
	traversal = {
	},
	display = {
	}
}

-- Define some helpers.
function Config.is_mode(x)
	-- TODO: Decide how many of these should be supported?
	return type(x) == "string" and x:match("^[nvxsoi!]?$")
end
function Config.is_mode_array(x)
	return vim.islist(x) and vim.iter(x):all(function(x_) return Config.is_mode(x_) end)
end
function Config.is_keymap_entry(x)
	return vim.islist(x) and #x == 2 and (Config.is_mode(x[1]) or Config.is_mode_array(x[1]))
		and type(x[2]) == "string"
end
function Config.is_keymap_entry_array(x)
	return vim.islist(x) and vim.iter(x):all(function (x_) return Config.is_keymap_entry(x_) end)
end

function Config:new()
	local obj = {
		-- Start with a default Opt, which may be overridden later with setup().
		opt = Opt:new(defaults)
	}
	self.__index = self
	return setmetatable(obj, self)
end

---@param opt? table
function Config:setup(opt)
	self.opt = Opt:new(defaults, opt)
end

-- Get default option value for fully-qualified name.
---@param fqn string[]|string
function Config:get_default(fqn)
	return self.opt:get(fqn, {want_default = true})
end

---@param fqn string[]|string
function Config:get(fqn)
	return self.opt:get(fqn)
end


-- Create and return singleton Config for treeclimber.
-- Note: The default Opt it contains will be replaced if the setup() method is subsequently called.
return Config:new()
