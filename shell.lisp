;;;; shell.lisp

(uiop:define-package #:scripts/shell
    (:use #:cl
          #:inferior-shell
          #:cl-scripting
          #:optima
          #:optima.ppcre
          #:marie
          #:scripts/common))

(in-package #:scripts/shell)

(defun template-directory ()
  "Return the template directory for the current system."
  (uiop:os-cond
   ((uiop:os-macosx-p) (home "Templates/"))
   ((uiop:os-unix-p) (xdg-dir "TEMPLATES"))
   (t (home "Templates/"))))

(defcommand shell (&rest args)
  (destructuring-bind (&optional base &rest command)
      args
    (cond
      ((null args)
       (run/i `("barf" "shell")))
      (t (let* ((cwd (uiop:getcwd))
                (path (uiop:ensure-directory-pathname
                       (uiop:merge-pathnames* "shell" (template-directory))))
                (directory (uiop:merge-pathnames* base path))
                (cmd (or command '("bash"))))
           (when (uiop:directory-exists-p directory)
             (uiop:chdir directory)
             (run/i `("barf" "shell" "--run" ,(fmt "cd ~A; ~{'~A'~^ ~}" cwd cmd)))))))
    (success)))

(register-commands :scripts/shell)
