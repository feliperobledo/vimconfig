"Display line numbers
set number

"Don't wrap lines by default
"set nowrap
set textwidth=140

"Enable mouse support
set mouse=a

"Change Background color past the accepted line length
set colorcolumn=140
highlight ColorColumn ctermbg=235 guibg=#2c2d27
let &colorcolumn=join(range(141,999),",")

"Display tabs as >-- and display empty spaces
set list!
set listchars=tab:>-,trail:.,precedes:<,extends:>

"Set the type of manual fold
"--Types
"  -- manual: in visual mode, press 
"            -- z+f to fold
"            -- z+o to open fold
"            -- z+d to delete all lines in the fold
set foldmethod=manual

"C language options
let c_no_trail_space_error = 1
let c_no_tab_space_error = 1

"Javascript language options
autocmd Filetype javascript setlocal ts=4 sts=4 sw=4 expandtab

"C++ language options
autocmd Filetype cpp setlocal ts=4 sts=4 sw=4 expandtab

"Java language options
autocmd Filetype java setlocal ts=4 sts=4 sw=4 expandtab

"HTML language options
autocmd FileType html setlocal ts=4 sts=4 sw=4 expandtab
