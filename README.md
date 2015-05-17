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

## TODO

- Test utilities
- Code reloading
- Undefine var
- Inspecting, tracing, debugging?

# License

Copyright (C) 2015 Juho Teperi

Distributed under the MIT License.
