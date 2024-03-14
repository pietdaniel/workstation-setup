vim.cmd [[packadd packer.nvim]]

require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'
  use 'preservim/nerdtree'
  use 'sainnhe/gruvbox-material'
  use { "ellisonleao/gruvbox.nvim" }
  use { 'junegunn/fzf.vim', requires = 'junegunn/fzf' }
  use "ntpeters/vim-better-whitespace"
end)

require("gruvbox").setup({
    palette_overrides = {
        bright_green = "#bdb951",
    }
})

vim.o.background = "dark"
vim.cmd("colorscheme gruvbox")

vim.api.nvim_set_keymap('n', '<Leader>w', ':StripWhitespace<CR>', {noremap = true, silent = true})
