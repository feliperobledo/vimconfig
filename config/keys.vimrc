"This keymap changes navigation between windows to only have to use 
"Ctrl+h/j/k/l
map <C-J> <C-W>j<C-W>_
map <C-K> <C-W>k<C-W>_
map <C-L> <C-W>l<C-W>_
map <C-H> <C-W>h<C-W>_

"Remap the movement keys
noremap ; l
noremap o k
noremap l j
noremap k h

"Collapse each opened file into a single line with its filename
set wmh=0

"Tab navigation mappings
nnoremap <F7>      :tabprevious<CR>
nnoremap <F8>      :tabnext<CR>
nnoremap <C-t>     :tabnew<CR>
inoremap <F7>      <Esc>:tabprevious<CR>i
inoremap <F8>      <Esc>:tabnext<CR>i
inoremap <C-t>     <Esc>:tabnew<CR>i

"Enable fuzzy file search
nnoremap <C-p> :FuzzyOpen<CR>

"Enable nerdtree
map <C-n> :NERDTreeToggle<CR>

" virtual tabstops using spaces
let my_tab=4
execute "set shiftwidth=".my_tab
execute "set softtabstop=".my_tab
set expandtab
" allow toggling between local and default mode
function! TabToggle()
  if &expandtab
    set shiftwidth=8
    set softtabstop=0
    set noexpandtab
  else
    execute "set shiftwidth=".g:my_tab
    execute "set softtabstop=".g:my_tab
    set expandtab
  endif
endfunction
nmap <F9> mz:execute TabToggle()<CR>'z
