local M = {}
local tc = require("nvim-treeclimber.api")
local Config = require('nvim-treeclimber.config')
local Util = require('nvim-treeclimber.util')
local Hi = require("nvim-treeclimber.hi")

local dbg = require'dp':get('treeclimber')

-- Re-export nvim-treeclimber.api
for k, v in pairs(tc) do
	M[k] = v
end

-- Keymap descriptions
local default_keymap_descriptions = {
	show_control_flow = "",
	select_current_node = "Treeclimber select current node",
	select_forward_end = "Treeclimber select and move to the end of the node, or the end of the next node",
	-- TODO: These two seem to be misnamed.
	select_siblings_backward = "Treeclimber select first sibling node",
	select_siblings_forward = "Treeclimber select last sibling node",
	select_top_level = "Treeclimber select the top level node from the current position",
	select_backward = "Treeclimber select previous node",
	select_shrink = "Treeclimber select child node",
	select_expand = "Treeclimber select parent node",
	select_forward = "Treeclimber select the next node",
	select_grow_forward = "Treeclimber add the next node to the selection",
	select_grow_backward = "Treeclimber add the next node to the selection",
}

-- Validate the input KeymapEntry and return one of the following as the first return value:
--   a KeymapEntryCanon to use with vim.keymap.set(), taking defaults into account if applicable
--   false if the keymap should be disabled
--   nil if the entry is invalid.
---@param ut treeclimber.KeymapEntry|nil The user entry to validate (or nil to use default)
---@param dt treeclimber.KeymapEntryCanon The corresponding entry from defaults in canonical form
---@return treeclimber.KeymapEntryCanon|false|nil # Keymap entry suitable for use with vim.keymap.set() 
---                                               # false if disabled
---                                               # nil on error
local function parse_keymap_entry(ut, dt)
	if ut == nil then
		-- Note: This is not considered error, so return default as first value.
		return dt
	end
	local utyp = type(ut)
	if utyp == "boolean" then
		-- Note: Explicit false disables the map without error or warning.
		return ut and dt or false
	elseif utyp == "string" then
		-- Use default entry with overridden lhs.
		-- TODO: Warn if there really are multiple mode entries?
		return vim.iter(dt):map(function (x) return {x[1], ut} end):totable()
	end
	-- At this point, there are only two valid possibilities left.
	if Config.is_keymap_entry(ut) then
		-- Return canonical form.
		return {ut}
	elseif Config.is_keymap_entry_array(ut) then
		return ut
	end
	-- Invalid format!
	return nil
end

function M.setup_keymaps()
	---@type table<string, treeclimber.KeymapEntry>|boolean
	local ukeys = Config:get("keys")
	---@type table<string, treeclimber.KeymapEntryCanon> # Default keys
	local dkeys = Config:get_default("keys")
	-- User can set entire keys option to boolean to enable/disable *all* default maps.
	if type(ukeys) == "boolean" then
		if not ukeys then
			-- User has disabled keymaps! Nothing do do...
			return
		end
		-- User has requested defaults, either explicitly or with empty table.
		ukeys = dkeys
	elseif type(ukeys) == "table" then
		-- Make sure it's the right kind of table.
		if vim.isarray(ukeys) and not vim.tbl_isempty(ukeys) then
			Util.error("Ignoring invalid 'keys' option: %s", vim.inspect(ukeys))
			ukeys = dkeys
		else
			local unk_keys = vim.iter(vim.tbl_keys(ukeys))
				:filter(function(x) return dkeys[x] == nil end)
				:join(", ")
			if #unk_keys > 0 then
				Util.error("Ignoring user 'keys' option with invalid key(s): %s", unk_keys)
				ukeys = dkeys
			end
		end
	end
	-- Loop over default keymap entries.
	for k, dv in pairs(dkeys) do
		---@type treeclimber.KeymapEntryCanon|false
		local cfg
		-- Canonicalize default entry.
		if Config.is_keymap_entry(dv) then
			dv = {dv}
		end
		if ukeys == dkeys then
			-- No need to validate default entry
			---@cast dv treeclimber.KeymapEntryCanon
			cfg = dv
		else
			local uv = ukeys[k]
			-- Get valid KeymapEntryCanon for the current keymap.
			---@type treeclimber.KeymapEntryCanon|nil|false
			local cfg_ = parse_keymap_entry(uv, dv)
			if cfg_ == nil then
				Util.error("Ignoring invalid keymap entry for %s: %s", k, vim.inspect(uv))
				---@cast dv treeclimber.KeymapEntryCanon
				cfg = dv
			else
				-- Use value returned by parse_keymap_entry (possibly false).
				---@cast cfg_ treeclimber.KeymapEntryCanon|false
				cfg = cfg_
			end
		end
		assert(cfg == false or cfg, "Internal error: No fallback keymap entry for " .. k)
		-- One or more keymaps (corresponding to different mode sets) need to be created for
		-- the current command.
		if cfg and type(cfg) == "table" then
			-- Loop over the mode sets.
			for _, c in ipairs(cfg) do
				vim.keymap.set(c[1], c[2], tc[k], { desc = default_keymap_descriptions[k] })
			end
		end
	end
end

function M.setup_user_commands()
	vim.api.nvim_create_user_command("TCDiffThis", tc.diff_this, { force = true, range = true, desc = "" })

	vim.api.nvim_create_user_command(
		"TCHighlightExternalDefinitions",
		tc.highlight_external_definitions,
		{ force = true, range = true, desc = "WIP" }
	)

	vim.api.nvim_create_user_command("TCShowControlFlow", tc.show_control_flow, {
		force = true,
		range = true,
		desc = "Populate the quick fix with all branches required to reach the current node",
	})
end

---@param uhl treeclimber.HighlightEntry
---@param dhl treeclimber.HighlightEntryCanon
---@param normal HSLUVHighlight
---@param visual HSLUVHighlight
---@return vim.api.keyset.highlight|nil|false cfg The configuration to use or nil if error
---@return vim.api.keyset.highlight|nil fallback The fallback configuration to use on error
local function parse_highlight_entry(uhl, dhl, normal, visual)
	if type(dhl) == "function" then
		---@cast dhl vim.api.keyset.highlight
		dhl = dhl(normal, visual)
	end
	if uhl == true or uhl == nil then
		return dhl -- use default
	elseif uhl == false then
		-- Disable this one.
		return false
	end
	-- User provided some sort of override requiring validation (possibly after expansion).
	if type(uhl) == "function" then
		uhl = uhl(normal, visual)
	end
	-- Validate the user highlight entry by using in protected call to nvim_set_hl().
	local validation_ns = vim.api.nvim_create_namespace("treeclimber.validation")
	local valid, _ = pcall(vim.api.nvim_set_hl, validation_ns, "ValidationGroup", uhl)
	if not valid then
		Util.error("Ignoring invalid user highlight configuration entry: %s", vim.inspect(uhl))
		return dhl
	end
	-- Now that we know user config is valid, merge it with default.
	return vim.tbl_deep_extend('force', dhl, uhl)
end

function M.setup_highlight()
	-- Must run after colorscheme or TermOpen to ensure that terminal_colors are available

	local Normal = Hi.get_hl("Normal", { follow = true })
	assert(not vim.tbl_isempty(Normal), "hi Normal not found")
	local normal = Hi.HSLUVHighlight:new(Normal)

	local Visual = Hi.get_hl("Visual", { follow = true })
	assert(not vim.tbl_isempty(Visual), "hi Visual not found")
	local visual = Hi.HSLUVHighlight:new(Visual)

	local defaults = Config:get_default("highlights")
	-- Get user overrides.
	local overrides = Config:get("highlights")
	-- Skip if entire "highlights" key is explicit false.
	if type(overrides) ~= "boolean" or overrides then
		if overrides ~= nil and (type(overrides) ~= "table" or vim.islist(overrides)) then
			-- TODO: Alias custom type for this?
			Util.error("Ignoring invalid 'highlights' option: expected dictionary")
			overrides = nil
		end

		-- Loop over keys in the default table.
		for k, dv in pairs(defaults) do
			-- Note: luals requires an extra nil-check on overrides for some reason.
			local uv = (overrides == true or overrides == nil) and dv or overrides and overrides[k]
			-- uv can be explicit false at this point.
			if uv then
				-- Validate and merge to get the vim.api.keyset.highlight to use.
				local cfg, fallback = parse_highlight_entry(uv, dv, normal, visual)
				-- Note: If cfg is explicit false, just skip.
				if cfg or cfg == nil then
					if cfg == nil then
						-- TODO: Warn about fallback.
						Util.error("Ignoring invalid highlights config for " .. k .. ": "
							.. vim.inspect(uv))
					end
					assert(cfg or fallback, "Internal error: Fallback highlight for " .. k .. " is nil")
					vim.api.nvim_set_hl(0, k, cfg or fallback or {})
				end
			end
		end
	end
end

function M.setup_augroups()
	local group = vim.api.nvim_create_augroup("nvim-treeclimber-colorscheme", { clear = true })

	vim.api.nvim_create_autocmd({ "Colorscheme" }, {
		group = group,
		pattern = "*",
		callback = function()
			M.setup_highlight()
		end,
	})
end

---@param opt table?
function M.setup(opt)
	if opt then
		-- If user provided an option table, persist it; otherwise, stick with defaults.
		Config:setup(opt)
	end
	M.setup_keymaps()
	M.setup_user_commands()
	M.setup_augroups()
end

return M
