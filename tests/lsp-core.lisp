;; Load with a generated runtime.lisp, then this file.
;; Exercise actual LSP handlers without opening sockets.
(in-package :cl-user)
(let ((lem-language-server::*server*
        (make-instance 'lem-language-server::mock-server))
      (lem-language-server::*debug-on-error* t))
  (labels ((request (class json)
             (lem-language-server:call-lsp-method
              (make-instance class) (lem-lsp-base/yason-utils:parse-json json))))
    (assert (gethash "capabilities"
                     (request 'lem-language-server:initialize-request
                              "{\"processId\":null,\"rootUri\":null,\"capabilities\":{}}")))
    (request 'lem-language-server:text-document-did-open-request
             "{\"textDocument\":{\"uri\":\"file:///tmp/cl-lsp-test.lisp\",\"languageId\":\"common-lisp\",\"version\":1,\"text\":\"(defun twice (x)\\n(* x 2))\\n\"}}")
    (let* ((doc (gethash "file:///tmp/cl-lsp-test.lisp"
                        lem-language-server::*text-document-table*))
           (before (lem:buffer-text (lem-language-server:text-document-buffer doc)))
           (edits (request 'lem-language-server::document-formatting-request
                           "{\"textDocument\":{\"uri\":\"file:///tmp/cl-lsp-test.lisp\"},\"options\":{\"tabSize\":2,\"insertSpaces\":true}}")))
      (assert (plusp (length edits)))
      (assert (equal before (lem:buffer-text (lem-language-server:text-document-buffer doc)))))
    (request 'lem-language-server:text-document-did-change-request
             "{\"textDocument\":{\"uri\":\"file:///tmp/cl-lsp-test.lisp\",\"version\":2},\"contentChanges\":[{\"text\":\"(+ 1 2)\"}]}")
    (assert (equal "(+ 1 2)"
                   (lem:buffer-text
                    (lem-language-server:text-document-buffer
                     (gethash "file:///tmp/cl-lsp-test.lisp" lem-language-server::*text-document-table*)))))
    (request 'lem-language-server:text-document-did-close-request
             "{\"textDocument\":{\"uri\":\"file:///tmp/cl-lsp-test.lisp\"}}")
    (assert (null (gethash "file:///tmp/cl-lsp-test.lisp" lem-language-server::*text-document-table*)))
    (request 'lem-language-server:shutdown-request "{}")
    (request 'lem-language-server:exit-request "{}")
    (assert (eql 0 (lem-language-server:mock-server-exit-status
                    lem-language-server::*server*)))))
(write-line "LSP initialize, open, formatting, change, close, shutdown and exit handlers passed.")
