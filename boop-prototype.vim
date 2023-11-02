
""" The boop pad
" Required for refocusing the scratch pad
set switchbuf +=useopen

function! s:BoopPad(mods) abort
    try
        exec a:mods "sbuffer \\[Boop]"
    catch
        exec a:mods "new +file \\[Boop]"
    endtry
    setlocal nobuflisted buftype=nofile bufhidden=hide noswapfile
endfunction
command! BoopPad call s:BoopPad(<q-mods>)

function! s:BoopPadSelection(mods) abort
    " defensive programming; register should be a single-char string
    let l:boop_reg = s:boopRegister[0]
    " remember the user's old register contents
    let l:reg_old = getreg(l:boop_reg)
    try
        silent exec "'<,'>yank" l:boop_reg
        BoopPad
        %delete _
        exec "normal" "V\""..l:boop_reg.."p"
    endtry
    call setreg(l:boop_reg, l:reg_old)
endfunction
command! -range BoopPadSelection call s:BoopPadSelection(<q-mods>)


""" Display all scripts
" You may prefer a different value than -3 below
if has('unix') || has('osxunix')
    command! ListBoopScripts !echo; boop -l | pr -3 -t
elseif has('win32')
    command! ListBoopScripts !echo.& boop -l
endif


""" Do the booping
function! s:BoopCompletion(ArgLead, CmdLine, CursorPos)
    return system("boop -l")
endfunction

let s:boopRegister = 'x'
function! s:DoRegisterBoop(args) abort
    " defensive programming; register should be a single-char string
    let l:boop_reg = s:boopRegister[0]
    " the `, 1, 1` below is to not translate NULs to newlines
    let l:selection = getreg(l:boop_reg, 1, 1)
    let l:cmd_list = ['boop', shellescape(a:args)]
    if has('unix') || has ('macosunix')
        let l:cmd_list = l:cmd_list + ['2>/dev/null']
    elseif has('win32')
        let l:cmd_list = l:cmd_list + ['2>NUL']
    else
        throw "unsupported platform"
    endif
    let l:output = system(join(l:cmd_list), l:selection)
    if v:shell_error == 0
        call setreg(boop_reg, l:output)
    else
        " run the command again and capture stderr instead of stdout
        let l:cmd_list = l:cmd_list[:-2] + ["1"..(l:cmd_list[-1][1:])]
        let l:output = system(join(l:cmd_list), l:selection)
        echohl ErrorMsg
        if v:shell_error == 0
            echom "Boop.vim encountered a fatal error"
        else
            echom "Boop returned the following error:"
            echom trim(l:output)
        endif
        echohl None
    endif
endfunction

" Boops the entire buffer
function! s:BoopBuffer(args) abort
    " defensive programming; register should be a single-char string
    let l:boop_reg = s:boopRegister[0]
    " remember the user's old register contents
    let l:reg_old = getreg(l:boop_reg)
    try
        silent exec "%yank" l:boop_reg
        call s:DoRegisterBoop(a:args)
        silent exec "normal" "gg\"_dG\""..l:boop_reg.."P"
    endtry
    call setreg(l:boop_reg, l:reg_old)
endfunction
command! -nargs=* -complete=custom,s:BoopCompletion BoopBuffer call s:BoopBuffer(<q-args>)

" Boops the current line. Does not affect the recent selection (gv)
function! s:BoopLine(args) abort
    " defensive programming; register should be a single-char string
    let l:boop_reg = s:boopRegister[0]
    " remember the user's old register contents
    let l:reg_old = getreg(l:boop_reg)
    try
        silent exec "yank" l:boop_reg
        call s:DoRegisterBoop(a:args)
        " do a `substitute` instead of some normal dd/P command, cause it
        " wasn't working for me.
        let l:search_reg = getreg('/')
        silent exec "substitute" "/.*/\\=@"..l:boop_reg.."/"
        call setreg('/', l:search_reg)
    endtry
    call setreg(l:boop_reg, l:reg_old)
endfunction
command! -nargs=* -complete=custom,s:BoopCompletion BoopLine call s:BoopLine(<q-args>)

" Boops the most recent selection (i.e. the current selection if triggered
" from visual mode)
" TODO: bugfix: `vap:boop [script]<cr>` removes a newline
function! s:BoopSelection(args) abort
    " defensive programming; register should be a single-char string
    let l:boop_reg = s:boopRegister[0]
    " remember the user's old register contents
    let l:reg_old = getreg(l:boop_reg)
    try
        silent exec "normal" "gv\""..l:boop_reg.."y"
        call s:DoRegisterBoop(a:args)
        silent exec "normal" "gv\""..l:boop_reg.."p"
    endtry
    call setreg(l:boop_reg, l:reg_old)
endfunction
command! -nargs=* -complete=custom,s:BoopCompletion -range Boop call s:BoopSelection(<q-args>)

