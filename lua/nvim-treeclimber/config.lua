---@class treeclimber.Config
---@field private opt? treeclimber.Opt
local Config = {}

-- The Config instance is a singleton, which holds a single Opt at a time.
local Opt = require"nvim-treeclimber.opt"

-- Create some type aliases for configuration parameters.

-- ** Keymaps **
---@alias modestr "n"|"v"|"x"|"o"|"s"|"i"|"!"|""
---@alias lhs string # Used as <lhs> in call to `vim.keymap.set`
---@alias treeclimber.KeymapSingle
---| [(modestr|modestr[]), lhs]     # override the default <lhs> and/or modes
---@alias treeclimber.KeymapEntry
---| boolean                        # true to accept default, false to disable
---| nil                            # accept default (same as omitting the command name from table)
---| lhs                            # override the default <lhs> (keeping mode(s))
---| treeclimber.KeymapSingle       # override the default <lhs> and/or modes
---| treeclimber.KeymapSingle[]     # idem, but allows multiple, mode-specific <lhs>'s
---All KeymapEntry's will be converted to this by successful validation.
---@alias treeclimber.KeymapEntryCanon
---| false
---| treeclimber.KeymapSingle[]

-- ** Highlights **
---@alias treeclimber.HighlightCallback
---| fun(o: {normal: HSLUVHighlight, visual: HSLUVHighlight}) : vim.api.keyset.highlight

---@alias treeclimber.HighlightEntry
---| treeclimber.HighlightCallback
---| vim.api.keyset.highlight
---| boolean
---| nil

-- Deferred or default canonical: ie, either canonical or should will expand to canonical.
---@alias treeclimber.HighlightEntryDefCanon
---| fun(o: {normal: HSLUVHighlight, visual: HSLUVHighlight}) : vim.api.keyset.highlight
---| vim.api.keyset.highlight
---| false

---@alias treeclimber.HighlightEntryCanon
---| vim.api.keyset.highlight
---| false

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
	display = {
		regions = {
			highlights = {
				Selection = function(o) return { bold = true, bg = o.visual.bg.hex } end,
				SiblingStart = false,
				Sibling = function(o) return { bg = o.visual.bg.mix(o.normal.bg, 50).hex } end,
				Parent = function(o) return { bg = o.visual.bg.mix(o.normal.bg, 80).hex } end,
				ParentStart = false,
			},
			inherit_attrs = true
		},
	},
	traversal = {
	},
}

-- Define some helpers.
function Config.is_mode(x)
	return type(x) == "string" and x:match("^[nvxosi!]?$")
end

function Config.is_mode_array(x)
	return vim.islist(x) and vim.iter(x):all(function(x_) return Config.is_mode(x_) end)
end

-- Return true if input is of type treeclimber.KeymapSingle
-- TODO: Consider adding an is_loose_keymap_entry function or somesuch, which doesn't validate
-- modes.
-- Rationale: Could be used to provide better error diagnostics.
function Config.is_keymap_single(x)
	return vim.islist(x) and #x == 2 and (Config.is_mode(x[1]) or Config.is_mode_array(x[1]))
		and type(x[2]) == "string"
end

-- Return true if input is an array of treeclimber.KeymapSingle
function Config.is_keymap_entry_array(x)
	return vim.islist(x) and vim.iter(x):all(function (x_) return Config.is_keymap_single(x_) end)
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
