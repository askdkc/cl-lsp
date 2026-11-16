# macOS verification

Checked against the trimmed working tree on Darwin arm64 with Roswell/SBCL.

- `ros tests/bundled-dependencies.ros`: passed; 56 source systems resolve
  inside the checkout (plus SBCL's own modules). Checks source-file existence
  and rejects external Lem, deploy, Dexador, CL+SSL and Mustache.
- `ros tests/install-headless.ros`: passed; existing destinations are preserved
  and launcher shell arguments are quoted correctly.
- `ros tests/roswell-install.ros`: passed; checks bootstrap selection despite
  a conflicting legacy cl-lsp, copied launcher arguments, successful reinstall
  and preservation after a failed build.
- `ros tests/bundled-runtime.ros --install-only`: passed; cold native/Lisp
  build, actual Roswell build hook, installed launcher and `--help`.
- `tests/lsp-core.lisp`, loaded after the generated `runtime.lisp`: passed;
  actual initialize, open, formatting, change, close, shutdown and exit handlers.
  Uses an in-process mock backend; this does not verify micros communication.
- `git diff --check`: passed.

For the handler check, use the runtime and cache from the same installation:

```sh
XDG_CACHE_HOME="$runtime/cache" ros -Q -e '(sb-ext:disable-debugger)' \
  -l "$runtime/runtime.lisp" -l tests/lsp-core.lisp -q
```

The vendor tree was reduced from 2,900 files / 35.0 MiB of file contents to
963 files / 14.2 MiB. Lem's optional extensions and their HTTP/TLS/template
dependencies are excluded. Upstream tests, documentation assets and redundant
Unicode generation inputs are omitted; generated Unicode Lisp tables remain.

The full socket-based LSP check remains unverified: the execution sandbox
denies localhost socket creation. GitHub download was not tested. Builds emit
upstream Lisp warnings but the checks above complete successfully.
