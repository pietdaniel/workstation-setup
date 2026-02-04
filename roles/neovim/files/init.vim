" == SETTINGS ==
set nocompatible
set smartindent
set number
set tabstop=2
set shiftwidth=2
set expandtab
set colorcolumn=120
" smart case search
set ignorecase
set smartcase
let re=1
set ttyfast
set lazyredraw
set showbreak=¬\
set list!
set listchars=tab:»\ ,extends:›,precedes:‹,nbsp:·,trail:·
set nofoldenable
" no higlight search
set nohlsearch
syntax enable
" Relative numbering
set relativenumber
let mapleader = "\<Space>"
set mouse=a
nmap ; :
set backspace=2
" distance from cursor
set scrolloff=2
" keep status line on
set laststatus=2
" hide vim insert
set noshowmode
" if hidden is not set, TextEdit might fail.
set hidden
" Some servers have issues with backup files, see #649
set nobackup
set nowritebackup
" Better display for messages
set cmdheight=2
" You will have bad experience for diagnostic messages when it's default 4000.
set updatetime=300
" don't give |ins-completion-menu| messages.
set shortmess+=c

" == CUSTOM COMMANDS ==

" Move cursor while scrolling
nmap <C-e> <C-e>j
nmap <C-y> <C-y>k

" turn text into 80 line length
vmap <leader>9 :s/\(.\{80\}.\{-}\s\)/\1\r/g<cr>:StripWhitespace<cr>

" toggle paste in cmd only
nnoremap <Leader>p :set invpaste<CR>

" fast json format
nnoremap <Leader>z :%!jq '.'<CR>

" Copy all to clipboard
vnoremap  <leader>x  "+y

" vim crosshairs
" hi CursorLine   cterm=NONE ctermbg=235
" hi CursorColumn cterm=NONE ctermbg=235
nnoremap <Leader>x :set cursorline! cursorcolumn!<CR>

" find via // over visual selection
vnoremap // y/<C-R>"<CR>"

" Disable vim ex mode
map Q <Nop>

" make W w
command W w

" next/prev quicklist item
nmap <c-b> :cprevious<CR>
nmap <c-n> :cnext<CR>

" Auto search on shift-i
map I yiw:Ack '<C-r>"'<cr>

" go to next error
nnoremap <Leader>] :lne<CR>

" insert timestamp
nnoremap <C-S-K> :let @r =strftime('- %c - ')<CR>:normal! "rp<CR>a
inoremap <C-S-K> <ESC>:let @r = strftime('- %c - ')<CR>:normal! "rp<CR>a
autocmd FileType markdown nnoremap <C-S-K> :let @r =strftime('# %c -')<CR>:normal! "rP<CR>li<CR><CR><CR><CR><ESC>kki
autocmd FileType markdown inoremap <C-S-K> <ESC>:let @r = strftime('# %c -')<CR>:normal! "rP<CR>li<CR><CR><CR><CR><ESC>kki

" == AUTOCMD ==

" dont save these things as files
autocmd BufWritePre [:;'"`]* throw 'Forbidden file name: ' . expand('<afile>')

" Rename for tmux
autocmd BufReadPost,FileReadPost,BufNewFile * call system("tmux rename-window " . expand("%"))

" ZSH theme files are zsh
autocmd Bufread,BufNewFile *.zsh-theme set syntax=zsh

" 2 shiftwidth for languages
au FileType ruby setl sw=2 et tabstop=2 sts=2 smartindent ai
au FileType sh setl sw=2 et tabstop=2 sts=2 smartindent ai
au FileType bash setl sw=2 et tabstop=2 sts=2 smartindent ai
au FileType zsh setl sw=2 et tabstop=2 sts=2 smartindent ai
au FileType javascript setl sw=2 et tabstop=2 sts=2 smartindent ai
au FileType text setl sw=2 et tabstop=2 sts=2
au FileType markdown setl sw=2 et tabstop=2 sts=2
au FileType yaml setl sw=2 et tabstop=2 sts=2 smartindent ai
au FileType yml setl sw=2 et tabstop=2 sts=2 smartindent ai

" == PLUGIN config ==

" nerdtree
map <Leader>n :NERDTreeToggle<CR>

" LUA
lua require('config')

" NERDTree
let NERDTreeShowHidden=1

" Easymotion
" map <Leader> <Plug>(easymotion-prefix)

" delimitMate
let delimitMate_expand_cr=1
autocmd FileType python let b:delimitMate_nesting_quotes = ['"']
autocmd FileType markdown let b:delimitMate_nesting_quotes = ['`']

" Use gotmpl tresitter on handlebar files
autocmd BufNewFile,BufRead *.yml,*.yaml if (search('{{.\+}}', 'nw') && (expand('%:p') =~ 'kube')) | setlocal filetype=gotmpl | endif
autocmd BufNewFile,BufRead *.yml,*.yaml if (search('{{.\+}}', 'nw') && (expand('%:p') =~ 'helm')) | setlocal filetype=helm | endif

" Define a function that updates the mapping
function! SetDebugMapping()
    if &filetype == 'python'
        nnoremap <Leader><Leader>p koimport ipdb; ipdb.set_trace()<esc>
    elseif &filetype == 'javascript'
        nnoremap <Leader><Leader>p kodebugger;<esc>
    elseif &filetype == 'typescript'
        nnoremap <Leader><Leader>p kodebugger;<esc>
    endif
endfunction

" Call the function whenever a buffer is entered
autocmd BufEnter * call SetDebugMapping()
