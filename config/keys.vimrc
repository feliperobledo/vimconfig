"This keymap changes navigation between windows to only have to use 
"Ctrl+h/j/k/l
map <C-J> <C-W>j<C-W>_
map <C-K> <C-W>k<C-W>_
map <C-L> <C-W>l<C-W>_
map <C-H> <C-W>h<C-W>_

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
