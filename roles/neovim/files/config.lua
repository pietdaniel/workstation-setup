require("config.vim_pack")

--- Obsidian Config
vim.api.nvim_set_keymap('n', '<Leader>on', ':ObsidianDailies<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>os', ':ObsidianSearch<CR>', { noremap = true, silent = true })
-- not sure why it whines about this but it does.
-- vim.cmd([[
--  autocmd FileType markdown setlocal conceallevel=1
-- ]])

local lsp_zero = require("lsp-zero")
local lspconfig = require("lspconfig")
local util = require("lspconfig.util")

lsp_zero.on_attach(function(client, bufnr)
  lsp_zero.default_keymaps({ buffer = bufnr })
end)

lsp_zero.extend_lspconfig()

require("mason").setup({})

require("mason-lspconfig").setup({
  ensure_installed = {
    "ty",
    "eslint",
    "ts_ls",
    "lua_ls",
    "gopls",
  },
  handlers = {
    lsp_zero.default_setup,
  },
})

vim.lsp.config('ty', {
  root_dir = vim.fs.root(0, {
    "pyproject.toml",
    "uv.lock",
    ".git",
  }),

  settings = {
    ty = {
      -- ty language server settings go here
    }
  }
})

-- Required: Enable the language server
vim.lsp.enable('ty')

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
-- Register go-template filetypes with the gotmpl parser
-- (parser is provided by the ngalaiko/tree-sitter-go-template plugin)
vim.filetype.add({
  extension = {
    gotmpl = "gotmpl",
  },
})
-- using helm-ls instead of this (TSInstall)
-- vim.treesitter.language.register("gotmpl", { "gohtmltmpl", "gotexttmpl", "gotmpl", "helm" })

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

-- === Telescope Configs ===
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<C-f>', function()
  builtin.find_files({
    hidden = true,
    file_ignore_patterns = { "^%.git/" },
  })
end, { noremap = true, silent = true })
vim.keymap.set('n', '<C-g>', builtin.live_grep, { noremap = true, silent = true })
vim.keymap.set('n', '<S-t>', builtin.buffers, { noremap = true, silent = true })
-- vim.keymap.set('n', '<leader>fh', builtin.help_tags, { noremap = true, silent = true })

-- find files
vim.api.nvim_set_keymap(
  'n', '<Leader>fh', ':lua require"telescope.builtin".find_files({ hidden = true })<CR>',
  {noremap = true, silent = true}
)

-- project search
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', function()
  builtin.grep_string({ search = vim.fn.input("Grep > ") });
end)

vim.keymap.set("n", "<C-l>", function()
  require("telescope.builtin").diagnostics({
    bufnr = 0, -- current buffer; remove for workspace
  })
end, { noremap = true, silent = true })

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
vim.api.nvim_set_keymap(
  'n', '<leader>f', ':lua require("telescope.builtin").lsp_document_symbols()<CR>zz',
  { noremap = true, silent = true }
)

--- treesitter
-- Support both old (master) and new (main) nvim-treesitter branches
local ts_ok, ts_configs = pcall(require, 'nvim-treesitter.configs')
if ts_ok then
  -- Old API (master branch)
  ts_configs.setup {
    ensure_installed = {
      "c", "lua", "vim", "vimdoc", "query",
      "javascript", "python", "go", "c_sharp",
    },
    sync_install = false,
    auto_install = true,
    ignore_install = { "javascript" },
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },
  }
else
  -- New API (main branch) - highlight is built into Neovim
  vim.treesitter.start = vim.treesitter.start or function() end
  require('nvim-treesitter').setup {}
  -- Install parsers if missing
  local parsers = { "c", "lua", "vim", "vimdoc", "query", "javascript", "python", "go", "c_sharp" }
  local installed = require('nvim-treesitter').get_installed()
  local installed_set = {}
  for _, p in ipairs(installed) do installed_set[p] = true end
  local to_install = {}
  for _, p in ipairs(parsers) do
    if not installed_set[p] then table.insert(to_install, p) end
  end
  if #to_install > 0 then
    require('nvim-treesitter').install(to_install)
  end
  -- Enable treesitter highlighting for all buffers
  vim.api.nvim_create_autocmd("FileType", {
    callback = function()
      pcall(vim.treesitter.start)
    end,
  })
end


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

  -- Exclude node_modules, git, and dist directories
  local exclude_args = "--glob='!node_modules/**' --glob='!dist/**' --glob='!.git/**'"

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

-- Trouble config -- idk, do I care about these?
vim.keymap.set("n", "<leader>xx", function()
  vim.cmd("Trouble diagnostics toggle")
end, { silent = true, noremap = true, desc = "Diagnostics (Trouble)" })

vim.keymap.set("n", "<leader>xX", function()
  vim.cmd("Trouble diagnostics toggle filter.buf=0")
end, { silent = true, noremap = true, desc = "Buffer Diagnostics (Trouble)" })

vim.keymap.set("n", "<leader>cl", function()
  vim.cmd("Trouble lsp toggle focus=false win.position=right")
end, { silent = true, noremap = true, desc = "LSP (Trouble)" })

vim.keymap.set("n", "<leader>xL", function()
  vim.cmd("Trouble loclist toggle")
end, { silent = true, noremap = true, desc = "Location List (Trouble)" })

vim.keymap.set("n", "<leader>xQ", function()
  vim.cmd("Trouble qflist toggle")
end, { silent = true, noremap = true, desc = "Quickfix List (Trouble)" })

-- configure helm
vim.lsp.config('helm_ls', {
  cmd = { 'helm_ls', 'serve' },
  filetypes = { 'helm' },
  root_markers = { 'Chart.yaml' },
  settings = {
    ['helm-ls'] = {
      yamlls = {
        path = 'yaml-language-server',
      },
    },
  },
})
vim.lsp.enable('helm_ls')
