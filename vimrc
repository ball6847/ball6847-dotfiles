set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'

" ------------------------------------------------
" other bundles

Plugin 'flazz/vim-colorschemes'
Plugin 'tpope/vim-git'
Plugin 'Lokaltog/powerline', {'rtp': 'powerline/bindings/vim/'}
Plugin 'Yggdroot/indentLine'
Plugin 'jiangmiao/auto-pairs'
Plugin 'scrooloose/nerdtree'
Plugin 'kien/ctrlp.vim'
Plugin 'Shougo/neocomplete.vim'
Plugin 'scrooloose/nerdcommenter'
Plugin 'chrisbra/improvedft'
Plugin 'vim-scripts/L9'
Plugin 'othree/vim-autocomplpop'
Plugin 'lfilho/cosco.vim'
Plugin 'justinmk/vim-sneak'
Plugin 'StanAngeloff/php.vim'
Plugin 'groenewege/vim-less'
Plugin 'scrooloose/syntastic'
Plugin 'myusuf3/numbers.vim'
Plugin 'dkprice/vim-easygrep'
Plugin 'vim-scripts/upAndDown'
Plugin 'embear/vim-localvimrc'

" Syntax Plugins
Plugin 'evanmiller/nginx-vim-syntax'
Plugin 'kchmck/vim-coffee-script'
Plugin 'digitaltoad/vim-jade'

" snipmate
Plugin 'MarcWeber/vim-addon-mw-utils'
Plugin 'tomtom/tlib_vim'
Plugin 'garbas/vim-snipmate'
Plugin 'honza/vim-snippets'


" taglist.vim needs exuberant-ctags package installed
" run (sudo apt-get install exuberant-ctags) to install the package
Plugin 'vim-scripts/taglist.vim'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required

" ------------------------------------------------
" general options

syntax on

set tabstop=4
set shiftwidth=4
set expandtab
set smartindent
set number
set t_Co=256
set cursorline
set modeline
colorscheme Monokai
"set list lcs=tab:\┊\
"set list
"set listchars=tab:┊,trail:·,eol:,extends:>,precedes:<
filetype plugin on

" ------------------------------------------------
" powerline options

set laststatus=2 " always show powerbar
let g:Powerline_symbols = 'unicode'

" ------------------------------------------------
" indentLine

"let g:indentLine_char = '┊'
let g:indentLine_color_term = 239

" ------------------------------------------------
" localvimrc, auto source localvim file

let g:localvimrc_ask = 0 


" ------------------------------------------------
" keymap
"nnoremap <F3> :NumbersToggle<CR>
"nnoremap <F4> :NumbersOnOff<CR>

"nnoremap <silent> <Plug>Sneak_f :<c-u>call sneak#wrap('', 3, 0, 1, 0)<cr>
nnoremap <silent> s   :call sneak#wrap('', 3, 0, 1, 0)<cr>
nnoremap <silent> S   :call sneak#wrap('', 3, 1, 1, 0)<cr>
"onoremap <silent> F   :call sneak#wrap(v:operator, 1, 1, 1)<cr>

nnoremap <silent> <PageUp> <C-U>
vnoremap <silent> <PageUp> <C-U>
inoremap <silent> <PageUp> <C-\><C-O><C-U>

nnoremap <silent> <PageDown> <C-D>
vnoremap <silent> <PageDown> <C-D>
inoremap <silent> <PageDown> <C-\><C-O><C-D>

nmap <silent> <A-Up> :wincmd k<CR>
nmap <silent> <A-Down> :wincmd j<CR>
nmap <silent> <A-Left> :wincmd h<CR>
nmap <silent> <A-Right> :wincmd l<CR>
nmap <silent> <C-n> :NERDTreeToggle<CR>
imap <Home> <ESC>^i
map <F4> :TlistToggle<cr>

:command WQ wq
:command Wq wq
:command W w
:command Q q

autocmd FileType javascript,css,php nmap <silent> ,; :call cosco#commaOrSemiColon()<CR>
autocmd FileType javascript,css,php inoremap <silent> ,; <ESC>:call cosco#commaOrSemiColon()"<CR>a
autocmd FileType html,smarty setl sw=4 sts=4 et
autocmd FileType coffee,javascript,css,less setl sw=2 sts=2 et

"autocmd CursorMoved * exe printf('match IncSearch /\V\<%s\>/', escape(expand('<cword>'), '/\'))


" ------------------------------------------------
" syntastic (php, jshint, coffeelint)

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list=1
let g:syntastic_auto_loc_list=1
let g:syntastic_check_on_open=0
let g:syntastic_check_on_wq=1
let g:syntastic_php_checkers=['php', 'phpcs', 'phpmd']
let g:syntastic_coffee_checkers=['coffeelint']
let g:syntastic_coffee_coffeelint_exec='coffeelint'
let g:syntastic_javascript_checkers=['jshint']
let g:syntastic_javascript_jshint_exec='jshint'

" ------------------------------------------------
" vim-coffee-script, auto compile *.coffee to *.js on buffer written

autocmd BufWritePost *.coffee silent make! --no-header 

" ------------------------------------------------
" nerdtree options

set autochdir
let g:NERDTreeShowHidden=1
let g:NERDTreeIgnore=['\.swp$', '\.sublime-project$', '\.sublime-workspace', '\.komodo-project$']
nnoremap <leader>n :NERDTree .<CR>


" ------------------------------------------------
" auto change cursor shape based on current mode

if has("autocmd")
    au InsertEnter * silent execute "!gconftool-2 --type string --set /apps/gnome-terminal/profiles/Default/cursor_shape ibeam"
    au InsertLeave * silent execute "!gconftool-2 --type string --set /apps/gnome-terminal/profiles/Default/cursor_shape block"
    au VimLeave * silent execute "!gconftool-2 --type string --set /apps/gnome-terminal/profiles/Default/cursor_shape block"
endif

" ------------------------------------------------

if has('unix')
    cnoremap w!! %!sudo tee > /dev/null %
endif

if has("gui_running")
    if has("gui_gtk2")
        set guifont=Monaco\ 10
        colorscheme molokai
        " map ctrl+v ctrl+c
        nmap <C-V> "+gP
        imap <C-V> <ESC><C-V>i
        vmap <C-C> "+y
    endif
endif
" -------------------------------------------------
" vdebug - dbgp server configuration

let g:vdebug_options = {
\ 'server': '0.0.0.0',
\ 'port': '9022'
\}

