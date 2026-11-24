(defsystem "strict-build-fixture-arity"
  :defsystem-depends-on ("strict-build")
  :class "strict-build:strict-system"
  :default-component-class "strict-build:strict-source-file"
  :serial t
  :components ((:file "defines")
               (:file "calls")))
