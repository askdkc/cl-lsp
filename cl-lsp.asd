(defsystem "cl-lsp"
  :depends-on ("cl-lsp/cli")
  :components ((:file "main"))
  :in-order-to ((test-op (test-op "cl-lsp/test"))))

(defsystem "cl-lsp/executable"
  :build-operation program-op
  :build-pathname "cl-lsp"
  :entry-point "cl-lsp/main:main"
  :depends-on ("cl-lsp"))

#+sb-core-compression
(defmethod asdf:perform ((o asdf:image-op) (c asdf:system))
  (uiop:dump-image (asdf:output-file o c) :executable t :compression t))
;; Headless Lem systems; upstream MIT license: vendor/lem/LICENCE.

(DEFSYSTEM "cl-lsp/lem-core"
  :VERSION
  "2.3.0"
  :DEPENDS-ON
  ("iterate" "closer-mop" "trivia" "alexandria" "trivial-gray-streams"
   "trivial-types" "cl-ppcre" "cl-unicode" "micros" "inquisitor" "babel"
   "bordeaux-threads" "yason" "log4cl" "split-sequence" "str"
   SB-CONCURRENCY "lem-mailbox" "sb-sprof")
  :PATHNAME
  "vendor/lem/src/"
  :SERIAL
  T
  :COMPONENTS
  ((:MODULE "common" :COMPONENTS
    ((:FILE "ring") (:FILE "killring") (:FILE "history") (:FILE "timer")
     (:FILE "command") (:FILE "color") (:FILE "queue") (:FILE "hooks")
     (:FILE "var") (:FILE "socket") (:FILE "utils")
     (:MODULE "character" :SERIAL T :COMPONENTS
      ((:FILE "icon") (:FILE "eastasian") (:FILE "string-width-utils")
       (:FILE "package")))))
   (:MODULE "buffer" :SERIAL T :COMPONENTS
    ((:FILE "errors") (:FILE "file-utils") (:FILE "line")
     (:FILE "buffer-list-manager") (:FILE "syntax-table") (:FILE "interrupt")
     (:FILE "package")
     (:MODULE "internal" :SERIAL T :COMPONENTS
      ((:FILE "var") (:FILE "editor-variables") (:FILE "buffer")
       (:FILE "point") (:FILE "edit") (:FILE "mark") (:FILE "undo")
       (:FILE "buffer-insert") (:FILE "basic") (:FILE "syntax-predicates")
       (:FILE "search") (:FILE "parse-partial-sexp") (:FILE "syntax-scan")
       (:FILE "syntax-parser") (:FILE "tmlanguage")
       (:FILE "check-corruption")))
     (:FILE "encodings") (:FILE "file") (:FILE "indent")))
   (:FILE "internal-packages") (:FILE "system-utils") (:FILE "version")
   (:FILE "config") (:FILE "errors") (:FILE "system") (:FILE "key")
   (:FILE "macros") (:FILE "attribute") (:FILE "clipboard")
   (:FILE "save-excursion") (:FILE "killring") (:FILE "named-point")
   (:FILE "file") (:FILE "frame") (:FILE "echo") (:FILE "prompt")
   (:FILE "format")
   (:MODULE "window" :SERIAL T :COMPONENTS
    ((:FILE "window-tree") (:FILE "window") (:FILE "virtual-line")
     (:FILE "floating-window") (:FILE "header-window") (:FILE "side-window")
     (:FILE "attached-window")))
   (:FILE "buffer-ext") (:FILE "popup") (:FILE "modeline") (:FILE "command")
   (:FILE "mode") (:FILE "keymap") (:FILE "defcommand")
   (:FILE "fundamental-mode") (:FILE "region") (:FILE "event-queue")
   (:FILE "interp") (:FILE "mouse") (:FILE "context-menu") (:FILE "input")
   (:FILE "overlay") (:FILE "streams") (:FILE "completion") (:FILE "typeout")
   (:FILE "cursors") (:FILE "command-advices") (:FILE "interface")
   (:FILE "highlight-line") (:FILE "syntax-scanner") (:FILE "html-buffer")
   (:FILE "site-init") (:FILE "command-line-arguments") (:FILE "tabbar-config")
   (:FILE "lem") (:FILE "color-theme")
   (:MODULE "display" :SERIAL T :COMPONENTS
    ((:FILE "base") (:FILE "char-type") (:FILE "logical-line")
     (:FILE "physical-line")))
   (:MODULE "commands" :SERIAL T :COMPONENTS
    ((:FILE "move") (:FILE "edit" :DEPENDS-ON ("move")) (:FILE "mark")
     (:FILE "word" :DEPENDS-ON ("edit"))
     (:FILE "s-expression" :DEPENDS-ON ("edit"))
     (:FILE "file" :DEPENDS-ON ("edit")) (:FILE "project" :DEPENDS-ON ("file"))
     (:FILE "buffer") (:FILE "window" :DEPENDS-ON ("move"))
     (:FILE "multiple-cursors") (:FILE "process") (:FILE "help") (:FILE "font")
     (:FILE "other" :DEPENDS-ON ("file")) (:FILE "frame") (:FILE "sprof")))
   (:FILE "external-packages")))
(DEFSYSTEM "cl-lsp/lisp-syntax"
  :PATHNAME
  "vendor/lem/extensions/lisp-syntax/"
  :DEPENDS-ON
  ("cl-lsp/lem-core" "cl-ppcre" "micros" "trivia")
  :SERIAL
  T
  :COMPONENTS
  ((:FILE "indent") (:FILE "syntax-table") (:FILE "misc") (:FILE "enclosing")
   (:FILE "parse-for-autodoc") (:FILE "defstruct-to-defclass")
   (:FILE "lem-lisp-syntax")))
(DEFSYSTEM "cl-lsp/lsp-base"
  :PATHNAME
  "vendor/lem/extensions/lsp-base/"
  :DEPENDS-ON
  ("cl-lsp/lem-core" "cl-change-case" "bordeaux-threads" "jsonrpc"
   "trivia.level2" "quri")
  :SERIAL
  T
  :COMPONENTS
  ((:FILE "yason-utils") (:FILE "type") (:FILE "protocol-generator")
   (:FILE "protocol-3-17") (:FILE "converter") (:FILE "utils")))
(DEFSYSTEM "cl-lsp/language-server"
  :PATHNAME
  "vendor/lem/extensions/language-server/"
  :DEPENDS-ON
  ("alexandria" "jsonrpc" "usocket" "log4cl" "quri" "cl-change-case"
   "async-process" "micros" "cl-lsp/lem-core" "cl-lsp/lisp-syntax"
   "cl-lsp/lsp-base")
  :SERIAL
  T
  :COMPONENTS
  ((:FILE "micros-client") (:FILE "package") (:FILE "config")
   (:FILE "editor-utils") (:FILE "method") (:FILE "server")
   (:FILE "text-document") (:FILE "eval") (:FILE "commands")
   (:MODULE "controller" :COMPONENTS
    ((:FILE "lifecycle") (:FILE "document-synchronization")
     (:FILE "language-features") (:FILE "workspace") (:FILE "window")
     (:FILE "commands")))))
(DEFSYSTEM "cl-lsp/cli"
  :PATHNAME
  "vendor/lem/extensions/language-server/"
  :DEPENDS-ON
  ("cl-lsp/language-server" "command-line-arguments")
  :SERIAL
  T
  :COMPONENTS
  ((:FILE "cli")))
