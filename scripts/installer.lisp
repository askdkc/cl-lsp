(require :asdf)
(defpackage :cl-lsp/installer
  (:use :cl)
  (:export :command :install :install-for-roswell :run-ros))
(in-package :cl-lsp/installer)

(defparameter *root*
  (uiop:pathname-parent-directory-pathname
   (uiop:pathname-directory-pathname *load-truename*)))

(defun write-new (file text)
  (with-open-file (out file :direction :output :if-exists :error)
    (write-string text out))
  file)

(defun run (arguments &key directory capture ignore-error)
  (format *error-output* "~&Running: ~S~%" arguments)
  (uiop:run-program arguments :directory directory
                    :output (if capture :string *standard-output*)
                    :error-output *error-output* :ignore-error-status ignore-error))

(defun run-ros (arguments &key directory capture ignore-error)
  (run (append '("ros" "-Q" "-e" "(ros:ensure-asdf)"
                 "-e" "#+sbcl (sb-ext:disable-debugger)") arguments)
       :directory directory :capture capture :ignore-error ignore-error))

(defun shell-quote (text)
  (with-output-to-string (out)
    (write-char #\' out)
    (loop for char across text do
      (if (char= char #\') (write-string "'\"'\"'" out) (write-char char out)))
    (write-char #\' out)))

(defun install (destination)
  (let* ((prefix (uiop:ensure-directory-pathname (merge-pathnames destination)))
         (cache (namestring (merge-pathnames "cache/" prefix)))
         (old-cache (uiop:getenv "XDG_CACHE_HOME"))
         (old-registry (uiop:getenv "CL_SOURCE_REGISTRY"))
         (registry (format nil "(:source-registry (:directory ~S) (:tree ~S) :ignore-inherited-configuration)"
                           (namestring *root*) (namestring (merge-pathnames "vendor/" *root*)))))
    (when (probe-file prefix) (error "Installation prefix already exists: ~A" prefix))
    (ensure-directories-exist prefix)
    (unwind-protect
         (progn
           (setf (uiop:getenv "XDG_CACHE_HOME") cache
                 (uiop:getenv "CL_SOURCE_REGISTRY") registry)
           (let* ((native (merge-pathnames "native/" prefix))
                  (runtime (merge-pathnames "runtime.lisp" prefix))
                  (entry (merge-pathnames "entry.ros" prefix))
                  (launcher (merge-pathnames "cl-lsp" prefix)))
             (ensure-directories-exist native)
             ;; This small POSIX library needs only the system C compiler.
             ;; Build outside vendor so reinstallations never modify sources.
             (let ((sources (directory (merge-pathnames "vendor/quicklisp/async-process-*/src/async-process.c" *root*))))
               (unless (= 1 (length sources)) (error "Expected one bundled async-process source."))
               (run (list "cc" #+darwin "-dynamiclib" #-darwin "-shared" "-fPIC" "-O2"
                          "-o" (namestring (merge-pathnames #+darwin "libasyncprocess.dylib"
                                                          #-darwin "libasyncprocess.so" native))
                          (namestring (first sources)))))
             (write-new runtime
                        (format nil "(let ((*standard-output* *error-output*) (*trace-output* *error-output*)) (load ~S))
(let ((*standard-output* *error-output*) (*trace-output* *error-output*))
  (asdf:load-system \"cffi\"))
(let ((*standard-output* *error-output*) (*trace-output* *error-output*))
  (pushnew ~S cffi:*foreign-library-directories* :test #'equal)
  (asdf:load-system \"cl-lsp\")
  (asdf:load-system \"swank\")
  (asdf:load-system \"micros\"))~%"
                                (namestring (merge-pathnames "vendor/setup.lisp" *root*)) native))
             (run-ros (list "-l" (namestring runtime) "-e" "(cl-lsp:main (list \"--help\"))" "-q"))
             (write-new entry "(defpackage :cl-lsp/launcher (:use :cl))
(in-package :cl-lsp/launcher)
(defun main (&rest args) (cl-lsp:main args))
")
             (write-new launcher
                        (format nil "#!/bin/sh~%export XDG_CACHE_HOME=~A~%export CL_SOURCE_REGISTRY=~A~%exec ros -Q -e '(ros:ensure-asdf)' -e '(sb-ext:disable-debugger)' -l ~A -- ~A \"$@\"~%"
                                (shell-quote cache) (shell-quote registry)
                                (shell-quote (namestring runtime)) (shell-quote (namestring entry))))
             (run (list "chmod" "755" (namestring launcher)))
             (format t "Launcher: ~A~%" launcher)))
      (setf (uiop:getenv "XDG_CACHE_HOME") (or old-cache "")
            (uiop:getenv "CL_SOURCE_REGISTRY") (or old-registry "")))))

(defun install-for-roswell ()
  ;; Keep failed attempts for diagnosis and retain the previous working pointer
  ;; until the new runtime has passed its load check.
  (let* ((prefix (loop for name = (format nil ".cl-lsp/install-~D-~D/"
                                         (get-universal-time) (random 1000000000))
                       for path = (merge-pathnames name *root*)
                       unless (probe-file path) return path))
         (bin (merge-pathnames "bin/" (uiop:symbol-call :roswell.util :checkoutdir)))
         (pointer (merge-pathnames "cl-lsp-runtime.sexp" bin))
         (temporary (merge-pathnames (format nil "cl-lsp-runtime-~D.tmp" (random 1000000000)) bin)))
    (install prefix)
    (unless (probe-file (merge-pathnames "cl-lsp" prefix))
      (error "Installation did not produce a CL-LSP launcher: ~A" prefix))
    (ensure-directories-exist bin)
    (unwind-protect
         (progn
           (write-new temporary
                      (format nil "~S~%" (namestring (merge-pathnames "cl-lsp" prefix))))
           (uiop:rename-file-overwriting-target temporary pointer))
      (when (probe-file temporary) (delete-file temporary)))))

(defun command (args)
  (when (member "--help" args :test #'equal)
    (format t "Usage: ros scripts/install-headless.ros --prefix NEW-DIRECTORY~%")
    (return-from command))
  (let ((prefix nil))
    (loop while args for arg = (pop args) do
      (cond ((equal arg "--prefix") (setf prefix (or (pop args) (error "Missing prefix."))))
            (t (error "Unknown argument: ~A" arg))))
    (unless prefix (error "--prefix is required."))
    (install prefix)))
