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
map <F2> :mksession! Session.vim <cr> " Quick write session with F2
map <F3> :source Session.vim <cr>     " And load session with F3

"Enable fuzzy file search
nnoremap <C-p> :FuzzyOpen<CR>
nnoremap <C-s> :FlyGrep<CR>

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

" Move visual selection
vnoremap J :m '>+1<cr>gv=gv
vnoremap K :m '<-2<cr>gv=gv

" Resource: https://superuser.com/questions/321547/how-do-i-replace-paste-yanked-text-in-vim-without-yanking-the-deleted-lines
" delete without yanking
nnoremap <leader>d "_d
vnoremap <leader>d "_d

" replace currently selected text with default register
" without yanking it
vnoremap p "_dP

" if Coc is installed, go to defition
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
