-- Run with -u NONE so editor startup does not launch competing installers.
local function install()
  vim.g.workstation_bootstrap = true
  require("config.vim_pack")
  local tools = require("config.tools")
  local timeout = 20 * 60 * 1000

  -- Run on reruns too, so an interrupted npm install can recover.
  local preview = vim.pack.get({ "markdown-preview.nvim" })[1]
  print("Installing Markdown preview dependencies...")
  local result = vim.system({ "npm", "install" }, {
    cwd = preview.path .. "/app",
    text = true,
  }):wait(timeout)
  assert(result.code == 0, "Markdown preview installation failed: " .. (result.stderr or ""))

  require("mason").setup({})
  local registry = require("mason-registry")
  local refreshed, refresh_error
  registry.refresh(function(success, err)
    refreshed, refresh_error = success, err
  end)
  assert(vim.wait(timeout, function() return refreshed ~= nil end, 100), "Mason registry refresh timed out")
  assert(refreshed, "Mason registry refresh failed: " .. vim.inspect(refresh_error))

  local mappings = require("mason-lspconfig").get_mappings().lspconfig_to_package
  for _, server in ipairs(tools.servers) do
    local name = assert(mappings[server], "No Mason package for " .. server)
    local package = registry.get_package(name)
    if not package:is_installed() then
      print("Installing " .. name .. "...")
      local finished, install_error
      package:install({}, function(success, err)
        finished, install_error = success, err
      end)
      assert(vim.wait(timeout, function() return finished ~= nil end, 100), name .. " installation timed out")
      assert(finished, name .. " installation failed: " .. vim.inspect(install_error))
    end
  end

  print("Installing Treesitter parsers...")
  local treesitter = require("nvim-treesitter")
  local legacy, configs = pcall(require, "nvim-treesitter.configs")
  if legacy then
    configs.setup({ ensure_installed = {}, auto_install = false })
    require("nvim-treesitter.install").commands.TSInstallSync.run(tools.parsers)
  else
    treesitter.setup({})
    assert(treesitter.install(tools.parsers):wait(timeout), "Treesitter installation failed")
  end
  for _, parser in ipairs(tools.parsers) do
    assert(vim.treesitter.language.add(parser), "Treesitter parser missing: " .. parser)
  end
  print("Neovim plugins and tools are ready.")
end

local ok, err = xpcall(install, debug.traceback)
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd("cquit 1")
end
vim.cmd("qa!")
