local backends = require("aerial.backends")
local config = require("aerial.config")
local language_kind_map = require("aerial.backends.treesitter.language_kind_map")
local util = require("aerial.backends.util")
local M = {}

M.is_supported = function(bufnr)
  local ok, parsers = pcall(require, "nvim-treesitter.parsers")
  if not ok then
    return false
  end
  local lang = parsers.get_buf_lang(bufnr)
  if not parsers.has_parser(lang) then
    return false
  end
  local query = require("nvim-treesitter.query")
  return query.has_query_files(lang, "aerial")
end

M.fetch_symbols_sync = function(timeout)
  local extensions = require("aerial.backends.treesitter.extensions")
  local parsers = require("nvim-treesitter.parsers")
  local query = require("nvim-treesitter.query")
  local ts_utils = require("nvim-treesitter.ts_utils")
  local utils = require("nvim-treesitter.utils")
  local bufnr = 0
  local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
  local include_kind = config.get_filter_kind_map(filetype)
  local parser = parsers.get_parser(bufnr)
  local items = {}
  if not parser then
    backends.set_symbols(bufnr, items)
    return
  end
  local lang = parser:lang()
  local syntax_tree = parser:parse()[1]
  if not query.has_query_files(lang, "aerial") or not syntax_tree then
    backends.set_symbols(bufnr, items)
    return
  end
  -- This will track a loose hierarchy of recent node+items.
  -- It is used to determine node parents for the tree structure.
  local stack = {}
  local ext = extensions[lang]
  local kind_map = language_kind_map[lang]
  for match in query.iter_group_results(bufnr, "aerial", syntax_tree:root(), lang) do
    local name_node = (utils.get_at_path(match, "name") or {}).node
    local type_node = (utils.get_at_path(match, "type") or {}).node
    -- The location capture name is optional. We default to the
    -- location of the @type capture
    local loc_node = (utils.get_at_path(match, "location") or {}).node or type_node
    local parent_item, parent_node, level = ext.get_parent(stack, match, type_node)
    -- Sometimes our queries will match the same node twice.
    -- Detect that (type_node == parent_node), and skip dupes.
    if not type_node or type_node == parent_node then
      goto continue
    end
    local kind = kind_map[type_node:type()]
    if not kind then
      vim.api.nvim_err_writeln(
        string.format("Missing entry in aerial treesitter kind_map: %s", type_node:type())
      )
      break
    end
    if not include_kind[kind] then
      goto continue
    end
    local row, col = loc_node:start()
    local name
    if name_node then
      name = ts_utils.get_node_text(name_node, bufnr)[1] or "<parse error>"
    else
      name = "<Anonymous>"
    end
    local item = {
      kind = kind,
      name = name,
      level = level,
      parent = parent_item,
      lnum = row + 1,
      col = col,
    }
    ext.postprocess(item, match)
    if item.parent then
      if not item.parent.children then
        item.parent.children = {}
      end
      table.insert(item.parent.children, item)
    else
      table.insert(items, item)
    end
    table.insert(stack, { node = type_node, item = item })

    ::continue::
  end
  backends.set_symbols(bufnr, items)
end

M.fetch_symbols = M.fetch_symbols_sync

M.attach = function(bufnr)
  util.add_change_watcher(bufnr, "treesitter")
  M.fetch_symbols()
end

M.detach = function(bufnr)
  util.remove_change_watcher(bufnr, "treesitter")
end

return M
