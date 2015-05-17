# cider.vim

Requires [fireplace.vim](https://github.com/tpope/vim-fireplace) and cider-nrepl middleware:
```clj
{:user {:plugins [[cider/cider-nrepl "0.9.0-SNAPSHOT"]]}}
```

Cider-nrepl takes care of all other dependencies so you don't need to depend e.g. on cljfmt.

Some additional IDE-like functionality for Clojure development using
[cider-nrepl](https://github.com/clojure-emacs/cider-nrepl).

## Features

- Code formatting (uses [cljfmt](https://github.com/weavejester/cljfmt))
  - `cff` (current form), `cf{motion}`, `cF` (current file)

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
  - Undefine var
  - Inspecting, tracing, debugging?
- Refactor-nrepl (https://github.com/clojure-emacs/refactor-nrepl)
  - Rename symbol
  - Clean ns form
  - Resolve-missing

# License

Copyright (C) 2015 Juho Teperi

Distributed under the MIT License.
