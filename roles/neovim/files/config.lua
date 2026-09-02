require("config.vim_pack")

vim.opt.smartindent = true
vim.opt.number = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.colorcolumn = "120"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.g.re = 1
vim.opt.lazyredraw = true
vim.opt.showbreak = "¬"
vim.opt.list = true
vim.opt.listchars = "tab:»\\ ,extends:›,precedes:‹,nbsp:·,trail:·"
vim.opt.foldenable = false
vim.opt.hlsearch = false
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.backspace = { "indent", "eol", "start" }
vim.opt.scrolloff = 2
vim.opt.laststatus = 2
vim.opt.showmode = false
vim.opt.hidden = true
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.cmdheight = 2
vim.opt.updatetime = 300
vim.opt.shortmess:append("c")

vim.keymap.set("n", ";", ":")
vim.keymap.set("n", "<C-e>", "<C-e>j")
vim.keymap.set("n", "<C-y>", "<C-y>k")
vim.keymap.set("x", "<leader>9", ":s/\\(.\\{80\\}.\\{-}\\s\\)/\\1\\r/g<CR>:StripWhitespace<CR>")
vim.keymap.set("n", "<leader>p", ":set invpaste<CR>")
vim.keymap.set("n", "<leader>z", ":%!jq '.'<CR>")
vim.keymap.set("x", "<leader>x", "+y")
vim.keymap.set("n", "<leader>x", ":set cursorline! cursorcolumn!<CR>")
vim.keymap.set("x", "//", "y/<C-R>\"<CR>")
vim.keymap.set({ "n", "v" }, "Q", "<Nop>")
vim.keymap.set("n", "<C-b>", ":cprevious<CR>")
vim.keymap.set("n", "<C-n>", ":cnext<CR>")
vim.keymap.set("n", "I", "yiw:Ack '<C-r>\"'<CR>")
vim.keymap.set("n", "<leader>]", ":lne<CR>")
vim.keymap.set("n", "<C-S-K>", ":let @r =strftime('- %c - ')<CR>:normal! \"rp<CR>a")
vim.keymap.set("i", "<C-S-K>", "<ESC>:let @r = strftime('- %c - ')<CR>:normal! \"rp<CR>a")

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.keymap.set("n", "<C-S-K>", ":let @r =strftime('# %c -')<CR>:normal! \"rP<CR>li<CR><CR><CR><CR><ESC>kki", { buffer = true })
    vim.keymap.set("i", "<C-S-K>", "<ESC>:let @r = strftime('# %c -')<CR>:normal! \"rP<CR>li<CR><CR><CR><CR><ESC>kki", { buffer = true })
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "[:;'\"`]*",
  callback = function()
    error("Forbidden file name: " .. vim.fn.expand("<afile>"))
  end,
})

vim.api.nvim_create_autocmd({ "BufReadPost", "FileReadPost", "BufNewFile" }, {
  pattern = "*",
  callback = function()
    vim.fn.system({ "tmux", "rename-window", vim.fn.expand("%") })
  end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.zsh-theme",
  callback = function()
    vim.bo.syntax = "zsh"
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "ruby", "sh", "bash", "zsh", "javascript", "text", "markdown", "yaml", "yml" },
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.smartindent = true
    vim.opt_local.autoindent = true
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function(event)
    vim.keymap.set("n", "<leader><leader>p", "koimport ipdb; ipdb.set_trace()<esc>", { buffer = event.buf })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "javascript", "typescript" },
  callback = function(event)
    vim.keymap.set("n", "<leader><leader>p", "kodebugger;<esc>", { buffer = event.buf })
  end,
})

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
local format_group = vim.api.nvim_create_augroup("FormatOnSave", { clear = true })

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    pattern = { "*.py" },
    desc = "Auto-format Python files after saving",
    callback = function()
        local fileName = vim.api.nvim_buf_get_name(0)
        vim.cmd(":silent !black --preview -q -l 120 " .. fileName)
        vim.cmd(":silent !isort --profile black --float-to-top -q " .. fileName)
    end,
    group = format_group,
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

vim.g.NERDTreeShowHidden = 1
vim.keymap.set("n", "<leader>n", ":NERDTreeToggle<CR>")
vim.g.delimitMate_expand_cr = 1

vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.b.delimitMate_nesting_quotes = { '"' }
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.b.delimitMate_nesting_quotes = { "`" }
  end,
})
