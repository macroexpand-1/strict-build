;;;; strict-build.asd

(defsystem "strict-build"
  :description "ASDF Systems Whose Own Warnings Fail the Build. SBCL Only, No Deps"
  :author "Real Limoges"
  :license "BSD-2-Clause"
  :components ((:file "strict-build"))
  :in-order-to ((test-op (test-op "strict-build/tests"))))

(defsystem "strict-build/tests"
  :description "Loads each fixture system in a fresh SBCL and checks it loads or is refused"
  :depends-on ("strict-build" "fiveam")
  :components ((:module "test"
                :components ((:file "tests"))))
  :perform (test-op (o c)
                    (declare (ignore o c))
                    (unless (uiop:symbol-call :fiveam :run!
                                              (uiop:find-symbol* :strict-build-tests
                                                                 :strict-build/tests))
                      (error "strict-build tests failed!"))))
