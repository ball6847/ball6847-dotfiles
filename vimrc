" ------------------------------------------------
" External programs you may need to install
"
" ================================================================================================
" PACKAGE         | DESCRIPTION                            | INSTALL COMMAND
" =================================================================================================
" python-autopep8 | formatter for python                   | sudo apt-get install python-autopep8
" js-beautify     | formatter fot javascript,json,css,html | npm install -g js-beautify
" tidy            | formatter for xhtml,xml                | sudo apt-get install tidy
" ack-grep        | find in files using :Ack command       | sudo apt-get install ack-grep
" coffee-script   | coffee script compiler                 | npm install -g coffee-script
" coffeelint      | coffee script linter                   | npm install -g coffeelint
" jshint          | javascript linter                      | npm install -g jshint
" ================================================================================================


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
"Plugin 'tpope/vim-git'
"Plugin 'Lokaltog/powerline', {'rtp': 'powerline/bindings/vim/'}
Plugin 'itchyny/lightline.vim'
Plugin 'Yggdroot/indentLine'
Plugin 'jiangmiao/auto-pairs'
Plugin 'scrooloose/nerdtree'
Plugin 'Xuyuanp/nerdtree-git-plugin'
"Plugin 'jistr/vim-nerdtree-tabs'
Plugin 'kien/ctrlp.vim'
Plugin 'Shougo/neocomplete.vim'
Plugin 'scrooloose/nerdcommenter'
Plugin 'chrisbra/improvedft'
Plugin 'vim-scripts/L9'
Plugin 'othree/vim-autocomplpop'
Plugin 'lfilho/cosco.vim'
"Plugin 'justinmk/vim-sneak'
Plugin 'StanAngeloff/php.vim'
Plugin 'groenewege/vim-less'
Plugin 'scrooloose/syntastic'
Plugin 'myusuf3/numbers.vim'
"Plugin 'dkprice/vim-easygrep'
Plugin 'vim-scripts/upAndDown'
Plugin 'embear/vim-localvimrc'
Plugin 'godlygeek/tabular'
Plugin 'tpope/vim-surround'
Plugin 'mattn/emmet-vim'
Plugin 'majutsushi/tagbar'
"Plugin 'jszakmeister/vim-togglecursor'
Plugin 'haya14busa/incsearch.vim'
"Plugin 'mileszs/ack.vim' " make sure you have ack installed on your system use `sudo apt-get install ack-grep` to install it
Plugin 'gregsexton/MatchTag'
Plugin 'tmhedberg/matchit'
Plugin 'Chiel92/vim-autoformat'
Plugin 'Lokaltog/vim-easymotion'
Plugin 'elzr/vim-json'
Plugin 'ntpeters/vim-better-whitespace'
Plugin 'terryma/vim-expand-region'

" Syntax Plugins
Plugin 'evanmiller/nginx-vim-syntax'
Plugin 'kchmck/vim-coffee-script'
Plugin 'digitaltoad/vim-jade'
Plugin 'ekalinin/Dockerfile.vim'

" snipmate
Plugin 'MarcWeber/vim-addon-mw-utils'
Plugin 'tomtom/tlib_vim'
Plugin 'garbas/vim-snipmate'
Plugin 'honza/vim-snippets'

" additional colorscheme
"Plugin 'stulzer/heroku-colorscheme'

" taglist.vim needs exuberant-ctags package installed
" run (sudo apt-get install exuberant-ctags) to install the package
"Plugin 'vim-scripts/taglist.vim'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required

" ------------------------------------------------
" general options

syntax on

set tabstop=4
set bs=2 " enable backspace key for windows
set shiftwidth=4
set expandtab
set smartindent
set number
set t_Co=256
set cursorline
set modeline
set backupcopy=yes
"colorscheme molokai
filetype plugin on

let mapleader=','
let g:vim_json_syntax_conceal = 0

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
let g:localvimrc_sandbox = 0

" ------------------------------------------------
" Toggle tagbar using F8

nmap <F8> :TagbarToggle<CR>

" ------------------------------------------------
" Vim incsearch plugin

map /  <Plug>(incsearch-forward)
map ?  <Plug>(incsearch-backward)
map g/ <Plug>(incsearch-stay)


" ------------------------------------------------
" keymap
"nnoremap <F3> :NumbersToggle<CR>
"nnoremap <F4> :NumbersOnOff<CR>

"nnoremap <silent> <Plug>Sneak_f :<c-u>call sneak#wrap('', 3, 0, 1, 0)<cr>
"nnoremap <silent> s   :call sneak#wrap('', 3, 0, 1, 0)<cr>
"nnoremap <silent> S   :call sneak#wrap('', 3, 1, 1, 0)<cr>
"onoremap <silent> F   :call sneak#wrap(v:operator, 1, 1, 1)<cr>

nnoremap <silent> <PageUp> <C-U>
vnoremap <silent> <PageUp> <C-U>
inoremap <silent> <PageUp> <C-\><C-O><C-U>

nnoremap <silent> <PageDown> <C-D>
vnoremap <silent> <PageDown> <C-D>
inoremap <silent> <PageDown> <C-\><C-O><C-D>

nnoremap <silent> <C-Right> W
nnoremap <silent> <C-Left> B

" ctrl+s to save current buffer
" this only work in gui mode
if has("gui_running")
    nmap <c-s> :w<cr>
    imap <c-s> <esc>:w<cr>a
endif

nmap <silent> <A-Up> :wincmd k<CR>
nmap <silent> <A-Down> :wincmd j<CR>
nmap <silent> <A-Left> :wincmd h<CR>
nmap <silent> <A-Right> :wincmd l<CR>
imap <Home> <ESC>^i
"map <F4> :TlistToggle<cr>
"
nmap s <Plug>(easymotion-s)
nmap <leader></leader> <Plug>(easymotion-s)

" emmet
let g:user_emmet_expandabbr_key = '<C-E>'

" indenting maintain previous visual range, also map to TAB key
vnoremap > >gv
vnoremap < <gv
nnoremap <Tab> >>_
nnoremap <S-Tab> <<_
inoremap <S-Tab> <C-D>
vnoremap <Tab> >gv
vnoremap <S-Tab> <gv


:command WQ wq
:command Wq wq
:command W w
:command Q q



autocmd BufRead,BufNewFile *.cnf set filetype=dosini " treat .cnf as dosini, eg my.cnf
autocmd FileType javascript,css,php nmap <silent> ,; :call cosco#commaOrSemiColon()<CR>
autocmd FileType javascript,css,php inoremap <silent> ,; <ESC>:call cosco#commaOrSemiColon()"<CR>a
autocmd FileType html,smarty setl sw=2 sts=2 et
autocmd FileType coffee,css,less,jade,javascript,yml,yaml setl sw=2 sts=2 et
"autocmd FileType smarty so /home/ball6847/.vim/bundle/MatchTag/ftplugin/html.vim
"autocmd BufEnter * colorscheme heroku
"autocmd BufEnter *.tpl colorscheme molokai
"autocmd BufEnter *.html colorscheme molokai

" auto remove trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e

let g:formatprg_smarty = "html-beautify"
let g:formatprg_args_expr_smarty = '"-f - -s ".&shiftwidth'
noremap <F3> :Autoformat<CR><CR>



vnoremap <C-3> <leader>cl


" highlight words while we are moving cursor
"autocmd CursorMoved * exe printf('match IncSearch /\V\<%s\>/', escape(expand('<cword>'), '/\'))

" Tabular Customization
nnoremap <leader>a= :Tabularize /=<CR>
vnoremap <leader>a= :Tabularize /=<CR>
nnoremap <leader>a: :Tabularize /:<CR>
vnoremap <leader>a: :Tabularize /:<CR>

" ------------------------------------------------
" syntastic (php, jshint, coffeelint)

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list=1
let g:syntastic_auto_loc_list=1
let g:syntastic_check_on_open=0
let g:syntastic_coffee_checkers=['coffeelint']
let g:syntastic_coffee_coffeelint_exec='coffeelint'
let g:syntastic_coffee_coffeelint_args='-f ~/.coffeelint.json'
let g:syntastic_javascript_checkers=['jshint']
let g:syntastic_javascript_jshint_exec='jshint'

" ------------------------------------------------
" vim-coffee-script, auto compile *.coffee to *.js on buffer written

"autocmd BufWritePost *.coffee silent make! --no-header

" ------------------------------------------------
"  ctrlp configuration
let g:ctrlp_working_path_mode = 'r'

" ------------------------------------------------
" nerdtree options

"set autochdir
let g:NERDTreeShowHidden=1
let g:NERDTreeIgnore=['\.swp$', '\.sublime-project$', '\.sublime-workspace', '\.komodo-project$']
let g:nerdtree_tabs_open_on_gui_startup=0
let g:nerdtree_tabs_open_on_console_startup=0
"nmap <silent> <C-n> :NERDTreeTabsToggle<CR>
"nnoremap <leader>n :NERDTreeTabsOpen .<CR>
nmap <silent> <C-n> :NERDTreeToggle<CR>
nnoremap <leader>n :NERDTreeOpen .<CR>

" nerdtree git
set shell=sh
let g:NERDTreeIndicatorMapCustom = {
\ "Modified"  : "✹",
\ "Staged"    : "✚",
\ "Untracked" : "✭",
\ "Renamed"   : "➜",
\ "Unmerged"  : "═",
\ "Deleted"   : "✖",
\ "Dirty"     : "✗",
\ "Clean"     : "✔︎",
\ "Unknown"   : "?"
\}

" ------------------------------------------------
" tagbar options , open tagbar on startup

" use this on .lvimrc to make it more ide taste
"autocmd VimEnter * nested :TagbarOpen
"let g:nerdtree_tabs_open_on_console_startup=1

" ------------------------------------------------

if has('unix')
    cnoremap w!! %!sudo tee > /dev/null %
endif

if has("gui_running")
    if has("gui_gtk2")
        colorscheme badwolf
        "set guifont=Courier\ New\ 11
        vmap <C-c> "+yi
        vmap <C-x> "+c
        vmap <C-v> c<ESC>"+gP
        imap <C-v> <C-r><C-o>+
    endif
endif
" -------------------------------------------------
" vdebug - dbgp server configuration

let g:vdebug_options = {
\ 'server': '0.0.0.0',
\ 'port': '9022'
\}

