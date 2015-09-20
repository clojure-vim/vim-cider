# cider.vim

Some additional IDE-like functionality for Clojure development on Vim using
[cider-nrepl][cider-nrepl] and
[refactor-nrepl][refactor-nrepl].

## Using

Requires [fireplace.vim][vim-fireplace], cider-nrepl
and refactor-nrepl middlewares:

**Leiningen**, `~/.lein/profiles.clj`
```clj
{:user {:plugins [[cider/cider-nrepl "0.9.1"]
                  [refactor-nrepl "1.1.0"]]}}
```

**Boot**, `~/.boot/profile.boot`
```clj
(swap! boot.repl/*default-dependencies*
       concat '[[cider/cider-nrepl "0.9.1"]
                [refactor-nrepl "1.1.0"])

(swap! boot.repl/*default-middleware* conj
       'cider.nrepl/cider-middleware
       'refactor-nrepl.middleware/wrap-refactor)
```

Cider-nrepl takes care of all other dependencies so you don't need to depend
e.g. on cljfmt.

## Features

- Code formatting (uses [cljfmt][cljfmt])
  - `cff` (current form), `cf{motion}`, `cF` (current file)
- Var undef / alias unmap
  - `cdd`
- Clean ns (eliminate `:use`, sort, remove unused stuff and duplication)
  - `<F4>`

## Configuration

If you do not like the default bindings, you can disable them and create your
own. Check the implementation file for `<Plug>` bindings.

```vim
let g:cider_no_maps=1 " Disable built-in mappings

" Setup visualmode bindings yourself, to some keys which don't interact
" with e.g. change command
autocmd FileType clojure xmap <buffer> f <Plug>CiderFormat
```

## TODO

- Cider-nrepl
  - Test utilities
  - Code reloading
  - Inspecting, tracing, debugging?
- Refactor-nrepl
  - Rename symbol
  - Resolve-missing

# License

Copyright (C) 2015 Juho Teperi

Distributed under the MIT License.

[vim-fireplace]: https://github.com/tpope/vim-fireplace
[cider-nrepl]: https://github.com/clojure-emacs/cider-nrepl
[refactor-nrepl]: https://github.com/clojure-emacs/refactor-nrepl
[cljfmt]: https://github.com/weavejester/cljfmt
