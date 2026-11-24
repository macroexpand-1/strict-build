(defpackage #:strict-build-fixture-clean
  (:use #:cl))

(in-package #:strict-build-fixture-clean)

(defun double (x) (* 2 x))

(defun quadruple (x) (double (double x)))
