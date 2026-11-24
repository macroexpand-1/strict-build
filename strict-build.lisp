;;;; strict-build.lisp: ASDF systems whose own warnings fail the build

(defpackage #:strict-build
  (:use #:cl)
  (:export #:strict-system #:strict-source-file
           #:strict-build-refused #:refused-warnings))

(in-package #:strict-build)

(defstruct (strict-scope (:constructor make-strict-scope ()))
  "What one strict operation (or one strict file, outside any operation) has seen so far"
  ;; mutable
  (warnings '())                        ; newest first
  (outputs '()))

(defvar *strict-scope* :no-scope
  "The strict scope open now or :NO-SCOPE")

;;; An operation on a STRICT-SYSTEM is one compilation unit and one scope.
;;; Any warning from its STRICT-SOURCE-FILEs or SBCL's undefined-function
;;; warnings  fails it.

(defclass strict-system (asdf:system) ()
  (:documentation "A system whose operations fail on any warning from its own files"))

(defclass strict-source-file (asdf:cl-source-file) ()
  (:documentation "A Lisp file whose warnings fail the strict operation it's part of"))

(define-condition strict-build-refused (error)
  ((warnings :initarg :warnings :reader refused-warnings))
  (:documentation "A strict operation's files raised warnings. REFUSED-WARNINGS has them oldest first")
  (:report (lambda (condition stream)
             (format stream "Strict build refused ~D warning~:P:~{~%  ~A~}"
                     (length (refused-warnings condition)) (refused-warnings condition)))))

(defun keep-warning (warning)
  "Keep WARNING in the open scope, unless ASDF counts it as uninteresting or it's ASDF's own
summary of a file's warnings (already kept) Still prints"
  (unless (or (typep warning 'uiop:compile-condition)
              (uiop:match-any-condition-p warning uiop:*usual-uninteresting-conditions*))
    (push warning (strict-scope-warnings *strict-scope*))))

(defun refuse-scope (strict-scope)
  "Signal STRICT-BUILD-REFUSED if STRICT-SCOPE kept any warnings, first deleting the files it
compiled so the next load can't skip them. :CLEAN when it kept none"
  (let ((warnings (reverse (strict-scope-warnings strict-scope))))
    (cond ((null warnings) :clean)
          (t (mapc #'uiop:delete-file-if-exists (strict-scope-outputs strict-scope))
             (error 'strict-build-refused :warnings warnings)))))

(defun call-keeping-warnings (thunk)
  "Call THUNK, keeping each warning it raises in the open scope"
  (handler-bind ((warning #'keep-warning))
    (funcall thunk)))

(defun call-in-file-scope (thunk)
  "Call THUNK, one strict file's work outside any strict operation then refuse what it kept.
An undefined function prints only here"
  (let ((*strict-scope* (make-strict-scope)))
    (multiple-value-prog1 (call-keeping-warnings thunk)
      (refuse-scope *strict-scope*))))

(defun call-in-operation-scope (thunk)
  "Call THUNK (a strict system's operation) in one compilation unit. Keeps the warnings SBCL
reports as the unit ends, then refuses everything kept"
  (let ((*strict-scope* (make-strict-scope))
        (body-finished nil))
    (multiple-value-prog1
        (handler-bind ((warning (lambda (warning)
                                  (when body-finished (keep-warning warning)))))
          (with-compilation-unit (:override t)
            (multiple-value-prog1 (funcall thunk)
              (setf body-finished t))))
      (refuse-scope *strict-scope*))))

(defmethod asdf:perform :around ((operation asdf:operation) (strict-source-file strict-source-file))
  (if (eq *strict-scope* :no-scope)
      (call-in-file-scope (lambda () (call-next-method)))
      (call-keeping-warnings (lambda () (call-next-method)))))

(defmethod asdf:perform :after ((compile-op asdf:compile-op) (strict-source-file strict-source-file))
  (setf (strict-scope-outputs *strict-scope*)
        (append (asdf:output-files compile-op strict-source-file)
                (strict-scope-outputs *strict-scope*))))

(defmethod asdf:operate :around (operation (strict-system strict-system) &key &allow-other-keys)
  (if (eq *strict-scope* :no-scope)
      (call-in-operation-scope (lambda () (call-next-method)))
      (call-next-method)))
