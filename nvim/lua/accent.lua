local M = {}
local dir = vim.fn.expand("~/.cache")
local file = dir .. "/accent-palette.lua"

function M.set_header()
  local ok, p = pcall(dofile, file)
  local c = (ok and type(p) == "table" and p.accent) or "#b48cff"
  vim.api.nvim_set_hl(0, "AlphaHeader", { fg = c })
end

function M.apply()
  local ok, p = pcall(dofile, file)
  local opts = { flavour = "mocha", transparent_background = true }
  if ok and type(p) == "table" then
    opts.color_overrides = { mocha = {
      mauve = p.accent, lavender = p.accent_light, blue = p.accent,
      sapphire = p.accent_light, text = p.fg, subtext1 = p.fg,
      subtext0 = p.dim, overlay1 = p.dim, overlay0 = p.dim,
      surface2 = p.border, surface1 = p.surface_hi, surface0 = p.surface,
      base = p.bg, mantle = p.bg, crust = p.bg,
    } }
  end
  require("catppuccin").setup(opts)
  vim.cmd.colorscheme("catppuccin")
  M.set_header()
end

function M.watch()
  local w = vim.uv.new_fs_event()
  if not w then return end
  w:start(dir, {}, vim.schedule_wrap(function(_, name)
    if name == "accent-palette.lua" then M.apply() end
  end))
end

return M
