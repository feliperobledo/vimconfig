" =========================================================
"       vim-polyglot
" =========================================================
" needs to be declared before polyglot is loaded
let g:polyglot_disabled = ['typescript']

call plug#begin('~/.config/nvim/plugged')


" =================================================================================
"                         Autocompletetion engine
" =================================================================================
"" Use release branch
Plug 'neoclide/coc.nvim', {'branch': 'release'}


" =================================================================================
"                         C# engine
" =================================================================================
" coc doesn't support C# very well, yet. Until then, we need these configs.

" Omnisharp (c#) completion
Plug 'OmniSharp/omnisharp-vim'

" Syntax highlighting
Plug 'w0rp/ale'

" =================================================================================
"                         Working with git
" =================================================================================
" Work with Git on Vim
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'

" =================================================================================
"                         C++ engine
" =================================================================================
Plug 'rhysd/vim-clang-format', {'for' : ['c', 'cpp']}


" =================================================================================
"                         Debugging Tools
" =================================================================================
" TODO: look into dap configuration
" Plug 'mfussenegger/nvim-dap'

" C++ debugging
Plug 'sakhnik/nvim-gdb', { 'do': ':!./install.sh' }

" =================================================================================
"                         Editor Actions
" =================================================================================
"
" Mimic Control+Shift Find of a reference across a project, and edit all references in place
Plug 'dyng/ctrlsf.vim'

" Plugin to surround word under cursor with whatever
Plug 'tpope/vim-surround'

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

if has('nvim-0.5')
" telescope previewer for neovim 0.5
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
else

" Fuzzy file search
" requires: brew install ripgrep the_silver_searcher
Plug 'cloudhead/neovim-fuzzy'

endif

" =================================================================================
"                         File syntax
" =================================================================================

" The only file syntax highlighter you will need
Plug 'sheerun/vim-polyglot'

" For C# development
Plug 'tomasiser/vim-code-dark'

" =================================================================================
"                        Themes
" =================================================================================
Plug 'drewtempelmeyer/palenight.vim'

" =================================================================================
"                        Documentation Helpers
" =================================================================================
" Plug 'JamshedVesuna/vim-markdown-preview'

" PlanUML live previewer
" Plug 'tyru/open-browser.vim' " dependency of platuml-previewer
" Plug 'weirongxu/plantuml-previewer.vim'
"
" =================================================================================
"                        Look n' Feel
" =================================================================================
" Add a status line. Helps with keeping track of git branch and others. Super useful
" when working with git worktrees.
Plug 'hoob3rt/lualine.nvim'
" If you want to have icons in your statusline choose one of these
" Plug 'kyazdani42/nvim-web-devicons'

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

" Tell ALE to use OmniSharp for linting C# files, and no other linters.
let g:ale_linters = { 'cs': ['OmniSharp'] }
" Only run linters named in ale_linters settings.
let g:ale_linters_explicit = 1

" =========================================================
"       Conqueror of Completions (coc) settings
" =========================================================
let g:coc_global_extensions=[
    \'coc-json',
    \'coc-tsserver',
    \'coc-eslint',
    \'coc-python',
    \'coc-pyls',
    \'coc-java',
    \'coc-java-debug',
    \'coc-css',
    \'coc-snippets',
    \'coc-prettier',
    \'coc-highlight',
\]

" =========================================================
"       coc-highlighting
" =========================================================

" =========================================================
"       coc-snippets
" =========================================================
" Use <C-l> for trigger snippet expand.
imap <leader>ll <Plug>(coc-snippets-expand)

" Use <C-j> for select text for visual placeholder of snippet.
vmap <leader>jj <Plug>(coc-snippets-select)

" Make <tab> used for trigger completion, completion confirm, snippet expand and jump like VSCode.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? coc#_select_confirm() :
      \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

let g:coc_snippet_next = '<tab>'


" =========================================================
"       custom installed theme
" =========================================================
set background=dark
colorscheme palenight

" =========================================================
"       markdown helper
" =========================================================
" this is the hotkey when viewing the docs
let vim_markdown_preview_hotkey='<C-l>'

" because I'm using grip to render markdown
let vim_markdown_preview_github=1

" enable rendering images on buffer write
let vim_markdown_preview_toggle=2

" set my default browser
let vim_markdown_preview_browser='Google Chrome'

" =========================================================
"       coc snippets
" =========================================================
" Use <C-l> for trigger snippet expand.
imap <C-l> <Plug>(coc-snippets-expand)

" Use <C-j> for select text for visual placeholder of snippet.
vmap <C-j> <Plug>(coc-snippets-select)

" Use <C-j> for jump to next placeholder, it's default of coc.nvim
let g:coc_snippet_next = '<c-j>'

" Use <C-k> for jump to previous placeholder, it's default of coc.nvim
let g:coc_snippet_prev = '<c-k>'

" Use <C-j> for both expand and jump (make expand higher priority.)
imap <C-j> <Plug>(coc-snippets-expand-jump)

" =========================================================
"       nvim-gdb config
" =========================================================

" Disable the gdb debugger by default. If the project wants to use it, they will set it back
" let g:loaded_nvimgdb = 1

" We're going to define single-letter keymaps, so don't try to define them
" in the terminal window.  The debugger CLI should continue accepting text commands.
function! NvimGdbNoTKeymaps()
  tnoremap <silent> <buffer> <esc> <c-\><c-n>
endfunction

let g:nvimgdb_config_override = {
  \ 'key_next': 'n',
  \ 'key_step': 's',
  \ 'key_finish': 'f',
  \ 'key_continue': 'c',
  \ 'key_until': 'u',
  \ 'key_breakpoint': 'b',
  \ 'set_tkeymaps': "NvimGdbNoTKeymaps",
  \ }
