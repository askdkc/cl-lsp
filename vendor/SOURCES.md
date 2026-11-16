# Bundled dependency sources

These are source snapshots shipped with this fork, not an installer download
manifest. Installation performs no dependency clones or Quicklisp downloads.
Roswell, SBCL and the C compiler remain external prerequisites.

Each project's copyright and license notices remain in its own directory or
source headers. These dependencies retain their original licenses; the fork's
license does not replace them. In particular, Trivia and its related libraries
include LLGPL-licensed code.

| Directory | Upstream | Source identity |
|---|---|---|
| lem | https://github.com/lem-project/lem | commit a1362e917469019db65f089ad308bdb935ec1564 |
| micros | https://github.com/lem-project/micros | commit 2ec61c8d6028d219cc511a0e41d9228761c84251 |
| lem-mailbox | https://github.com/lem-project/lem-mailbox | default branch files retrieved for this change |
| trivia | https://github.com/guicho271828/trivia | 4383dd894f7c9861673aad78d8f09e5587bc9616 |
| inquisitor | https://github.com/cxxxr/inquisitor | 57610f688d3a2990817e34fca1d907eba433900f |
| command-line-arguments | https://github.com/fare/command-line-arguments | 5008c4e4cac5dad8f00438c6d335f36bc4fa6747 |
| type-i | https://github.com/guicho271828/type-i | 4407a6852e76e795f697180dfb01749b49cc7b0c |
| lisp-namespace | https://github.com/guicho271828/lisp-namespace | 699fccb6727027343bb5fca69162a3113996edfc |
| bt-semaphore | https://github.com/r-moeritz/bt-semaphore | 46b4bf315590f510d2d4ec5ca8908efbe68007e9 |
| queues | https://github.com/oconnore/queues | 47d4da65e9ea20953b74aeeab7e89a831b66bc94 |
| trivial-cltl2 | https://github.com/Zulu-Inuoe/trivial-cltl2 | 2ada8722dc1d7bae1f49832a2ca26b25b90055d3 |
| introspect-environment | https://github.com/Bike/introspect-environment | 69a50ac84b4c23447521dfab008cc20e4bfbee82 |

GitHub identities above (except those marked commit) are source tree SHA values
returned during retrieval. Quicklisp sources are listed in
`quicklisp/SOURCES.txt`; their directory names retain the distribution's snapshot
identity. All bundled file contents are reviewable and tracked by this repository.

## Local adaptations

- Only Lem core, Lisp syntax, LSP base and language-server source trees are
  included. Its original ASDF files are excluded. The root `cl-lsp.asd` defines
  private `cl-lsp/*` systems without `lem`, `deploy`, extension-manager or GUI
  dependencies. ASDF source-directory references use these private names.
- `lem/src/buffer/package.lisp` registers its local nickname through SBCL,
  independently of UIOP's support for that defpackage option.
- `setup.lisp` restricts ASDF lookup to this checkout and bundled source trees.
- Async-process's single C source is compiled directly into each runtime's
  private native directory; vendored source files are not build destinations.

When updating a dependency, import its current upstream source with notices,
update this inventory and run the installer and protocol checks. Source snapshot
names are provenance, not conditions selecting implementation behavior.

Additional adaptations: Swank's ASDF loader honors the runtime's XDG cache;
the micros child explicitly loads this checkout's registry setup. Vendored
ignore files and test-only nested Iterate dependencies were removed so required
generated Unicode source files are tracked and dependency lookup is unambiguous.
Bordeaux-Threads documentation assets are omitted.

Lem's optional ext/ and ui/ modules are omitted, along with Dexador, CL+SSL,
Mustache and dependencies no longer reachable from the server. Upstream test
suites, documentation/example/CI directories and Emacs client files (except
slime.el, read for Swank metadata) are omitted. CL-UNICODE ships its generated
Lisp tables; its regeneration inputs and build/test ASDF definitions are omitted.
