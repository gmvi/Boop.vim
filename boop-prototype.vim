"
" From visual mode, press <ctrl-b> to get a prompt to choose a boop script.
" Note that tab autocompletion mostly works
"
" From normal mode, press <ctrl-b> to open or focus the boop scratch pad.
" Within the scratch pad, press <ctrl-b> to run a script over the whole pad.
" Press <ctrl-l> to see all boop scripts.

" The boop pad is a scratch pad emulating some of the Boop app
nnoremap <c-b> :BoopPad<cr>
" If you'd rather open the boop pad a different way, add a modifier
"nnoremap <c-b> :vertical BoopPad<cr>
" Note that tabular boop pads will not refocus automatically
"nnoremap <c-b> :tab BoopPad<cr>

xnoremap <c-b> :Boop 
" You may prefer a different value than -3 below
nnoremap <c-l> :!echo; boop -l \| pr -3 -t<cr>

" Required for refocusing the scratch pad
set switchbuf +=useopen

function! ScratchPad(mods, name)
    try
        if a:name == "*"
            exec a:mods "new"
        else
            let name = fnameescape(a:name)
            try
                exec a:mods "sbuffer \\[" . name . "]"
            catch
                exec a:mods "new +file \\[" . name . "]"
            endtry
        endif
        setlocal nobuflisted buftype=nofile bufhidden=delete noswapfile
    endtry
endfunction
command! -nargs=1 Scratch call ScratchPad(<q-mods>, <q-args>)


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
    nnoremap <buffer> <c-b> ggVG:Boop 
endfunction
command! BoopPad call BoopPad(<q-mods>)

" Make a simple command wrapper around !boop with autocompletion
function! BoopCompletion(ArgLead, CmdLine, CursorPos)
    return system("boop -l")
endfunction
command! -range -nargs=1 -complete=custom,BoopCompletion Boop '<,'>!boop <f-args>

