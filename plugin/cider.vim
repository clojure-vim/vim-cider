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

function! s:paste(text) abort
  " Does charwise paste to current '[ and '] marks
  let @@ = a:text
  let reg_type = getregtype('@@')
  call setreg('@@', getreg('@@'), 'v')
  silent exe "normal! `[v`]p"
  call setreg('@@', getreg('@@'), reg_type)"
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
    let opts = { 'op': 'clean-ns', 'path': p }
    call extend(opts, get(g:, 'refactor_nrepl_options', {}))

    let res = fireplace#message(opts)[0]
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

  " TODO: Investigate using something prettier? Check how CtrlP is
  " implemented.
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

function! s:kwpairs_to_dict(x) abort
  let m = {}
  for i in range(0, len(a:x) - 2, 2)
    let m[a:x[i]] = a:x[i + 1]
  endfor
  return m
endfunction

" echom scriptease#dump(s:kwpairs_to_dict(['a', 5]))
" echom scriptease#dump(s:kwpairs_to_dict(['a', 5, 'b', 3]))

function! s:find_symbol() abort
  let sym = expand('<cword>')
  let meta = fireplace#info(sym)
  " echom scriptease#dump(meta)
  let [bufnum, lnum, col, off] = getpos('.')
  let filepath = expand('%:p')
  let res = fireplace#message({'op': 'find-symbol', 'dir': '.', 'file': filepath, 'ns': meta.ns, 'name': meta.name, 'line': lnum, 'column': col, 'serialization-format': 'bencode'})

  call filter(res, 'has_key(v:val, "occurrence")')
  call map(res, 's:kwpairs_to_dict(v:val.occurrence)')
  call map(res, 'v:val["file"] . ":" . v:val["line-beg"] . ":" . v:val["col-beg"] . ":" . v:val["match"]')

  " TODO: Investigate using something more like CtrlP

  cgetexpr res
  copen
endfunction

nnoremap <silent> <Plug>RefactorFindSymbol :<C-U>call <SID>find_symbol()<CR>

function! s:set_up() abort
  if get(g:, 'cider_no_maps') | return | endif

  nmap <buffer> =f <Plug>CiderFormat
  nmap <buffer> =ff <Plug>CiderCountFormat
  nmap <buffer> =F gg=fG

  nmap <buffer> cdd <Plug>CiderUndef
  nmap <buffer> <F4> <Plug>RefactorCleanNs
  " FIXME: Find better binding
  nmap <buffer> cRR <Plug>RefactorResolveMissing
  nmap <buffer> <F5> <Plug>RefactorFindSymbol
endfunction

augroup cider_eval
  autocmd!
  autocmd FileType clojure call s:set_up()
augroup END
