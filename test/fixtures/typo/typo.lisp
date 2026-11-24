(defpackage #:strict-build-fixture-typo
  (:use #:cl))

(in-package #:strict-build-fixture-typo)

(defun double (x) (* 2 x))

;; DOUBEL is the typo
(defun quadruple (x) (doubel (double x)))
