# strict-build

ASDF systems whose own warnings fail the build.
SBCL only, no dependencies beyond ASDF.

SBCL has no `-Werror`.
It reports a misspelled function, or a call with the wrong number of arguments, only as a style-warning, and the build carries on.
A system built with strict-build fails instead, listing every warning from its own files.

## Use

```lisp
(defsystem "my-lib"
  :defsystem-depends-on ("strict-build")
  :class "strict-build:strict-system"
  :default-component-class "strict-build:strict-source-file"
  :components (...))
```

A refused operation signals `strict-build:strict-build-refused`; `strict-build:refused-warnings` returns the warnings, oldest first.

## What Counts

- Every warning from compiling or loading the system's own files, style-warnings included.
- Undefined functions, which SBCL reports only when the compilation unit ends.
  One operation is one unit, so a function a later file defines is fine.
- Warnings while loading, since fiveam compiles test bodies then.

Redefinitions from reloading in a live image don't count, and warnings from other libraries only print.

A refusal deletes the fasls the operation compiled, so the next load compiles again and refuses again.

A strict system loaded as a dependency of a plain one still refuses its own warnings, file by file.
An undefined function there only prints, since a later file might define it.

## Why Not ASDF's Settings

`*compile-file-warnings-behaviour*` goes by `compile-file`'s `warnings-p`, which is NIL for style-warnings.
`uiop:enable-deferred-warnings-check` reads an SBCL internal that SBCL 2.6.10 no longer has.

## Tests

```sh
sbcl --non-interactive --eval '(asdf:test-system "strict-build")'
```

Each test loads a fixture system under `test/fixtures/` in a fresh SBCL that sees only this repository.

## License

BSD-2-Clause.
