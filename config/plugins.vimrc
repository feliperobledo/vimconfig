call plug#begin('~/.config/nvim/plugged')

"Plug 'carlitux/deoplete-ternjs', { 'do': 'npm install -g tern' }
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
" Initialize plugin system

Plug 'zchee/deoplete-clang'
Plug 'zchee/deoplete-jedi'

" Plugin to surround word under cursor with whatever
Plug 'tpope/vim-surround'

" Working with APEX. Syntax highlighting
Plug 'ejholmes/vim-forcedotcom'

" Work with Git on Vim
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'

" Goto package for python
Plug 'davidhalter/jedi-vim'

" Add color to every indentation level
Plug 'nathanaelkane/vim-indent-guides'

" Fuzzy file search
" requires: brew install ripgrep the_silver_searcher
Plug 'cloudhead/neovim-fuzzy'

" Jenkins filesyntax
Plug 'martinda/Jenkinsfile-vim-syntax'

" Enable silver searcher in editor
Plug 'Numkil/ag.nvim'

" Typescript extension
Plug 'leafgarland/typescript-vim'
Plug 'peitalin/vim-jsx-typescript'
" This is promising but broken
" Plug 'mhartington/nvim-typescript', {'do': './install.sh' }

" Html and CSS autocompletion
Plug 'mattn/emmet-vim'

" Better interface to make sessions. Works well with tmux-resurrect
Plug 'tpope/vim-obsession'

" Ruby plugins
Plug 'vim-ruby/vim-ruby'

call plug#end()

" Enable deoplete
let g:deoplete#enable_at_startup = 1
let g:deoplete#auto_complete_start_length = 1

" =========================================================
"       deoplete-jedi
" =========================================================

let g:deoplete#sources#jedi#server_timeout = 10
let g:deoplete#sources#jedi#statement_length = 50
let g:deoplete#sources#jedi#enable_cache = 1
let g:deoplete#sources#jedi#show_docstring = 0
" Use the following only if the VIRTUAL_ENV environment variable will not be set. Better to set it in on a per session basis.
" let g:deoplete#sources#jedi#python_path - ''

let g:deoplete#sources#jedi#debug_server = 0
let g:deoplete#sources#jedi#extra_path = []

" =========================================================
"       deoplete-clang
" =========================================================
let g:deoplete#sources#clang#libclang_path = '/usr/local/Cellar/llvm/5.0.0/lib/libclang.dylib'
let g:deoplete#sources#clang#clang_header = '/usr/local/Cellar/llvm/5.0.0/include/clang'
let g:deoplete#sources#clang#std#cpp = 'c++11'
let g:deoplete#sources#clang#sort_algo = 'priority'

" =========================================================
"       ternjs
" =========================================================

" Set bin if you have many instalations
let g:deoplete#sources#ternjs#tern_bin = '/usr/local/bin/tern'
let g:deoplete#sources#ternjs#timeout = 1

" Whether to include the types of the completions in the result data. Default: 0
let g:deoplete#sources#ternjs#types = 1

" Whether to include the distance (in scopes for variables, in prototypes for 
" properties) between the completions and the origin position in the result 
" data. Default: 0
let g:deoplete#sources#ternjs#depths = 1

" Whether to include documentation strings (if found) in the result data.
" Default: 0
let g:deoplete#sources#ternjs#docs = 1

" When on, only completions that match the current word at the given point will
" be returned. Turn this off to get all results, so that you can filter on the 
" client side. Default: 1
let g:deoplete#sources#ternjs#filter = 0

" Whether to use a case-insensitive compare between the current word and 
" potential completions. Default 0
let g:deoplete#sources#ternjs#case_insensitive = 1

" Determines whether the result set will be sorted. Default: 1
let g:deoplete#sources#ternjs#sort = 0

" If completions should be returned when inside a literal. Default: 1
let g:deoplete#sources#ternjs#in_literal = 0

"Add extra filetypes
let g:deoplete#sources#ternjs#filetypes = [
                \ 'jsx',
                \ 'javascript.jsx',
                \ 'vue',
                \ '...'
                \ ]

" Use tern_for_vim.
let g:tern#command = ["tern"]
let g:tern#arguments = ["--persistent"]

" =========================================================
"       vim-indent-guidelines
" =========================================================
let g:indent_guides_enable_on_vim_startup = 0
let g:indent_guides_auto_colors = 0
let g:indent_guides_start_level = 2
let g:indent_guides_guide_size = 1
let g:indext_guides_color_change_percent = 1
autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  ctermbg=22
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven ctermbg=136
