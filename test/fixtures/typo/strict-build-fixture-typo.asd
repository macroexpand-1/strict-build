(defsystem "strict-build-fixture-typo"
  :defsystem-depends-on ("strict-build")
  :class "strict-build:strict-system"
  :default-component-class "strict-build:strict-source-file"
  :components ((:file "typo")))
