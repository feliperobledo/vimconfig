call plug#begin('~/.config/nvim/plugged')


" =================================================================================
"                         Autocompletetion engine
" =================================================================================
" Plug 'carlitux/deoplete-ternjs', { 'do': 'npm install -g tern' }
" Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }

" Initialize plugin system
" Plug 'zchee/deoplete-clang'
" Plug 'zchee/deoplete-jedi'
"
"" Use release branch
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Omnisharp (c#) completion
Plug 'OmniSharp/omnisharp-vim'

" =================================================================================
"                         Working with git
" =================================================================================
" Work with Git on Vim
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'

" =================================================================================
"                         Editor Actions
" =================================================================================
"
" Mimic Control+Shift Find of a reference across a project, and edit all references in place
Plug 'dyng/ctrlsf.vim'

" Plugin to surround word under cursor with whatever
Plug 'tpope/vim-surround'

" Fuzzy file search
" requires: brew install ripgrep the_silver_searcher
Plug 'cloudhead/neovim-fuzzy'

" Search for string in project
Plug 'wsdjeg/FlyGrep.vim'

" Enable silver searcher in editor
Plug 'Numkil/ag.nvim'


" Add color to every indentation level
Plug 'nathanaelkane/vim-indent-guides'


" Better interface to make sessions. Works well with tmux-resurrect
Plug 'tpope/vim-obsession'

" Ruby plugins
Plug 'vim-ruby/vim-ruby'

" Plugin to add editing features when working with cucumber files
Plug 'tpope/vim-cucumber'

" =================================================================================
"                         File syntax
" =================================================================================

" Typescript extension
Plug 'HerringtonDarkholme/yats.vim'

" Jenkins filesyntax
Plug 'martinda/Jenkinsfile-vim-syntax'

" Add color and syntax highlighting for Godot's Gscript
Plug 'calviken/vim-gdscript3'

" C++11/14/17 extra syntax highlighting
Plug 'octol/vim-cpp-enhanced-highlight'

" =================================================================================
"                        Themes
" =================================================================================

Plug 'drewtempelmeyer/palenight.vim'

call plug#end()

" Enable deoplete
let g:deoplete#enable_at_startup = 1
let g:deoplete#auto_complete_start_length = 1

" =========================================================
"       vim-cpp-enhanced-highlight
" =========================================================
let g:cpp_class_scope_highlight = 1
let g:cpp_member_variable_highlight = 1
let g:cpp_class_decl_highlight = 1
let g:cpp_experimental_simple_template_highlight = 1 "works in most cases, but can be a little slow on large files
" let g:cpp_experimental_template_highlight = 1 "is a faster implementation but has some corner cases where it doesn't work
let g:cpp_concepts_highlight = 1
" let c_no_curly_error=1 " vim tends to flag braces as error. This disables that.

" =========================================================
"       syntastic
" =========================================================
let g:syntastic_python_flake8_args='--ignore=E501'
let g:syntastic_auto_loc_list=1
let g:syntastic_cpp_compiler = 'clang++'
let g:syntastic_cpp_compiler_options = ' -std=c++17 -stdlib=libc++'

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
let g:deoplete#sources#clang#libclang_path = '/usr/local/Cellar/llvm/7.0.1/lib/libclang.dylib'
let g:deoplete#sources#clang#clang_header = '/usr/local/Cellar/llvm/7.0.1/include/clang'
let g:deoplete#sources#clang#std = { 'cpp': 'c++17','c': 'c11', 'objc': 'c11', 'objcpp': 'c++1z' }
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

" =========================================================
"       Omnisharp completion
" =========================================================
let g:OmniSharp_server_stdio = 1
let g:OmniSharp_server_use_mono = 1

" Don't autoselect first omnicomplete option, show options even if there is only
" one (so the preview documentation is accessible). Remove 'preview' if you
" don't want to see any documentation whatsoever.
set completeopt=longest,menuone,preview

" =========================================================
"       Conqueror of Completions (coc) settings
" =========================================================
let g:coc_global_extensions=[ ]

" =========================================================
"       custom installed theme
" =========================================================
set background=dark
colorscheme palenight
