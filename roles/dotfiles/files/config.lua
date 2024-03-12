vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'
  use 'preservim/nerdtree'
  use "morhetz/gruvbox"
  use { 'junegunn/fzf.vim', requires = 'junegunn/fzf' }
end)
