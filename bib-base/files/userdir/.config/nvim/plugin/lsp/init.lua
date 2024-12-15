-- settings
require('mason').setup({
  ui = {
    icons = {
      package_installed = "",
      package_pending = "",
      package_uninstalled = "",
    },
  }
})

require('mason-lspconfig').setup()

-- languages
require'lspconfig'.rust_analyzer.setup{}  -- rust
require'lspconfig'.taplo.setup{}          -- toml
require'lspconfig'.lua_ls.setup {         -- lua  
  settings = {
    Lua = {
      diagnostics = {
        globals = {'vim'}
      },
    },
  },
}
