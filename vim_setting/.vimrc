"utf-8
set enc=utf-8

syntax on

set tabstop=2
set shiftwidth=2
set expandtab

"set nowrapscan
set ignorecase
colorscheme desert
set guifont=consolas:h10
set nu

"Key binding"
nmap <C-n> :tabnew<CR> 
nmap <C-d> :tabc<CR> 
nmap <C-o> :tabe<SPACE> 


let Tlist_Show_One_File=1
let Tlist_Exit_OnlyWindow=1
nmap tt :Tlist<CR>


set tags=tags
set autochdir

"code completion
filetype plugin indent on
set completeopt=longest,menu


let g:winManagerWindowLayout='FileExplorer|TagList'
nmap wm :WMToggle<cr>

"Multifile edit
let g:miniBufExplMapCTabSwitchBufs=1
let g:miniBufExplMapWindowsNavVim=1
let g:miniBufExplMapWindowNavArrows=1


nnoremap <silent> <F12> :A<CR>


nnoremap <silent> <F3> :Grep<CR>


"buffer window resize
if bufwinnr(1)
	map + <C-W>+
	map - <C-W>-
endif

