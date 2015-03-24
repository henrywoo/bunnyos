
```
set nocompatible
source $VIMRUNTIME/vimrc_example.vim
source $VIMRUNTIME/mswin.vim
behave mswin

"utf-8
set enc=utf-8
set encoding=utf-8

"set expandtab
set tabstop=4
set shiftwidth=4
set nowrapscan
set ignorecase
colorscheme evening
"colorscheme desert
"colorscheme zellner
set wrapscan
set guifont=consolas:h11
set nu

"ctags
set tags=tags;
set autochdir

"Taglist
let Tlist_Show_One_File=1
let Tlist_Exit_OnlyWindow=1
nmap tt :Tlist<CR>

"Windows manager
let g:winManagerWindowLayout='FileExplorer|TagList'
nmap wm :WMToggle<CR>

"Key binding"
nmap <C-n> :tabnew<CR> 
nmap <C-d> :tabc<CR> 
nmap <C-o> :tabe<SPACE> 

"Multifile edit
let g:miniBufExplMapCTabSwitchBufs=1
let g:miniBufExplMapWindowsNavVim=1
let g:miniBufExplMapWindowNavArrows=1

"switch between h/cpp/c
nnoremap <silent> <F12> :A<CR>

"grep
nnoremap <silent> <F3> :Grep<CR>

set diffexpr=MyDiff()
function MyDiff()
  let opt = '-a --binary '
  if &diffopt =~ 'icase' | let opt = opt . '-i ' | endif
  if &diffopt =~ 'iwhite' | let opt = opt . '-b ' | endif
  let arg1 = v:fname_in
  if arg1 =~ ' ' | let arg1 = '"' . arg1 . '"' | endif
  let arg2 = v:fname_new
  if arg2 =~ ' ' | let arg2 = '"' . arg2 . '"' | endif
  let arg3 = v:fname_out
  if arg3 =~ ' ' | let arg3 = '"' . arg3 . '"' | endif
  let eq = ''
  if $VIMRUNTIME =~ ' '
    if &sh =~ '\<cmd'
      let cmd = '""' . $VIMRUNTIME . '\diff"'
      let eq = '"'
    else
      let cmd = substitute($VIMRUNTIME, ' ', '" ', '') . '\diff"'
    endif
  else
    let cmd = $VIMRUNTIME . '\diff'
  endif
  silent execute '!' . cmd . ' ' . opt . arg1 . ' ' . arg2 . ' > ' . arg3 . eq
endfunction


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set history=700

" Turn backup off, since most stuff is in SVN, git anyway...
set nobackup
set nowb
set noswapfile

```