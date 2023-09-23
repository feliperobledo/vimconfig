"Don't wrap lines by default
"set nowrap
set textwidth=140

"Enable mouse support
set mouse=a

"Change Background color past the accepted line length
" set colorcolumn=140
" highlight ColorColumn ctermbg=235 guibg=#2c2d27
" let &colorcolumn=join(range(141,999),",")

"Display tabs as >-- and display empty spaces
set list!
set listchars=tab:>-,trail:.,precedes:<,extends:>

"Close neovim if the only window left is NERDTree
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

"Set the type of manual fold
"--Types
"  -- manual: in visual mode, press 
"            -- z+f to fold
"            -- z+o to open fold
"            -- z+d to delete all lines in the fold
set foldmethod=manual

" Use the OSX clipboard by default
set clipboard=unnamed

" enable project speficific vimrc
set exrc
"set secure

" ensure cursor always stays at screen middle
set so=999


"=============================================================================-
"                           Language Options
"==============================================================================

" Do not select the first thing COC suggests
let coc_config_suggest_noselect = 1

"C language options
let c_no_trail_space_error = 1
let c_no_tab_space_error = 1

"Javascript language options
autocmd Filetype javascript setlocal ts=4 sts=4 sw=4 expandtab

"C++ language options
autocmd Filetype cpp setlocal ts=4 sts=4 sw=4 expandtab

"HTML language options
autocmd FileType html setlocal ts=4 sts=4 sw=4 expandtab

"typescript language options
autocmd FileType typescript setlocal ts=4 sts=4 sw=4 expandtab

"json files options
autocmd FileType json setlocal ts=2 sts=2 sw=2 expandtab

"ruby file options
autocmd FileType ruby setlocal ts=2 sts=2 sw=2 expandtab
autocmd BufNewFile,BufRead *.feature setlocal syntax=ruby
