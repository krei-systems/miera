;;;; -*- mode: lisp; syntax: common-lisp; base: 10 -*-
;;;; unix.lisp --- some unix-related stuff, or are they really?

(uiop:define-package #:ebzzry-scripts/src/unix
  (:use #:cl
        #:inferior-shell
        #:cl-scripting
        #:optima
        #:optima.ppcre
        #:marie
        #:ebzzry-scripts/src/common))

(in-package #:ebzzry-scripts/src/unix)

(% md "mkdir -p")
(% rm! "rm -rf")
(% ln! "ln -sf")

(% l  "ls -tr -A -F --color")
(% ll "l -l")
(% la "ls -A -F --color")
(% lk "la -l")

(% l! "l -R")
(% lh "l -H")
(% l1 "l -1")

(def lv (&rest args)
  (run/i `(pipe (l ,@args) (less)))
  (success))

(def sush (&rest args)
  (run/i `(sudo "sh" "-c" ,(fmt "~{~A~^ ~}" args)))
  (success))

(register-commands :ebzzry-scripts/src/unix)
