;;;; -*- mode: lisp; syntax: common-lisp; base: 10; coding: utf-8-unix; external-format: (:utf-8 :eol-style :lf); -*-
;;;; dev.lisp --- nix shell stuff

(uiop:define-package #:scripts/dev
  (:use #:cl
        #:uiop
        #:inferior-shell
        #:cl-scripting
        #:cl-launch/dispatch
        #:optima
        #:optima.ppcre
        #:scripts/common)
  (:import-from #:marie
                #:def- #:def
                #:home
                #:fmt))

(in-package #:scripts/dev)

(def- template-directory ()
  "Return the template directory for the current system."
  (uiop:os-cond
   ((or (uiop:os-macosx-p) (uiop:os-unix-p))
    (home "src/t/"))
   (t (home "Templates/"))))

(defcommand dev (&rest args)
  (destructuring-bind (&optional base &rest command)
      args
    (cond
      ((null args)
       (run/i `("oof" "develop")))
      (t (let* ((cwd (uiop:getcwd))
                (path (uiop:ensure-directory-pathname
                       (uiop:merge-pathnames* "shell" (template-directory))))
                (directory (uiop:merge-pathnames* base path))
                (cmd (or command '("bash"))))
           (when (uiop:directory-exists-p directory)
             (uiop:chdir directory)
             (run/i `("oof" "develop" "." "--command" "sh" "-c" ,(fmt "cd ~A && ~{~A~^ ~}" cwd cmd)))))))
    (success)))

(register-commands :scripts/dev)
