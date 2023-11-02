# Boop.vim

## Installing
Haven't looked at Vim package managers or prebuilt binaries yet. You'll have to build from source.

## Building from source

### Requirements
Linux, Rust. 

1. Clone this repo
2. Clone all the submodules: `git submodule update --init --recursive`
3. Install the boop binary: `cargo install --path .`
4. Source the vim file from your .vimrc: `source 'boop-prototype.vim'`
5. Add bindings to your .vimrc:
```
"
" The boop pad is a scratch pad emulating some of the Boop app
" From normal mode, press <ctrl-b> to open or focus the boop scratch pad.
nnoremap <c-b> :BoopPad<cr>
" If you'd rather open the boop pad vertically, add the vertical modifier
"nnoremap <c-b> :vertical BoopPad<cr>

" From visual mode, press <ctrl-b> to run a boop script on the selection
xnoremap <c-b> :Boop<space>
" Or, use <ctrl-b> in visual mode to populate the boop pad with the selection
"xnoremap <c-b> :BoopPadSelection<cr>


" remap keys within the boop pad
augroup boop_mapping
    autocmd!
    autocmd BufEnter,BufFilePost \[Boop] call s:BoopMapping()
augroup END

function! s:BoopMapping()
    " Within the scratch pad, press <ctrl-b> to run a script over the whole pad.
    " Press <ctrl-l> to see a listing of all boop scripts.
    nnoremap <buffer> <c-b> :BoopBuffer<space>
    xnoremap <buffer> <c-b> :Boop<space>
    nnoremap <buffer> <c-l> :ListBoopScripts<cr>
endfunction
```
