-- ## Usage
--
-- Just specify "aerial" component in one of your lualine sections.
-- For example:
--
--   require("lualine").setup({
--     sections = {
--       lualine_x = { "aerial" },
--     },
--   })
--
-- ## Options
--
-- *sep* (default: " ⟩ ")
--   The separator to be used to separate symbols in status line.
--
-- *depth* (default: nil)
--   The number of symbols to render top-down. In order to render only 'N' last
--   symbols, negative numbers may be supplied. For instance, 'depth = -1' can
--   be used in order to render only current symbol.
--
-- *dense* (default: false)
--   When 'dense' mode is on, icons are not rendered near their symbols. Only
--   a single icon that represents the kind of current symbol is rendered at
--   the beginning of status line.
--
-- *dense_sep* (default: ".")
--   The separator to be used to separate symbols in dense mode. Normally does
--   not contain spaces to increase density.
--
-- *colored* (default: true)
--   Color the symbol icons.
--
-- ## Examples
--
-- { "aerial" }
-- ﴯ MyClassName ⟩  my_method_name
--
-- { "aerial", dense = true }
--  MyClassName.my_method_name
--
-- { "aerial", depth = -1 }
--  my_method_name

local M = require("lualine.component"):extend()
local aerial = require("aerial")

local default_options = {
  sep = " ⟩ ",
  depth = nil,
  dense = false,
  dense_sep = ".",
  exact = true,
}

local function color_icon(symbol_kind, icon, colored)
  if colored then
    return string.format("%%#%s#%s%%##", "Aerial" .. symbol_kind .. "Icon", icon.." ")
  else
    return icon
  end
end

local function color(symbol_kind, text, colored)
  if colored then
    return string.format("%%#%s#%s", "Aerial" .. symbol_kind, text )
  else
    return text
  end
end

local function format_status(symbols, depth, separator, icons_enabled, colored)
  local parts = {}
  depth = depth or #symbols

  if depth > 0 then
    symbols = { unpack(symbols, 1, depth) }
  else
    symbols = { unpack(symbols, #symbols + 1 + depth) }
  end

  for _, symbol in ipairs(symbols) do
    if icons_enabled then
      local icon = color_icon(symbol.kind, symbol.icon, colored)
      local name = color(symbol.kind, symbol.name, colored)
      table.insert(parts, string.format("%s%s", icon, name))
    else
      local name = color(symbol.kind, symbol.name, colored)
      table.insert(parts, name)
    end
  end
  return table.concat(parts, separator)
end

function M:init(options)
  M.super.init(self, options)

  self.options = vim.tbl_deep_extend("keep", self.options or {}, default_options)
  if self.options.colored == nil then
    self.options.colored = true
  end
  self.get_status = self.get_status_normal

  if self.options.dense then
    self.get_status = self.get_status_dense
  end
end

function M:update_status()
  return self:get_status()
end

function M:get_status_normal()
  local symbols = aerial.get_location(self.options.exact)
  local status = format_status(
    symbols,
    self.options.depth,
    self.options.sep,
    self.options.icons_enabled,
    self.options.colored
  )
  return status
end

function M:get_status_dense()
  local symbols = aerial.get_location(self.options.exact)
  local status = format_status(
    symbols,
    self.options.depth,
    self.options.dense_sep,
    -- In dense mode icons aren't rendered togeter with symbols. A single icon
    -- at the beginning of status line is rendered instead. See below.
    false
  )

  if self.options.icons_enabled and not vim.tbl_isempty(symbols) then
    local symbol = symbols[#symbols]
    local icon = color_icon(symbol.kind, symbol.icon, self.options.colored)
    status = string.format("%s %s", icon, status)
  end
  return status
end

return M
