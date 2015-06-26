# cider.vim

Some additional IDE-like functionality for Clojure development using
[cider-nrepl](https://github.com/clojure-emacs/cider-nrepl).

## Using

Requires [fireplace.vim](https://github.com/tpope/vim-fireplace), cider-nrepl
and refactor-nrepl middlewares:

https://img.shields.io/clojars/v/clojure-emacs/cider-nrepl.svg
https://img.shields.io/clojars/v/refactor-nrepl.svg

### Leiningen

```clj
{:user {:plugins [[cider/cider-nrepl "0.9.1"]
                  [refactor-nrepl "1.0.5"]]}}
```

### Boot

```clj
(swap! boot.repl/*default-dependencies*
       concat '[[cider/cider-nrepl "0.9.1"]
                [refactor-nrepl "1.0.5"])

(swap! boot.repl/*default-middleware* conj
       'cider.nrepl/cider-middleware
       'refactor-nrepl.middleware/wrap-refactor)
```

Cider-nrepl takes care of all other dependencies so you don't need to depend
e.g. on cljfmt.

## Features

- Code formatting (uses [cljfmt](https://github.com/weavejester/cljfmt))
  - `cff` (current form), `cf{motion}`, `cF` (current file)
- Var undef / alias unmap
  - `cdd`
- Clean ns (eliminate `:use`, sort, remove unused stuff and duplication)
  - `<F4>`

## Configuration

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
- Refactor-nrepl (https://github.com/clojure-emacs/refactor-nrepl)
  - Rename symbol
  - Clean ns form
  - Resolve-missing

# License

Copyright (C) 2015 Juho Teperi

Distributed under the MIT License.
