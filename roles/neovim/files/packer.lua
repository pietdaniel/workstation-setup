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
    'nvim-telescope/telescope.nvim',
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

  -- use 'easymotion/vim-easymotion'
  use({
    "easymotion/vim-easymotion",
    config = function()
      -- Set leader as the EasyMotion prefix, old-school but it works
      vim.keymap.set({ "n", "x", "o" }, "<Leader>", "<Plug>(easymotion-prefix)", {
        remap = true,
        silent = true,
      })
    end,
  })

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

  use({
    "folke/trouble.nvim",
    cmd = { "Trouble" },
    requires = {
      'nvim-telescope/telescope.nvim',
    },
    config = function()
      require("trouble").setup({})
    end,
  })

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
      local vault_path = vim.fn.expand("~/Documents/Obsidian Vault")
      if vim.fn.isdirectory(vault_path) == 1 then
        require("obsidian").setup({
          workspaces = {
            {
              name = "main",
              path = vault_path,
            },
          },
          completion = {
            nvim_cmp = true,
            min_chars = 2,
          },
        })
      end
    end,
  })

  use { 'qvalentin/helm-ls.nvim', ft = 'helm' }
end)

