# macOS installation verification

Verified on 2026-11-16 JST, Darwin arm64, in this `cl-lsp` checkout
(base revision `f06e9b8bb8111f9643f7988dcb9b98705887e1ed`).

## Cause

The supplied `last-failure.json` failed at `lem-dependencies`, with
`The alien function "ASN1_STRING_data" is undefined.` Its referenced Qlot
stack-trace file no longer existed. The failure was reproduced directly with
Roswell/SBCL and the installed CL+SSL, independently of the missing trace.

The Homebrew default was OpenSSL 4.1.0. It did not expose the required API.
The installed OpenSSL 3.5.9 pair did, and was selected by the new capability
probe. These are observed versions, not version constraints in the installer.

## Results

- `ros tests/install-headless.ros`: passed. Includes a real
  CL+SSL load and ASN1 allocation/access/free using the selected library,
  reproduction without the override, rejection of an incompatible default,
  failure when no pair exists, preservation of an existing prefix, and shell
  quoting with embedded quotes and shell metacharacters.
  The missing-dependency fixture also verifies that removing the dependency
  resolution step reproduces `TRIVIAL-GRAY-STREAMS` missing, while the corrected
  generated configuration succeeds. This fixture uses real ASDF with a simulated
  Quicklisp provider; the separate TLS test loads the installed real CL+SSL.
- `ros scripts/install-headless.ros --prefix /tmp/cl-lsp-ros-tls-check --tls-only`:
  passed, including the actual CL+SSL call (`CL_LSP_TLS_READY`).
- `ros scripts/install-headless.ros --prefix /tmp/cl-lsp-dependency-install-check`:
  TLS probe and real Lisp API call passed (`CL_LSP_TLS_READY`). Git clone then
  failed with `Could not resolve host: github.com` (exit 128). No launcher was
  published. Dependency resolution, native compilation, LSP initialize,
  diagnostics and editor operation remain unverified.
- `git diff --check`: passed.

The installer and tests use Common Lisp and Roswell. Shell is used only for
entry-point launchers and external build commands. Library probing uses SBCL's
foreign-library API in separate processes.

The reduced dependency graph was inspected in local Lem source
`a1362e917469019db65f089ad308bdb935ec1564`: `lem-language-server/cli` depends
on the language server, `lem/core`, Lisp syntax and LSP base systems. It does
not target the GUI editor. The proposed reduced manifest still needs a cold
installation test with network access; this is not proof of a functioning
minimal installation against a future upstream Git head.

## Single-command Roswell installation

The fork now registers Roswell's build hook from `cl-lsp.asd`. Only during
`:ros.installing`, server loading is deferred until the hook prepares the
dependencies. A sidecar in Roswell's bin directory selects the completed runtime;
the normal installed `cl-lsp` script forwards arguments to it.

`ros tests/roswell-install.ros` exercises Roswell's actual
`install-system-script` routine against an isolated checkout and bin directory.
Dependency construction is replaced with a test executable. Hook invocation,
script copying, argument forwarding (including spaces), successful reinstall,
preservation after a failed reinstall, and normal ASDF dependencies are checked.
This does not establish remote GitHub download or real LSP startup success.

No global Roswell launcher, MoDKH installation, Homebrew link, or existing
Lem checkout was changed during verification. Full remote installation remains
unverified because GitHub DNS resolution failed in this environment.
