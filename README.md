# CL-LSP
This is [askdkc/cl-lsp](https://github.com/askdkc/cl-lsp), a fork of CL-LSP for Common Lisp.
It includes a Roswell installer for the language server without the Lem editor, with macOS OpenSSL compatibility checks.

## Getting Started

1. Get CL-LSP Installed

    1. Install [roswell](https://github.com/roswell/roswell/)

    2. Clone **this fork** and install the language-server dependencies into a
       **new** directory (Git, Make, Autoconf, Automake and Libtool are
       also required):

       ```sh
       git clone https://github.com/askdkc/cl-lsp.git
       cd cl-lsp
       ros scripts/install-headless.ros --prefix "$HOME/.local/share/cl-lsp"
       ```

       Roswell must already have a working SBCL and Quicklisp setup. The installer
       fetches current Git heads; it does not pin a Lem or OpenSSL version. A failed
       attempt is retained for inspection. Retry with a new prefix.

    3. Verify loading: `~/.local/share/cl-lsp/cl-lsp --help`.
       Configure your editor to launch this executable with `--stdio`.

2. Configure your editor to use CL-LSP. See below for more information about editor integration.

3. Enjoy!

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

Use the installer from this fork's checkout. `ros install askdkc/cl-lsp` alone
does not run this dependency and OpenSSL setup.

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
