" Don't be a noob, join the no arrows key movement
inoremap  <Up>     <NOP>
inoremap  <Down>   <NOP>
inoremap  <Left>   <NOP>
inoremap  <Right>  <NOP>
noremap   <Up>     <NOP>
noremap   <Down>   <NOP>
noremap   <Left>   <NOP>
noremap   <Right>  <NOP>"

"This keymap changes navigation between windows to only have to use 
"Ctrl+h/j/k/l
map <C-J> <C-W>j<C-W>_
map <C-K> <C-W>k<C-W>_
map <C-L> <C-W>l<C-W>_
map <C-H> <C-W>h<C-W>_

"Collapse each opened file into a single line with its filename
set wmh=0

"Tab navigation mappings
nnoremap <F8>      :tabprevious<CR>
nnoremap <F9>      :tabnext<CR>
nnoremap <C-t>     :tabnew<CR>
inoremap <F8>      <Esc>:tabprevious<CR>i
inoremap <F9>      <Esc>:tabnext<CR>i
inoremap <C-t>     <Esc>:tabnew<CR>i
map <F2> :mksession! Session.vim <cr> " Quick write session with F2
map <F3> :source Session.vim <cr>     " And load session with F3

"Enable fuzzy file search
if has('nvim-0.5')
    nnoremap <leader>ff <cmd>Telescope find_files<cr>
    nnoremap <leader>fg <cmd>Telescope live_grep<cr>
    nnoremap <leader>fb <cmd>Telescope buffers<cr>
    nnoremap <leader>fh <cmd>Telescope help_tags<cr>
    nnoremap <leader>ft <cmd>Telescope git_files<cr>
else
    nnoremap <C-p> :FuzzyOpen<CR>
    nnoremap <C-s> :FlyGrep<CR>
endif

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
nmap <F10> mz:execute TabToggle()<CR>'z

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
