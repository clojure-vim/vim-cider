" cider.vim
" Maintainer:   Juho Teperi

if exists("g:loaded_cider") || v:version < 700 || &cp
  finish
endif
let g:loaded_cider = 1

"
" Utils
"

function! s:save_regs(fn, ...)
  let reg_save = @@
  let sel_save = &selection
  let cb_save = &clipboard
  try
    set selection=inclusive clipboard-=unnamed clipboard-=unnamedplus
    call call(a:fn, a:000)
  catch /^Clojure:/
    return ''
  finally
    let @@ = reg_save
    let &selection = sel_save
    let &clipboard = cb_save
  endtry
endfunction

"
" Format operation
"

function! s:formatop_impl(type) abort
  let expr = fireplace#opfunc(a:type)
  " Remove additional newlines from start of expression
  let res = fireplace#message({'op': 'format-code', 'code': substitute(expr, '^\n\+', '', '')})
  " Remove additional spaces from start of the first line as code is
  " already indented?
  let formatted = substitute(get(get(res, 0), 'formatted-code'), '^ \+', '', '')
  let @@ = formatted
  if @@ !~# '^\n*$'
    normal! gvp
  endif
endfunction

function! s:formatop(type) abort
  call s:save_regs(function('s:formatop_impl'), a:type)
endfunction

nnoremap <silent> <Plug>CiderFormat :<C-U>set opfunc=<SID>formatop<CR>g@
xnoremap <silent> <Plug>CiderFormat :<C-U>call <SID>formatop(visualmode())<CR>
nnoremap <silent> <Plug>CiderCountFormat :<C-U>call <SID>formatop(v:count)<CR>

"
" Undef
"

function! s:undef() abort
  let ns = fireplace#ns()
  let s = expand('<cword>')
  let res = fireplace#message({'op': 'undef', 'ns': ns, 'symbol': s})
  echo 'Undef ' . ns . '/' . s
endfunction

nnoremap <silent> <Plug>CiderUndef :<C-U>call <SID>undef()<CR>

"
" CleanNs
"

function! s:init_refactor_nrepl() abort
  if exists('g:refactor_nrepl_options')
    let client = g:fireplace_post_connect_session
    call client.message({'op': 'configure', 'opts': g:refactor_nrepl_options}, client)
  endif
endfunction

function! s:clean_ns() abort
  " FIXME: Moves cursor

  let p = expand('%:p')
  normal! ggw

  let [line1, col1] = searchpairpos('(', '', ')', 'bc')
  let [line2, col2] = searchpairpos('(', '', ')', 'n')

  while col1 > 1 && getline(line1)[col1-2] =~# '[#''`~@]'
    let col1 -= 1
  endwhile
  call setpos("'[", [0, line1, col1, 0])
  call setpos("']", [0, line2, col2, 0])

  if expand('<cword>') ==? 'ns'
    let res = fireplace#message({'op': 'clean-ns', 'path': p})
    let @@ = get(res[0], 'ns')
    " FIXME: Adds unuecessary line before and after
    silent exe "normal! `[v`]p"
    " FIXME: Simplify?
    silent exe "normal! `[v`]=="
  endif
endfunction

nnoremap <silent> <Plug>RefactorCleanNs :<C-U>call <SID>clean_ns()<CR>

function! s:set_up() abort
  if get(g:, 'cider_no_maps') | return | endif

  nmap <buffer> cf <Plug>CiderFormat
  nmap <buffer> cff <Plug>CiderCountFormat
  nmap <buffer> cF ggcfG

  nmap <buffer> cdd <Plug>CiderUndef

  nmap <buffer> <F4> <Plug>RefactorCleanNs
endfunction

augroup cider_eval
  autocmd!
  autocmd FileType clojure call s:set_up()
augroup END

augroup refactor_nrepl_configure
  autocmd User FireplacePostConnect call s:init_refactor_nrepl()
augroup END
