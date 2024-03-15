vim.cmd [[packadd packer.nvim]]

--- plugins
require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'
  use 'preservim/nerdtree'
  use 'sainnhe/gruvbox-material'
  use { "ellisonleao/gruvbox.nvim" }
  use { 'junegunn/fzf.vim', requires = 'junegunn/fzf' }
  use "ntpeters/vim-better-whitespace"
  use {
    'nvim-telescope/telescope.nvim', tag = '0.1.6',
    requires = { {'nvim-lua/plenary.nvim'} }
  }
  use 'tpope/vim-surround'
  use 'tpope/vim-abolish'
  use 'tpope/vim-fugitive'
  use {'neovim/nvim-lspconfig'}

  use {
    "nvim-treesitter/nvim-treesitter",
    run = ':TSUpdate'
  }

  use {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v3.x',
    requires = {
      --- Uncomment the two plugins below if you want to manage the language servers from neovim
      {'williamboman/mason.nvim'},
      {'williamboman/mason-lspconfig.nvim'},

      -- LSP Support
      {'neovim/nvim-lspconfig'},
      -- Autocompletion
      {'hrsh7th/nvim-cmp'},
      {'hrsh7th/cmp-nvim-lsp'},
      {'L3MON4D3/LuaSnip'},
    }
  }
end)

--- LSP Config
local lsp_zero = require('lsp-zero')

lsp_zero.on_attach(function(client, bufnr)
  -- see :help lsp-zero-keybindings
  -- to learn the available actions
  lsp_zero.default_keymaps({buffer = bufnr})
end)

-- to learn how to use mason.nvim with lsp-zero
-- read this: https://github.com/VonHeikemen/lsp-zero.nvim/blob/v3.x/doc/md/guide/integrate-with-mason-nvim.md
require('mason').setup({})
require('mason-lspconfig').setup({
  ensure_installed = {
    "pyright",
    "eslint",
    "tsserver",
    "rust_analyzer",
  },
  handlers = {
    lsp_zero.default_setup,
  },
})

--- gruvbox
require("gruvbox").setup({
  palette_overrides = {
    bright_green = "#bdb951",
  }
})
vim.o.background = "dark"
vim.cmd("colorscheme gruvbox")

--- whitespace
vim.api.nvim_set_keymap('n', '<Leader>w', ':StripWhitespace<CR>', {noremap = true, silent = true})

--- telescope configs
-- project search
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', function()
  builtin.grep_string({ search = vim.fn.input("Grep > ") });
end)
-- fuck arrow keys
local actions = require('telescope.actions')
require('telescope').setup{
  defaults = {
    mappings = {
      i = {
        ["<C-k>"] = actions.move_selection_previous,
        ["<C-j>"] = actions.move_selection_next,
      },
      n = {
        ["<C-k>"] = actions.move_selection_previous,
        ["<C-j>"] = actions.move_selection_next,
      },
    },
  },
}

--- treesitter
require'nvim-treesitter.configs'.setup {
  ensure_installed = {
    "c",
    "lua",
    "vim",
    "vimdoc",
    "query",
    "javascript",
    "python",
    "go",
    "c_sharp",
  },
  sync_install = false,
  auto_install = true,
  ignore_install = { "javascript" },
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
}

--- project search
vim.cmd [[
command! -nargs=+ Ack lua require('telescope.builtin').grep_string({ search = vim.fn.escape(<q-args>, '\\') })
]]
vim.cmd [[cnoreabbrev ag Ack]]
vim.cmd [[cnoreabbrev Ag Ack]]

--- search word
function _G.search_word()
  local search_term = vim.fn.expand("<cword>")
  if search_term and search_term ~= "" then
    require('telescope.builtin').grep_string({ search = search_term })
  end
end

function _G.search_selection()
  local original_regtype = vim.fn.getregtype('"')
  vim.cmd('noau normal! gvy')
  local search_term = vim.fn.getreg('"')
  vim.fn.setreg('"', search_term, original_regtype)
  if search_term and search_term ~= "" then
    require('telescope.builtin').grep_string({ search = search_term })
  end
  vim.defer_fn(function()
    vim.cmd('stopinsert')
  end, 10)
end

vim.api.nvim_set_keymap('n', 'I', ':lua _G.search_word()<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('v', 'I', ':<C-u>lua _G.search_selection()<CR>', {noremap = true, silent = true})
