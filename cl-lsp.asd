;; Roswell loads the system before invoking its build hook. Defer the server
;; dependencies until the hook has installed them in their own environment.
#+ros.installing
(let ((root (uiop:pathname-directory-pathname *load-truename*)))
  (load (merge-pathnames "scripts/installer.lisp" root))
  (setf (symbol-value (find-symbol "*BUILD-HOOK*" "ROSWELL.INSTALL"))
        (lambda () (uiop:symbol-call :cl-lsp/installer :install-for-roswell))))

(defsystem "cl-lsp"
  :depends-on (#-ros.installing "lem-language-server/cli")
  :components (#-ros.installing (:file "main"))
  :in-order-to ((test-op (test-op "cl-lsp/test"))))

(defsystem "cl-lsp/executable"
  :build-operation program-op
  :build-pathname "cl-lsp"
  :entry-point "cl-lsp/main:main"
  :depends-on ("cl-lsp"))

#+sb-core-compression
(defmethod asdf:perform ((o asdf:image-op) (c asdf:system))
  (uiop:dump-image (asdf:output-file o c) :executable t :compression t))
