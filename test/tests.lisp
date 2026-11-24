;;;; test/tests.lisp: load each fixture system in a fresh SBCL and see what happens

(defpackage #:strict-build/tests
  (:use #:cl #:fiveam)
  (:export #:strict-build-tests))

(in-package #:strict-build/tests)

(def-suite strict-build-tests :description "Fixture systems that load or get refused")
(in-suite strict-build-tests)

(defun child-forms (system)
  "Forms for a fresh SBCL that sees only this repo, loads SYSTEM, and prints one RESULT line"
  (list "(require :asdf)"
        (format nil "(asdf:initialize-source-registry '(:source-registry (:tree ~S) :ignore-inherited-configuration))"
                (namestring (asdf:system-source-directory "strict-build")))
        ;; the handler below reads strict-build's symbols
        "(asdf:load-system \"strict-build\")"
        (format nil "(handler-case (progn (asdf:load-system ~S) (format t \"~~&RESULT LOADED~~%\"))
                       (strict-build:strict-build-refused (c)
                         (format t \"~~&RESULT REFUSED ~~D~~%\" (length (strict-build:refused-warnings c))))
                       (error (c) (format t \"~~&RESULT FAILED ~~S~~%\" (type-of c))))"
                system)))

(defun child-arguments (system)
  "The sbcl command line that runs CHILD-FORMS for SYSTEM"
  (append (list "sbcl" "--non-interactive" "--no-userinit")
          (mapcan (lambda (form) (list "--eval" form)) (child-forms system))))

(defun result-line (output)
  "The RESULT line in a child's OUTPUT, without its prefix, or :NO-RESULT"
  (let ((line (find-if (lambda (line) (uiop:string-prefix-p "RESULT " line))
                       (uiop:split-string output :separator '(#\Newline)))))
    (if line (subseq line (length "RESULT ")) :no-result)))

(defun load-in-child (system)
  "Load SYSTEM in a fresh SBCL: \"LOADED\", \"REFUSED N\", \"FAILED TYPE\", or :NO-RESULT"
  (result-line (uiop:run-program (child-arguments system)
                                 :output :string :error-output :output :ignore-error-status t)))

(test a-clean-system-loads
  (is (equal "LOADED" (load-in-child "strict-build-fixture-clean"))))

(test a-function-a-later-file-defines-is-fine
  (is (equal "LOADED" (load-in-child "strict-build-fixture-forward"))))

(test a-misspelled-function-is-refused
  (is (equal "REFUSED 1" (load-in-child "strict-build-fixture-typo")))
  (is (equal "REFUSED 1" (load-in-child "strict-build-fixture-typo"))))

(test a-wrong-argument-count-is-refused
  (is (equal "REFUSED 1" (load-in-child "strict-build-fixture-arity")))
  (is (equal "REFUSED 1" (load-in-child "strict-build-fixture-arity"))))

(test a-strict-dependency-is-refused-inside-a-plain-system
  (is (equal "REFUSED 1" (load-in-child "strict-build-fixture-outer"))))
