(defpackage #:strict-build-fixture-forward
  (:use #:cl))

(in-package #:strict-build-fixture-forward)

(defun quadruple (x) (double (double x)))
