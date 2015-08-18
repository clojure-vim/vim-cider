" cider.vim
" Maintainer:   Juho Teperi

if exists("g:loaded_cider") || v:version < 700 || &cp
  finish
endif
let g:loaded_cider = 1

" FIXME: From fireplace
function! s:opfunc(type) abort
  let sel_save = &selection
  let cb_save = &clipboard
  let reg_save = @@
  try
    set selection=inclusive clipboard-=unnamed clipboard-=unnamedplus
    if type(a:type) == type(0)
      let open = '[[{(]'
      let close = '[]})]'
      if getline('.')[col('.')-1] =~# close
        let [line1, col1] = searchpairpos(open, '', close, 'bn', g:fireplace#skip)
        let [line2, col2] = [line('.'), col('.')]
      else
        let [line1, col1] = searchpairpos(open, '', close, 'bcn', g:fireplace#skip)
        let [line2, col2] = searchpairpos(open, '', close, 'n', g:fireplace#skip)
      endif
      while col1 > 1 && getline(line1)[col1-2] =~# '[#''`~@]'
        let col1 -= 1
      endwhile
      call setpos("'[", [0, line1, col1, 0])
      call setpos("']", [0, line2, col2, 0])
      silent exe "normal! `[v`]y"
    elseif a:type =~# '^.$'
      silent exe "normal! `<" . a:type . "`>y"
    elseif a:type ==# 'line'
      silent exe "normal! '[V']y"
    elseif a:type ==# 'block'
      silent exe "normal! `[\<C-V>`]y"
    elseif a:type ==# 'outer'
      call searchpair('(','',')', 'Wbcr', g:fireplace#skip)
      silent exe "normal! vaby"
    else
      silent exe "normal! `[v`]y"
    endif
    redraw
    return repeat("\n", line("'<")-1) . repeat(" ", col("'<")-1) . @@
  finally
    let @@ = reg_save
    let &selection = sel_save
    let &clipboard = cb_save
  endtry
endfunction

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
  let expr = s:opfunc(a:type)
  let res = fireplace#message({'op': 'format-code', 'code': expr})[0]
  " Code is aligned to start in same position as in the original file
  let formatted = substitute(get(res, 'formatted-code'), '^[\n ]\+', '', '')
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
  let res = fireplace#message({'op': 'undef', 'ns': ns, 'symbol': s})[0]
  let error = get(res, 'err')
  if !empty(error)
    throw error
  else
    echo 'Undefined ' . s
  endif
endfunction

nnoremap <silent> <Plug>CiderUndef :<C-U>call <SID>undef()<CR>

"
" CleanNs
"

function! s:init_refactor_nrepl() abort
  if !exists('b:refactor_nrepl_loaded') && exists('g:refactor_nrepl_options')
    let b:refactor_nrepl_loaded = 1
    call fireplace#message({'op': 'configure', 'opts': g:refactor_nrepl_options})
  endif
endfunction

function! s:paste(text) abort
  " Does charwise paste to current '[ and '] marks
  let @@ = a:text
  let reg_type = getregtype('@@')
  call setreg('@@', getreg('@@'), 'v')
  silent exe "normal! `[v`]p"
  call setreg('@@', getreg('@@'), reg_type)"
endfunction

function! s:clean_ns() abort
  call s:init_refactor_nrepl()

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
    let res = fireplace#message({'op': 'clean-ns', 'path': p})[0]
    let error = get(res, 'error')
    if !empty(error)
      throw error
    elseif type(res.ns) == type("")
      call s:paste(substitute(res.ns, '\n$', '', ''))
      silent exe "normal! `[v`]=="
      echo "Ns form cleaned"
    else
      echo "Ns form already clean"
    endif
  endif
endfunction

nnoremap <silent> <Plug>RefactorCleanNs :<C-U>call <SID>clean_ns()<CR>

function! s:split_symbol(sym) abort
  if a:sym =~ '\/'
    return split(a:sym, '\/')
  elseif a:sym =~ '\.'
    let parts = split(a:sym, '\.')
    return [join(parts[0:-1], '.'), parts[-1]]
  else
    return [0, a:sym]
  endif
endfunction

" echom scriptease#dump(s:split_symbol('java.util.Date'))
" echom scriptease#dump(s:split_symbol('Date'))
" echom scriptease#dump(s:split_symbol('clojure.string/split'))
" echom scriptease#dump(s:split_symbol('str/split'))

function! s:resolve_missing() abort
  " TODO: Check indices

  call s:init_refactor_nrepl()

  let [alias, sym] = s:split_symbol(expand('<cword>'))
  let res = fireplace#message({'op': 'resolve-missing', 'symbol': sym})
  let choices = fireplace#evalparse('(quote ' . res[0].candidates . ')')

  call inputsave()
  let x = inputlist(["Select: "] + map(copy(choices), '(v:key+ 1) . ". " . v:val[0]'))
  call inputrestore()
  let @@ = "[" . choices[x - 1][0] . " :as " . alias . "]"

  " Insert as last entry in :require list
  normal gg
  if search('(:require', 'W') !=# 0
    execute "normal! %i\<CR>\<esc>p"
  endif
endfunction

nnoremap <silent> <Plug>RefactorResolveMissing :<C-U>call <SID>resolve_missing()<CR>

function! s:set_up() abort
  if get(g:, 'cider_no_maps') | return | endif

  nmap <buffer> cf <Plug>CiderFormat
  nmap <buffer> cff <Plug>CiderCountFormat
  nmap <buffer> cF ggcfG

  nmap <buffer> cdd <Plug>CiderUndef
  nmap <buffer> <F4> <Plug>RefactorCleanNs
  " FIXME: Find better binding
  nmap <buffer> cRR <Plug>RefactorResolveMissing
endfunction

augroup cider_eval
  autocmd!
  autocmd FileType clojure call s:set_up()
augroup END
