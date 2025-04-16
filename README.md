# Nvim-Treeclimber

Neovim plugin for treesitter based navigation and selection.
Takes inspiration from [ParEdit](https://calva.io/paredit/).

Requires neovim >= 0.10.

## Usage

### Navigation

The following table lists the treeclimber navigation commands, along with their default keybindings.
See [Configuration](#configuration) for details on changing the defaults.

| Key binding   | Action                                                                                                                                                                            | Demo                                                                                                                          |
| ------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `alt-h`       | Select the previous sibling node.                                                                                                                                                 | ![select-prev](https://user-images.githubusercontent.com/3162299/203088192-5c3a7f49-aa8f-4927-b9f2-1dc9c5245364.gif)          |
| `alt-j`       | Shrink selection. The video also shows growing the selection first. Shrinking selects a child node from the current node, or will undo the action of a previous expand operation. | ![select-shrink](https://user-images.githubusercontent.com/3162299/203088198-1c326834-bf6f-4782-9750-a04e319d449d.gif)        |
| `alt-k`       | Expand selection by selecting the parent of the current node or node under the cursor.                                                                                            | ![select-expand](https://user-images.githubusercontent.com/3162299/203088161-c29d3413-4e58-4da4-ae7e-f8ab6b379157.gif)        |
| `alt-l`       | Select the next sibling node.                                                                                                                                                     | ![select-next](https://user-images.githubusercontent.com/3162299/203088185-3f0cb56a-a6b0-4f02-b402-c1bd8adbacae.gif)          |
| `alt-shift-l` | Add the next sibling to the selection.                                                                                                                                            | ![grow-selection-next](https://user-images.githubusercontent.com/3162299/203088148-4d486a42-4359-436b-b446-f1947bf4ec46.gif)  |
| `alt-shift-h` | Add the previous sibling to the selection.                                                                                                                                        | ![grow-selection-prev](https://user-images.githubusercontent.com/3162299/203088157-84a4510e-eb5c-4689-807a-6540c0593098.gif)  |
| `alt-[`       | Select the first sibling relative to the current node.                                                                                                                            | ![select-first-sibling](https://user-images.githubusercontent.com/3162299/203088171-94a044e4-a07d-428b-a2be-c62dfc061672.gif) |
| `alt-]`       | Select the last sibling relative to the current node .                                                                                                                            | ![select-last-sibling](https://user-images.githubusercontent.com/3162299/203088178-5c8a2286-1b67-48c6-be6d-16729cb0851c.gif)  |
| `alt-g`       | Select the top level node relative to the cursor or selection.                                                                                                                     | ![select-top-level](https://user-images.githubusercontent.com/3162299/203088210-2846ab50-18ff-48d2-aef1-308369cbc395.gif)     |

### Inspection

| Key binding | Action                                                                      | Demo                                     |
| ----------- | --------------------------------------------------------------------------- | ---------------------------------------- |
| `leader-k`  | Populate the quick fix with all branches required to reach the current node | [:TCShowControlFlow](#tcshowcontrolflow) |

### Commands

#### :TCDiffThis

Diff two visual selections based on their AST difference.
Requires that [difft](https://github.com/Wilfred/difftastic) is available in your path.

To use, make your first selection and call `:TCDiffThis`, then make your second selection and call `:TCDiffThis` again.

[tc-diff-this.webm](https://user-images.githubusercontent.com/3162299/203088217-a827f8fc-ea20-4da7-95fe-884e3d82daa5.webm)

#### :TCShowControlFlow

Populate the quick fix with all branches required to reach the current node.

https://user-images.githubusercontent.com/3162299/203097777-a9a84c2d-8dec-4db8-a4c7-4c9a66ca26fe.mp4

## Installation

User your preferred package manager, or the built-in package system (`:help packages`).

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "dkendal/nvim-treeclimber",
  opts = {
    -- Provide your desired configuration here, or leave empty to use defaults.
    -- See Configuration section for details...
  },
}
```

### Bash command-line installation

```sh
mkdir -p ~/.config/nvim/pack/dkendal/opt
cd ~/.config/nvim/pack/dkendal/opt
git clone https://github.com/dkendal/nvim-treeclimber.git
```

### Neovim package system

```lua
-- ~/.config/nvim/init.lua
vim.cmd.packadd('nvim-treeclimber')

require('nvim-treeclimber').setup({ --[[ your config here ]])
```

If you do not provide an option table to `setup()` (or you provide an empty table), default options and keybindings will be used.
The following section documents the use of the option table to override defaults.

## Configuration

**To use default highlight, keymaps, and commands call `require('nvim-treeclimber').setup()` without arguments.**

To override specific elements of the default configuration, provide an option table containing only the keys you wish to change.
The default option table is provided below, with comments documenting the meaning of the various keys.
Any table you provide to `setup()` will be merged into this one (with preference given to your override), though treeclimber will generally fall back to the default with a warning if your override has an invalid format.

### Default Option Table

```lua
-- The default option table
{
  -- ** Keymaps **
  -- Each entry of the 'keys' table configures the keymap for a single treeclimber function.
  -- **Note:** The `keys` key itself can be set to a boolean to enable defaults or disable keymaps altogether.
  ---@alias modestr "n"|"x"|"o"|"v"|""|"!"
  ---@alias lhs string # Used as <lhs> in call to `vim.keymap.set`
  ---@alias KeymapEntry
  ---| boolean                        # true|nil to accept default <lhs> and mode(s)
  ---                                 # false to disable the keymap
  ---| lhs                            # override the default <lhs>
  ---| [(modestr|modestr[]), lhs]     # override the default <lhs> and/or modes
  ---| [(modestr|modestr[]), lhs][]   # idem, but allows multiple, mode-specific <lhs>'s
  ---@type {[string]: KeymapEntry}
  keys = {
    show_control_flow = { "n", "<leader>k"},
    select_current_node = {
      {"n", "<A-k>"},
      {{ "x", "o" }, "i."}},
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

  -- ** Highlights **
  -- Each entry in this table defines the highlighting treeclimber applies to one of several regions
  -- relative to the current selection and its siblings/parent. To override the default, provide
  -- either a `vim.api.keyset.highlight` or a callback function that returns one. The callback will
  -- be invoked upon colorscheme load with an `HSLUVHighlights` object that may be used to "mix" new
  -- colors from the currently active normal and visual mode fg/bg colors.
  -- **Note:** The `vim.api.keyset.highlight` contains properties for more than just fg/bg colors:
  -- e.g., you could make the currently selected region bold and its siblings italic with the
  -- following override:
  --   ...
  --   TreeClimberHighlight = {bold = true},
  --   TreeClimberSibling = {italic = true)
  --   ...
  -- **Note:** You can also disable unwanted regions by setting the corresponding key(s) `false`.
  -- E.g., to disable all but the primary selection region (TreeClimberHighlight)...
  --   {
  --   TreeClimberSiblingBoundary = false, TreeClimberSibling = false,
  --   TreeClimberParent = false, TreeClimberParentStart = false
  --   }
  ---@alias HSLUVHighlights
  ---| {normal: HSLUVHighlight, visual: HSLUVHighlight}
  ---@alias HighlightCallback
  ---| fun(o: HSLUVHighlights) : vim.api.keyset.highlight
  ---@alias HighlightEntry
  ---| vim.api.keyset.highlight   # to be provided to `nvim_set_hl()`
  ---| HighlightCallback          # must return a `vim.api.keyset.highlight`
  ---| boolean                    # true for default highlighting, false to disable the group
  ---| nil                        # default highlighting
  ---@type {[string]: HighlightEntry}
  highlights = {
    TreeClimberHighlight = function(o) return { bg = o.visual.bg.hex } end,
    TreeClimberSiblingBoundary = function(o) return { bg = o.visual.bg.mix(o.normal.bg, 50).hex } end,
    TreeClimberSibling = function(o) return { bg = o.visual.bg.mix(o.normal.bg, 50).hex } end,
    TreeClimberParent = function(o) return { bg = o.visual.bg.mix(o.normal.bg, 50).hex } end,
    TreeClimberParentStart = function(o) return { bg = o.visual.bg.mix(o.normal.bg, 50).hex } end,
  },
  features = {
        -- TODO...
  },
}
```

---

Copyright Dylan Kendal 2022.
