;; Roswell reads the "asd" selector before resolving the default repository name.
;; Use a unique bootstrap system so an installed upstream cl-lsp cannot win.
(:project ((:default (:parameters (("asd" "cl-lsp-bootstrap"))))))
