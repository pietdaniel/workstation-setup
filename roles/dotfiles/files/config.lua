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

  use "lukas-reineke/lsp-format.nvim"

  use {
    "nvim-treesitter/nvim-treesitter",
    run = ':TSUpdate'
  }

  use {
    'fatih/vim-go',
    run = ':GoUpdateBinaries'
  }

  use {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v3.x',
    requires = {
      {'williamboman/mason.nvim'},
      {'williamboman/mason-lspconfig.nvim'},
      {'neovim/nvim-lspconfig'},
      {'hrsh7th/nvim-cmp'},
      {'hrsh7th/cmp-nvim-lsp'},
      {'L3MON4D3/LuaSnip'},
    }
  }

  use 'easymotion/vim-easymotion'
  use 'NoahTheDuke/vim-just'
  use 'Raimondi/delimitMate'
  use({
    "iamcco/markdown-preview.nvim",
    run = "cd app && npm install",
    setup = function() vim.g.mkdp_filetypes = { "markdown" } end,
    ft = { "markdown" },
  })
  use 'ngalaiko/tree-sitter-go-template'
  use 'github/copilot.vim'


  --- https://github.com/epwalsh/obsidian.nvim?tab=readme-ov-file#setup
  use({
    "epwalsh/obsidian.nvim",
    tag = "*",
    requires = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
      "nvim-treesitter/nvim-treesitter",
      'hrsh7th/nvim-cmp',
    },
    config = function()
      require("obsidian").setup({
        workspaces = {
          {
            name = "main",
            path = "~/Documents/Obsidian Vault",
          },
        },
        -- Optional, completion of wiki links, local markdown links, and tags using nvim-cmp.
        completion = {
          -- Set to false to disable completion.
          nvim_cmp = true,
          -- Trigger completion at 2 chars.
          min_chars = 2,
        },
      })
    end,
  })
end)

--- Obsidian Config
vim.api.nvim_set_keymap('n', '<Leader>on', ':ObsidianDailies<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>os', ':ObsidianSearch<CR>', { noremap = true, silent = true })
-- not sure why it whines about this but it do
vim.cmd([[
  autocmd FileType markdown setlocal conceallevel=1
]])

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
  },
  handlers = {
    lsp_zero.default_setup,
  },
})

--- LSP Format
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    pattern = { "*.py" },
    desc = "Auto-format Python files after saving",
    callback = function()
        local fileName = vim.api.nvim_buf_get_name(0)
        vim.cmd(":silent !black --preview -q -l 120 " .. fileName)
        vim.cmd(":silent !isort --profile black --float-to-top -q " .. fileName)
    end,
    group = autocmd_group,
})

--- Treesitter
local parser_config = require'nvim-treesitter.parsers'.get_parser_configs()
parser_config.gotmpl = {
  install_info = {
    url = "https://github.com/ngalaiko/tree-sitter-go-template",
    files = {"src/parser.c"}
  },
  filetype = "gotmpl",
  used_by = {"gohtmltmpl", "gotexttmpl", "gotmpl", "yaml"}
}

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
-- find files
vim.api.nvim_set_keymap('n', '<Leader>fh', ':lua require"telescope.builtin".find_files({ hidden = true })<CR>', {noremap = true, silent = true})
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
function ProjectSearch(search_pattern)
  local command = string.format(":silent! grep -iR '%s' .", vim.fn.escape(search_pattern, "'\\"))
  vim.api.nvim_command(command)
  vim.api.nvim_command("copen")
end

vim.cmd([[
command! -nargs=* Ack lua _G.ProjectSearch(<f-args>)
]])

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

--- MarkdownPreview
vim.g.mkdp_theme = 'light'
