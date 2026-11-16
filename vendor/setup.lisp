;; Restrict application dependency lookup to this checkout. Roswell/ASDF itself
;; remains supplied by the Lisp installation; no global Quicklisp project is used.
(require :asdf)
(let* ((vendor (uiop:pathname-directory-pathname *load-truename*))
       (root (uiop:pathname-parent-directory-pathname vendor)))
  (setf asdf:*central-registry* nil)
  (asdf:initialize-source-registry
   `(:source-registry (:directory ,root) (:tree ,vendor) :ignore-inherited-configuration))
  (setf asdf:*system-definition-search-functions*
        (remove-if-not
         (lambda (function)
           (and (symbolp function)
                (member (symbol-name function)
                        '("SYSDEF-PACKAGE-INFERRED-SYSTEM-SEARCH"
                          "SYSDEF-CENTRAL-REGISTRY-SEARCH" "SYSDEF-SOURCE-REGISTRY-SEARCH"
                          "SYSDEF-PRELOADED-SYSTEM-SEARCH" "SYSDEF-IMMUTABLE-SYSTEM-SEARCH")
                        :test #'equal)))
         asdf:*system-definition-search-functions*))
  (asdf:load-asd (merge-pathnames "cl-lsp.asd" root)))
