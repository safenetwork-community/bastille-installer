local options = {
  -- Klyr
  termguicolors = true,

  -- Tâbs
  tabstop = 2,
  shiftwidth = 2,
  softtabstop = 2,
  smarttab = true,
  expandtab = true,

  -- IU Goş
  number = true,
  numberwidth = 4,
  signcolumn = "yes",

  -- IU Drwa
  cursorline = true,
  wrap = false,
  autoindent = true,

  -- IU Bâ
  showmode = false,

  -- IU otr
  conceallevel = 0,
  scrolloff = 8,
  sidescrolloff = 8,

  -- Reşêrşe
  incsearch = true,
  hlsearch = false,
  ignorecase = true,
  smartcase = true,

  -- Otr
  mouse = 'a',
  clipboard = "unnamedplus",
  undofile = true,
  title = true
}

for k,v in pairs(options) do
  vim.opt[k] = v
end

-- Kopjy/Kôly/Kxpy
local highlight_yank = vim.api.nvim_create_augroup("highlight_yank", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
    pattern = "*",
    callback = function()
        vim.highlight.on_yank({ higroup = "IncSearch", timeout = 100 })
    end,
    group = highlight_yank,
})

-- Sudo vim
local command = vim.api.nvim_create_user_command

command('W','SudaWrite',{bang = true})
