# CL-LSP
This is [askdkc/cl-lsp](https://github.com/askdkc/cl-lsp), a fork of CL-LSP for Common Lisp.
It includes a Roswell installer for the language server without the Lem editor, with macOS OpenSSL compatibility checks.

## Getting Started

With [Roswell](https://github.com/roswell/roswell/), SBCL and Quicklisp set up:

```sh
ros install askdkc/cl-lsp
```

The installation hook fetches the language-server dependencies, builds the native
library and configures compatible OpenSSL on macOS. Git, Make, Autoconf, Automake
and Libtool are required. Lem's editor is not installed.

Configure your editor to run `~/.roswell/bin/cl-lsp --stdio`.
Use `~/.roswell/bin/cl-lsp --help` to check loading.

Reinstallation builds a new runtime before switching the launcher; a failed build
keeps the previous runtime selected. Dependency versions are not hard-coded.

### macOS: `ASN1_STRING_data` is undefined

This is a CL+SSL/OpenSSL API mismatch during Qlot's HTTPS requests. An existing
`libssl.dylib` is not enough: CL+SSL also needs compatible symbols in libcrypto.
The installer probes installed Homebrew OpenSSL pairs in separate processes,
rejects pairs missing `ASN1_STRING_data`, and explicitly configures CL+SSL before
loading Qlot. It recompiles CL+SSL to discard decisions cached for a different
library, then exercises the failing API. The launcher uses the same configuration.
It does not relink Homebrew, disable certificate verification, or downgrade HTTPS.
If no compatible pair is installed, installation stops with an explicit error.

To check this part independently, without downloading Lem:

```sh
ros scripts/install-headless.ros --prefix /tmp/cl-lsp-tls-check-new --tls-only
```

The standalone script is available for diagnostics or a custom installation
prefix; normal installation only requires `ros install askdkc/cl-lsp`.

### `Component :TRIVIAL-GRAY-STREAMS not found`

Loading `cl+ssl/config` only prepares configuration and CFFI; it does not install
all CL+SSL dependencies. The installer now reads CL+SSL's ASDF dependency list
and resolves those dependencies with Quicklisp after selecting OpenSSL. It then
recompiles CL+SSL once, avoiding both missing dependencies and duplicate-load
package warnings.

If the error is reported by `modkh language install`, that command uses MoDKH's
own generated startup configuration. Updating this fork does not update an
already-installed MoDKH package.

### What is actually required?

`cl-lsp` delegates to `lem-language-server/cli`; it is not independent of Lem.
The required Lem systems are `lem-language-server`, `lem/core`,
`lem-lisp-syntax` and `lem-lsp-base`, plus their transitive dependencies.
The headless manifest keeps the Git overrides for micros, lem-mailbox,
async-process, jsonrpc and lem-extension-manager. Ordinary dependencies come
from Quicklisp. Roswell is also used to spawn the micros backend, and
async-process needs its native library built.

Lem source is still fetched, but the Lem editor, SDL/SDL-TTF/SDL-image, WebView,
and unrelated language modes are not installation targets. This is a smaller
installation of the existing server, not a rewrite that removes Lem core.

Installer checks (the real CL+SSL test requires macOS and Roswell):

```sh
ros tests/install-headless.ros
ros tests/roswell-install.ros
```

# Visual Studio Code

Depends `CL-LSP` on [vscode-lisp](https://github.com/mattn/vscode-lisp). See [vscode](vscode) for more information about Visual Studio Code integration.

## Status

CL-LSP is still in early development, so you may run into rough edges with any of the features. The following table shows the status of various features when using the latest development toolchain snapshot.

| Feature | Status | Notes |
|---------|:------:|-------|
| Go to definition | ✅ |
| Find references | ✅ |
| Document highlight | ✅ |
| Hover | ✅ |
| Completion | ✅ |
| Signature Help | ✅ |
| Formatting | ✅ |
| Range Formatting | ✅ |
