(require :asdf)
(defpackage :cl-lsp/installer
  (:use :cl)
  (:export :command :install :select-openssl :compatible-p :tls-source :run-ros))
(in-package :cl-lsp/installer)

(defparameter *root*
  (uiop:pathname-parent-directory-pathname
   (uiop:pathname-directory-pathname *load-truename*)))

(defparameter *manifest*
  "git micros https://github.com/lem-project/micros.git
git lem-mailbox https://github.com/lem-project/lem-mailbox.git
git async-process https://github.com/lem-project/async-process.git
git jsonrpc https://github.com/cxxxr/jsonrpc.git
git lem-extension-manager https://github.com/lem-project/lem-extension-manager.git
")

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

(defun compatible-p (directory)
  ;; Each pair is loaded in its own SBCL process, so different OpenSSL
  ;; versions cannot satisfy each other's missing symbols.
  (when (every (lambda (name) (probe-file (merge-pathnames name directory)))
               '("libcrypto.dylib" "libssl.dylib"))
    (multiple-value-bind (output errors status)
        (run-ros
         (list "-e"
               (format nil "(progn (sb-alien:load-shared-object ~S) (sb-alien:load-shared-object ~S)~
                 (dolist (name '(~{~S~^ ~})) (assert (sb-sys:find-foreign-symbol-address name)))~
                 (write-line ~S))"
                       (namestring (truename (merge-pathnames "libcrypto.dylib" directory)))
                       (namestring (truename (merge-pathnames "libssl.dylib" directory)))
                       '("ASN1_STRING_data" "ASN1_STRING_length" "ASN1_STRING_new"
                         "ASN1_STRING_free" "SSL_new" "TLS_method") "TLS_PAIR_OK") "-q")
         :capture t :ignore-error t)
      (declare (ignore errors))
      (and (zerop status) (search "TLS_PAIR_OK" output)))))

(defun select-openssl (&optional (roots '(#P"/opt/homebrew/opt/" #P"/usr/local/opt/")))
  (dolist (root roots)
    (when (probe-file root)
      ;; DIRECTORY follows Homebrew symlinks; retain the candidate paths when
      ;; probing and use real file paths when writing the configuration.
      (let ((candidates (directory (merge-pathnames "openssl*/lib/libcrypto.dylib" root))))
        (dolist (file candidates)
          (let ((directory (uiop:pathname-directory-pathname file)))
            (when (compatible-p directory)
              (return-from select-openssl directory)))))))
  (error "No installed Homebrew OpenSSL pair provides the CL+SSL APIs, including ASN1_STRING_data."))

(defun tls-source (directory)
  (format nil "(let ((*standard-output* *error-output*) (*trace-output* *error-output*))
  (ql:quickload \"cl+ssl/config\" :silent t))
(cl+ssl/config:define-libcrypto-path ~S)
(cl+ssl/config:define-libssl-path ~S)
(let ((*standard-output* *error-output*) (*trace-output* *error-output*))
  ;; Resolve dependencies without loading CL+SSL twice. A second forced load
  ;; can turn SBCL's CL+SSL package-variance warning into a compile failure.
  (labels ((ensure-dependency (dependency)
             (etypecase dependency
               ((or string symbol) (ql:quickload dependency :silent t))
               (cons
                (case (first dependency)
                  (:feature (when (uiop:featurep (second dependency))
                              (ensure-dependency (third dependency))))
                  (:version (ensure-dependency (second dependency)))
                  (:require (require (second dependency)))
                  (otherwise (error \"Unsupported dependency: ~~S\" dependency)))))))
    (mapc #'ensure-dependency (asdf:system-depends-on (asdf:find-system \"cl+ssl\")))))
(let ((*standard-output* *error-output*) (*trace-output* *error-output*))
  (asdf:load-system \"cl+ssl\" :force t))
(let ((value (cffi:foreign-funcall \"ASN1_STRING_new\" :pointer)))
  (assert (not (cffi:null-pointer-p value)))
  (unwind-protect
       (cffi:foreign-funcall \"ASN1_STRING_data\" :pointer value :pointer)
    (cffi:foreign-funcall \"ASN1_STRING_free\" :pointer value :void)))~%"
          (namestring (truename (merge-pathnames "libcrypto.dylib" directory)))
          (namestring (truename (merge-pathnames "libssl.dylib" directory)))))

(defun shell-quote (text)
  (with-output-to-string (out)
    (write-char #\' out)
    (loop for char across text do
      (if (char= char #\') (write-string "'\"'\"'" out) (write-char char out)))
    (write-char #\' out)))

(defun install (destination &key tls-only)
  (let* ((prefix (uiop:ensure-directory-pathname (merge-pathnames destination)))
         (cache (namestring (merge-pathnames "cache/" prefix)))
         (old-cache (uiop:getenv "XDG_CACHE_HOME"))
         (old-registry (uiop:getenv "CL_SOURCE_REGISTRY")))
    (when (probe-file prefix) (error "Installation prefix already exists: ~A" prefix))
    (ensure-directories-exist prefix)
    (unwind-protect
         (progn
           (setf (uiop:getenv "XDG_CACHE_HOME") cache)
           (let* ((tls (write-new (merge-pathnames "configure-tls.lisp" prefix)
                                 #+darwin (tls-source (select-openssl))
                                 #-darwin "; Use platform CL+SSL defaults."))
                  (tls-args (list "-l" (namestring tls)))
                  (lem (merge-pathnames "lem/" prefix))
                  (qlot (merge-pathnames "qlot/" prefix))
                  (setup (merge-pathnames ".qlot/setup.lisp" prefix)))
             (run-ros (append tls-args '("-e" "(write-line \"CL_LSP_TLS_READY\")" "-q")))
             (when tls-only (return-from install prefix))
             (run (list "git" "clone" "--depth" "1" "https://github.com/lem-project/lem.git" (namestring lem)))
             (run (list "git" "clone" "--depth" "1" "https://github.com/fukamachi/qlot.git" (namestring qlot)))
             (write-new (merge-pathnames "qlfile" prefix) *manifest*)
             (run-ros
              (append tls-args
                      (list "-e" (format nil "(asdf:initialize-source-registry '(:source-registry (:tree ~S) :inherit-configuration))" (namestring qlot))
                            "-e" "(ql:quickload \"qlot/cli\" :silent t)"
                            "-e" "(qlot/cli:qlot-command \"install\" \"--no-deps\")" "-q"))
              :directory prefix)
             (let* ((registry (format nil "(:source-registry (:tree ~S) (:tree ~S) (:directory ~S) :inherit-configuration)"
                                      (namestring lem) (namestring (merge-pathnames ".qlot/" prefix)) (namestring *root*)))
                    (source-file (merge-pathnames "async-source.txt" prefix)))
               (setf (uiop:getenv "CL_SOURCE_REGISTRY") registry)
               (run-ros
                (append (list "-l" (namestring setup)) tls-args
                        (list "-e" (format nil "(with-open-file (out ~S :direction :output :if-exists :error) (write-string (namestring (asdf:system-source-directory \"async-process\")) out))" (namestring source-file)) "-q")))
               (let* ((source (truename (uiop:read-file-string source-file)))
                      (native (uiop:pathname-parent-directory-pathname source))
                      (runtime (merge-pathnames "runtime.lisp" prefix))
                      (entry (merge-pathnames "entry.ros" prefix))
                      (launcher (merge-pathnames "cl-lsp" prefix)))
                 (unless (uiop:subpathp source (truename prefix))
                   (error "async-process resolved outside the installation prefix: ~A" source))
                 (run (list "make" "-C" (namestring native)))
                 (write-new runtime
                  (format nil "(let ((*standard-output* *error-output*) (*trace-output* *error-output*)) (load ~S))
(load ~S)
(let ((*standard-output* *error-output*) (*trace-output* *error-output*)) (ql:quickload \"cffi\" :silent t))
(let ((*standard-output* *error-output*) (*trace-output* *error-output*))
  (pushnew ~S cffi:*foreign-library-directories* :test #'equal)
  (ql:quickload \"cl-lsp\" :silent t))~%"
                          (namestring setup) (namestring tls) (merge-pathnames ".libs/" native)))
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
                 (format t "Launcher: ~A~%" launcher)))))
      (setf (uiop:getenv "XDG_CACHE_HOME") (or old-cache "")
            (uiop:getenv "CL_SOURCE_REGISTRY") (or old-registry "")))))

(defun command (args)
  (when (member "--help" args :test #'equal)
    (format t "Usage: ros scripts/install-headless.ros --prefix NEW-DIRECTORY [--tls-only]~%")
    (return-from command))
  (let ((prefix nil) (tls-only nil))
    (loop while args for arg = (pop args) do
      (cond ((equal arg "--prefix") (setf prefix (or (pop args) (error "Missing prefix."))))
            ((equal arg "--tls-only") (setf tls-only t))
            (t (error "Unknown argument: ~A" arg))))
    (unless prefix (error "--prefix is required."))
    (install prefix :tls-only tls-only)))
