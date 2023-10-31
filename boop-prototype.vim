
" You may prefer a different value than -3 below
function! ListBoopScripts()
    !echo; boop -l | pr -3 -t
endfunction

" Required for refocusing the scratch pad
set switchbuf +=useopen

function! BoopPad(mods)
    try
        try
            exec a:mods "sbuffer \\[Boop]"
        catch
            exec a:mods "new +file \\[Boop]"
        endtry
        setlocal nobuflisted buftype=nofile bufhidden=delete noswapfile
    endtry

    " add a convenience mapping for <c-b> in the [Boop] buffer
    " TODO: make this a user-defined event
    "nnoremap <buffer> <c-b> ggVG:Boop 
endfunction
command! BoopPad call BoopPad(<q-mods>)

" Make a simple command wrapper around !boop with autocompletion
function! BoopCompletion(ArgLead, CmdLine, CursorPos)
    return system("boop -l")
endfunction
command! -range -nargs=1 -complete=custom,BoopCompletion Boop '<,'>!boop <f-args>

"
" From normal mode, press <ctrl-b> to open or focus the boop scratch pad.
" Within the scratch pad, press <ctrl-b> to run a script over the whole pad.
" Press <ctrl-l> to see all boop scripts.

" The boop pad is a scratch pad emulating some of the Boop app
nnoremap <c-b> :BoopPad<cr>
" If you'd rather open the boop pad vertically, add the vertical modifier
"nnoremap <c-b> :vertical BoopPad<cr>

nnoremap <c-l> :call ListBoopScripts()<cr>

" Use the `:Boop [script name]` command to Boop some line-wise selected text
" Note that you can't run a command on char-wise or block-wise selections

" remap keys within the boop pad
augroup boop_mapping
    autocmd!
    autocmd BufEnter,BufFilePost \[Boop] call s:BoopMapping()
augroup END

function! s:BoopMapping()
    nnoremap <buffer> <c-b> ggVG:Boop<space>
endfunction
