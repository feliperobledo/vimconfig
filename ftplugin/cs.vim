setlocal ts=4 sts=4 sw=4 expandtab

" Taken from: https://vim.fandom.com/wiki/Fold_a_C_sharp_region
" zf% - folds region
" zo - unfolds region
let b:match_words = '\s*#\s*region.*$:\s*#\s*endregion'

" =========================================================
"       Omnisharp completion
" =========================================================
" Show type information automatically when the cursor stops moving.
" Note that the type is echoed to the Vim command line, and will overwrite
" any other messages in this space including e.g. ALE linting messages.
autocmd CursorHold *.cs OmniSharpTypeLookup

" The following commands are contextual, based on the cursor position.
nnoremap <buffer> gd :OmniSharpGotoDefinition<CR>
nnoremap <buffer> <Leader>fi :OmniSharpFindImplementations<CR>
nnoremap <buffer> <Leader>fs :OmniSharpFindSymbol<CR>
nnoremap <buffer> <Leader>fu :OmniSharpFindUsages<CR>

" Finds members in the current buffer
nnoremap <buffer> <Leader>fm :OmniSharpFindMembers<CR>

nnoremap <buffer> <Leader>fx :OmniSharpFixUsings<CR>
nnoremap <buffer> <Leader>tt :OmniSharpTypeLookup<CR>
nnoremap <buffer> <Leader>dc :OmniSharpDocumentation<CR>
nnoremap <buffer> <C-\> :OmniSharpSignatureHelp<CR>
inoremap <buffer> <C-\> <C-o>:OmniSharpSignatureHelp<CR>

" Find all code errors/warnings for the current solution and populate the quickfix window
nnoremap <buffer> <Leader>cc :OmniSharpGlobalCodeCheck<CR>
