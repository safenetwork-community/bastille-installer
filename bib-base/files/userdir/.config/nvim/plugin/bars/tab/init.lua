local bufferline = require "bufferline"
local icons = require "shared.icons"

local function diagnostics_indicator(_, _, diagnostics, _)
  local result = {}
  local symbols = {
    error = icons.diagnostics.Error,
    warning = icons.diagnostics.Warning,
    info = icons.diagnostics.Information,
  }
  for name, count in pairs(diagnostics) do
    if symbols[name] and count > 0 then
      table.insert(result, symbols[name] .. " " .. count)
    end
  end
  result = table.concat(result, " ")
  return #result > 0 and result or ""
end

local config = {
  options = {
    buffer_close_icon = icons.ui.Close,
    close_icon = icons.ui.BoldClose,
    color_icons = true,
    diagnostics = "nvim_lsp",
    diagnostics_indicator = diagnostics_indicator,
    diagnostics_update_in_insert = false,
    indicator = {
      icon = icons.ui.BoldLineLeft,
      style = "icon",
    },
    left_trunc_marker = icons.ui.ArrowCircleLeft,
    modified_icon = icons.ui.Circle,
    right_trunc_marker = icons.ui.ArrowCircleRight,
    style_preset = bufferline.style_preset.minimal,
  }
}

-- Bars
require('bufferline').setup(config)
