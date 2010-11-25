let g:clj_want_gorilla = 1
let vimclojure#NailgunClient =
  \ eclim#client#nailgun#GetNgCommand() .
  \ ' --nailgun-port ' . eclim#client#nailgun#GetNgPort()
