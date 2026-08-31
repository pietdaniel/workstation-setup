if vim.fn.has("nvim-0.12") == 0 then
  error("vim.pack requires Neovim 0.12 or newer")
end

local gh = function(repo)
  return "https://github.com/" .. repo
end

vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(event)
    if event.data.spec.name ~= "markdown-preview.nvim" then
      return
    end

    if event.data.kind == "install" or event.data.kind == "update" then
      vim.system({ "npm", "install" }, {
        cwd = event.data.path .. "/app",
      }):wait()
    end
  end,
})

vim.g.mkdp_filetypes = { "markdown" }

vim.pack.add({
  gh("preservim/nerdtree"),
  gh("sainnhe/gruvbox-material"),
  gh("ellisonleao/gruvbox.nvim"),
  gh("junegunn/fzf"),
  gh("junegunn/fzf.vim"),
  gh("ntpeters/vim-better-whitespace"),
  gh("nvim-lua/plenary.nvim"),
  gh("nvim-telescope/telescope.nvim"),
  gh("tpope/vim-surround"),
  gh("tpope/vim-abolish"),
  gh("tpope/vim-fugitive"),
  gh("neovim/nvim-lspconfig"),
  gh("lukas-reineke/lsp-format.nvim"),
  gh("nvim-treesitter/nvim-treesitter"),
  gh("fatih/vim-go"),
  { src = gh("VonHeikemen/lsp-zero.nvim"), version = "v3.x" },
  gh("williamboman/mason.nvim"),
  gh("williamboman/mason-lspconfig.nvim"),
  gh("hrsh7th/nvim-cmp"),
  gh("hrsh7th/cmp-nvim-lsp"),
  gh("L3MON4D3/LuaSnip"),
  gh("easymotion/vim-easymotion"),
  gh("NoahTheDuke/vim-just"),
  gh("Raimondi/delimitMate"),
  gh("iamcco/markdown-preview.nvim"),
  gh("ngalaiko/tree-sitter-go-template"),
  gh("github/copilot.vim"),
  gh("folke/trouble.nvim"),
  gh("epwalsh/obsidian.nvim"),
  gh("qvalentin/helm-ls.nvim"),
  --- java block
  {
    src = gh("JavaHello/spring-boot.nvim"),
    version = "218c0c26c14d99feca778e4d13f5ec3e8b1b60f0",
  },
  gh("MunifTanjim/nui.nvim"),
  gh("mfussenegger/nvim-dap"),
  gh("nvim-java/nvim-java"),
  -- end java block
})

-- setup java
require("java").setup()

vim.lsp.config("jdtls", {
  settings = {
    java = {
      eclipse = {
        downloadSources = true,
      },
      maven = {
        downloadSources = true,
      },
    },
  },
})

vim.lsp.enable("jdtls")

-- no idea what this is
vim.keymap.set(
  { "n", "x", "o" },
  "<Leader>",
  "<Plug>(easymotion-prefix)",
  { remap = true, silent = true }
)

require("trouble").setup({})

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
