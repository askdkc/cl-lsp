# CL-LSP

[askdkc/cl-lsp](https://github.com/askdkc/cl-lsp) is a Common Lisp language server.
It bundles its runtime dependencies and uses Lem's buffer and Lisp syntax code.

## Installation

Requires Roswell/SBCL and a C compiler (Xcode Command Line Tools on macOS).

```sh
ros install askdkc/cl-lsp
```

Configure your editor to run `~/.roswell/bin/cl-lsp --stdio`.
Check loading with `~/.roswell/bin/cl-lsp --help`.

No separate Lem installation, Qlot or OpenSSL setup is needed.
Dependencies come from `vendor/`; installation does not download additional
Lisp packages. Failed builds preserve the previously selected launcher.

See [bundled sources and licenses](vendor/SOURCES.md) and
[verification](tests/MACOS-VERIFICATION.md).

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
