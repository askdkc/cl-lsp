;; This system intentionally has no Lem or server dependencies.
(defsystem "cl-lsp-bootstrap")

#+ros.installing
(let ((root (uiop:pathname-directory-pathname *load-truename*)))
  (load (merge-pathnames "scripts/installer.lisp" root))
  (setf (symbol-value (find-symbol "*BUILD-HOOK*" "ROSWELL.INSTALL"))
        (lambda () (uiop:symbol-call :cl-lsp/installer :install-for-roswell))))
