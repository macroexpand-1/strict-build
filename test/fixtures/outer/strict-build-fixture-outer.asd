;;; Not strict, so the arity fixture loads with no strict scope open

(defsystem "strict-build-fixture-outer"
  :depends-on ("strict-build-fixture-arity")
  :components ((:file "outer")))
