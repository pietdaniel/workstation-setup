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

  -- implement trouble
  --[[
  use {
    "folke/trouble.nvim",
    config = function()
      require("trouble").setup {
        icons = false, -- use devicons for filenames
        position = "bottom", -- position of the list can be: bottom, top, left, right
        height = 10, -- height of the trouble list when position is top or bottom
        mode = "quickfix", -- default mode
        fold_open = "", -- icon used for open folds
        fold_closed = "", -- icon used for closed folds
        group = true, -- group results by file
        padding = true, -- add an extra new line on top of the list
        action_keys = { -- key mappings for actions in the trouble list
          close = "q", -- close the list
          cancel = "<esc>", -- cancel the preview and get back to your last window / buffer / cursor
          refresh = "r", -- manually refresh
          jump = {"<cr>", "<tab>"}, -- jump to the diagnostic or open / close folds
          open_split = { "<c-x>" }, -- open buffer in new split
          open_vsplit = { "<c-v>" }, -- open buffer in new vsplit
          open_tab = { "<c-t>" }, -- open buffer in new tab
          jump_close = {"o"}, -- jump to the diagnostic and close the list
          toggle_mode = "m", -- toggle between "workspace" and "document" diagnostics mode
          toggle_preview = "P", -- toggle auto_preview
          hover = "K", -- opens a small popup with the full multiline message
          preview = "p", -- preview the diagnostic location
          close_folds = {"zM", "zm"}, -- close all folds
          open_folds = {"zR", "zr"}, -- open all folds
          toggle_fold = {"zA", "za"}, -- toggle fold of current file
          previous = "k", -- preview item
          next = "j" -- next item
        },
        indent_lines = true, -- add an indent guide below the fold icons
        auto_open = false, -- automatically open the list when you have diagnostics
        auto_close = false, -- automatically close the list when you have no diagnostics
        auto_preview = true, -- automatically preview the location of the diagnostic. <esc> to close preview and go back to last window
        auto_fold = false, -- automatically fold a file trouble list at creation
        auto_jump = {"lsp_definitions"}, -- for the given modes, automatically jump if there is only a single result
        signs = {
          -- icons / text used for a diagnostic
          error = "",
          warning = "",
          hint = "",
          information = "",
          other = "﫠"
        },
        use_diagnostic_signs = false -- enabling this will use the signs defined in your lsp client
      }
    end
  }
  --]]

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
-- not sure why it whines about this but it does.
-- vim.cmd([[
--  autocmd FileType markdown setlocal conceallevel=1
-- ]])

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

vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = { "*.js", "*.jsx", "*.ts", "*.tsx" },
    desc = "Auto-format JavaScript and TypeScript files with LSP before saving",
    callback = function()
        vim.lsp.buf.format()
    end,
})

vim.api.nvim_set_keymap('n', '<leader>=', '<cmd>lua vim.lsp.buf.format()<CR>', { noremap = true, silent = true })

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
--- go to function definition with leader f
vim.api.nvim_set_keymap('n', '<leader>f', ':lua require("telescope.builtin").lsp_document_symbols()<CR>zz', { noremap = true, silent = true })

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


--- Project Search
function ProjectSearch(search_pattern)
  local case_flag = "-i" -- Default to case-insensitive
  local pattern = search_pattern

  -- Check for quoted pattern (case-sensitive)
  local first_char = pattern:sub(1,1)
  local last_char = pattern:sub(-1)
  if (first_char == '"' and last_char == '"') or (first_char == "'" and last_char == "'") then
    case_flag = "" -- Case-sensitive
    pattern = pattern:sub(2, -2) -- Strip quotes
  end

  -- Escape special characters
  pattern = vim.fn.shellescape(pattern)

  -- Exclude node_modules and dist directories
  local exclude_args = "--glob='!node_modules/**' --glob='!dist/**'"

  -- Construct and run the ripgrep command
  local command = string.format(":silent! grep! %s --vimgrep --no-heading %s %s .", case_flag, exclude_args, pattern)
  vim.api.nvim_command(command)
  vim.api.nvim_command("copen")
end

vim.cmd([[
  command! -nargs=* Ack lua _G.ProjectSearch(<q-args>)
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
