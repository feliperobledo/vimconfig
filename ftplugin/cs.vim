setlocal ts=4 sts=4 sw=4 expandtab

" Taken from: https://vim.fandom.com/wiki/Fold_a_C_sharp_region
" zf% - folds region
" zo - unfolds region
let b:match_words = '\s*#\s*region.*$:\s*#\s*endregion'
