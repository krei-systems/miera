(uiop:define-package
    :scripts/nix
    (:use
     :cl
     :fare-utils
     :uiop
     :inferior-shell
     :cl-scripting
     :optima
     :optima.ppcre
     :cl-ppcre
     :local-time
     :cl-launch/dispatch
     :scripts/misc
     :scripts/utils)
  (:export #:nix))

(in-package :scripts/nix)

(defparameter +hostname+ (hostname))
(defparameter +http-repository+ "https://github.com/NixOS/nixpkgs.git")
(defparameter +git-repository+ "git@github.com:NixOS/nixpkgs.git")
(defparameter +base-dir+ (subpathname (user-homedir-pathname) ".nix/"))

(defun base-path (path)
  (subpathname +base-dir+ path))

(defparameter +nixpkgs+ (base-path "nixpkgs/"))
(defparameter +default-nix+ (base-path "nixpkgs/default.nix"))

(defun index-path (name)
  (subpathname (base-path "index/") (format nil "~A.~A.xz" name +hostname+)))

(defparameter +index-channels+ (index-path "channels"))
(defparameter +index-upstream+ (index-path "upstream"))
(defparameter +index-installed+ (index-path "installed"))

(defun ensure-dotnix ()
  (ensure-directories-exist +base-dir+))

(defun ensure-nixpkgs ()
  (ensure-dotnix)
  (unless (file-exists-p +default-nix+)
    (with-current-directory (+base-dir+)
      (run/i `(git "clone" ,+http-repository+)))))

(defun cdx (&rest args)
  (when (>= (length args) 1)
    (let ((directory (first args))
          (arguments (rest args)))
      (chdir directory)
      (when arguments (run/i arguments))
      (success))))

(exporting-definitions
 (defun nix (&rest args)
   (ensure-nixpkgs)
   (cond ((null args) (err "Meh"))
         (t (let ((self (argv0))
                  (op (first args))
                  (a (rest args)))
              (match op
                ((ppcre "^(cd)$")
                 (apply #'cdx `(,+nixpkgs+ ,@a)))
                ((ppcre "^(out-path|o-p)$")
                 (match (run/ss `(,self "query" "--out-path" ,(first a)))
                   ((ppcre ".*? (/.*)" path) (format t "~A~%" path))))
                ((ppcre "^(cd-out-path|c-o-p)$")
                 (let* ((dir (run/ss `(,self "out-path" ,(first a))))
                        (spec (append (list dir) a)))
                   (match spec
                     ((list path name command)
                      (cdx path command)))))
                ((ppcre "^(which)$")
                 (run `(command-not-found ,@a :error-output nil :on-error nil)))
                ((ppcre "^(store)$")
                 (run/i `(nix-store ,@a))
                 (success))
                ((ppcre "^(repl)$")
                 (run/i `(nix-repl ,@a)))
                ((ppcre "^(impure-shell)$")
                 (run/i `(nix-shell ,@a)))
                ((ppcre "^(pure-shell|shell)$")
                 (run/i `(,self "impure-shell" "--pure" ,@a)))
                ((ppcre "^(rebuild)$")
                 (run/i `(sudo nixos-rebuild ,@a)))
                ((ppcre "^(rebuild-switch|r-s)$")
                 (run/i `(,self "rebuild" "switch" ,@a)))
                ((ppcre "^(rebuild-switch-upgrade|r-s-u)$")
                 (run/i `(,self "rebuild" "switch" "--upgrade" ,@a)))
                ((ppcre "^(instantiate)$")
                 (run/i `(nix-instantiate ,@a)))
                ((ppcre "^(eval)$")
                 (run/i `(,self "instantiate" "--eval" "--strict" "--show-trace" ,@a)))
                ((ppcre "^(grep)$")
                 (with-current-directory (+nixpkgs+)
                   (run/i `(find "." "-iname" "*.nix" "-exec" "grep" ,@a "{}" "\;"))))
                ((ppcre "^(find)$")
                 (run/i `(find ,+nixpkgs+ "-iname" ,@a)))
                ((ppcre "^(install-package|i-p)$")
                 (run/i `(sudo "nix-install-package" ,@a)))
                ((ppcre "^(install-package-uri|i-p-u)$")
                 (run/i `(,self "install-package" "--non-interactive" "--url" ,@a)))
                ((ppcre "^(references|r)$")
                 (run/i `(,self "store" "-q" "--references" ,(run/ss `(,self "out-path" ,(last a))))))
                ((ppcre "^(referrers|R)$")
                 (run/i `(,self "store" "-q" "--referrers" ,(run/ss `(,self "out-path" ,(last a))))))
                ((ppcre "^(query-root|q-r)$")
                 (run/i `(sudo "nix-env" "--query" ,@a)))
                ((ppcre "^(closure)$")
                 (run/i `(,self "store" "-qR" ,@a)))
                ((ppcre "^(set-flag|s-f)$")
                 (run/i `(,self "env" "--set-flag" ,@a)))
                ((ppcre "^(option)$")
                 (run/i `(nixos-option ,@a)))
                ((ppcre "^(garbage-collect|g-c)$")
                 (run/i `(,self "store" "--gc" ,@a)))
                ((ppcre "^(garbage-collect-delete|g-c-d)$")
                 (run/i `(sudo "nix-collect-garbage -d" ,@a)))

                ((ppcre "^(channel|ch)$")
                 (run/i `(nix-channel ,@a)))
                ((ppcre "^(channel-list|ch-l)$")
                 (run/i `(,self "channel" "--list" ,@a)))
                ((ppcre "^(channel-add|ch-a)$")
                 (run/i `(,self "channel" "--add" ,@a)))
                ((ppcre "^(channel-remove|ch-r)$")
                 (run/i `(,self "channel" "--remove" ,@a)))
                ((ppcre "^(channel-update|ch-u)$")
                 (run/i `(,self "channel" "--update" ,@a)))
                ((ppcre "^(channel-name|ch-n)$")
                 (match (run/ss `(,self "channel-list" ,@a))
                   ((ppcre "^(.*?) .*" name)
                    (format t "~A~%" name))))

                ((ppcre "^(root-channel|r-ch)$")
                 (run/i `(nix-channel ,@a)))
                ((ppcre "^(root-channel-list|r-ch-l)$")
                 (run/i `(,self "root-channel" "--list" ,@a)))
                ((ppcre "^(root-channel-add|r-ch-a)$")
                 (run/i `(,self "root-channel" "--add" ,@a)))
                ((ppcre "^(root-channel-remove|r-ch-r)$")
                 (run/i `(,self "root-channel" "--remove" ,@a)))
                ((ppcre "^(root-channel-update|r-ch-u)$")
                 (run/i `(,self "root-channel" "--update" ,@a)))
                ((ppcre "^(root-channel-name|r-ch-n)$")
                 (match (run/ss `(,self "root-channel-list" ,@a))
                   ((ppcre "^(.*?) .*" name)
                    (format t "~A~%" name))))

                ;; channels
                ((ppcre "^(env|e)$")
                 (run/i `(nix-env ,@a)) (success))
                ((ppcre "^(build|b)$")
                 (run/i `(nix-build ,@a)))
                ((ppcre "^(query|q)$")
                 (run/i `(,self "env" "--query" ,@a)))
                ((ppcre "^(upgrade|U)$")
                 (run/i `(,self "env" "--upgrade" ,@a)))
                ((ppcre "^(upgrade-always|U-a)$")
                 (run/i `(,self "upgrade" "--always" ,@a)))
                ((ppcre "^(install|i)$")
                 (run/i `(,self "env" "--install" "-A"
                                ,@(loop :for pkg :in a
                                     :collect (format nil "~A.~A" (run/ss `(,self "channel-name")) pkg)))))
                ((ppcre "^(Install|I)$") (run/i `(,self "env" "--install" "-A" ,@a)))
                ((ppcre "^(query-available|q-a)$")
                 (run/i `(,self "query" "--available" "-P" ,@a)))
                ((ppcre "^(compare-versions)$")
                 (run/i `(,self "query" "--compare-versions" ,@a)))
                ((ppcre "^(compare-versions-lt|c-v-lt)$")
                 (run/i `(pipe (,self "compare-versions" ,@a) (grep "<"))))
                ((ppcre "^(compare-versions-eq|c-v-eq)$")
                 (run/i `(pipe (,self "compare-versions" ,@a) (grep "="))))
                ((ppcre "^(compare-versions-gt|c-v-gt)$")
                 (run/i `(pipe (,self "compare-versions" ,@a) (grep ">"))))
                ((ppcre "^(describe-available|d-a)$")
                 (run/i `(,self "query-available" "--description" ,@a)))
                ((ppcre "^(index-available|i-a)$")
                 (run `(pipe (,self "query-available") (xz "-c" (> ,+index-channels+)))))
                ((ppcre "^(search-available|search|s-a|s)$")
                 (run `(xzgrep "--color" "-i" ,@a ,+index-channels+) :error-output nil :on-error nil))
                ((ppcre "^(view-available|v-a)$")
                 (run/i `(xzless ,+index-channels+)))

                ;; upstream
                ((ppcre "^(upstream-env|u-e)$")
                 (run/i `(,self "env" "-f" ,+default-nix+ ,@a)))
                ((ppcre "^(upstream-build|u-b)$")
                 (run/i `(,self "build" "-I" ,(format nil "nixpkgs=~A" +nixpkgs+) ,@a)))
                ((ppcre "^(upstream-query|u-q)$")
                 (run/i `(,self "upstream-env" "--query" ,@a)))
                ((ppcre "^(upstream-upgrade|u-U)$")
                 (run/i `(,self "upstream-env" "--upgrade" ,@a)))
                ((ppcre "^(upstream-upgrade-always|u-U-a)$")
                 (run/i `(,self "upstream-upgrade" "--always" ,@a)))
                ((ppcre "^(upstream-install|u-i)$")
                 (run/i `(,self "upstream-env" "--install" "-A" ,@a)))
                ((ppcre "^(upstream-Install|u-I)$")
                 (run/i `(,self "upstream-env" "--install" "-A" ,@a)))
                ((ppcre "^(upstream-query-available|u-q-a)$")
                 (run/i `(,self "upstream-query" "--available" "-P" ,@a)))
                ((ppcre "^(upstream-compare-versions)$")
                 (run/i `(,self "upstream-query" "--compare-versions" ,@a)))
                ((ppcre "^(upstream-compare-versions-lt|u-c-v-lt)$")
                 (run/i `(pipe (,self "upstream-compare-versions" ,@a) (grep "<"))))
                ((ppcre "^(upstream-compare-versions-eq|u-c-v-eq)$")
                 (run/i `(pipe (,self "upstream-compare-versions" ,@a) (grep "="))))
                ((ppcre "^(upstream-compare-versions-gt|u-c-v-gt)$")
                 (run/i `(pipe (,self "upstream-compare-versions" ,@a) (grep ">"))))
                ((ppcre "^(upstream-describe-available|u-d-a)$")
                 (run/i `(,self "upstream-query-available" "--description" ,@a)))
                ((ppcre "^(upstream-index-available|u-i-a)$")
                 (run `(pipe (,self "upstream-query-available") (xz "-c" (> ,+index-upstream+)))))
                ((ppcre "^(upstream-search-available|u-search|u-s-a|u-s)$")
                 (run `(xzgrep "--color" "-i" ,@a ,+index-upstream+) :error-output nil :on-error nil))
                ((ppcre "^(upstream-view-available|u-v-a)$")
                 (run/i `(xzless ,+index-upstream+)))

                ;; installed
                ((ppcre "^(view-installed|v-i)$")
                 (run/i `(xzless ,+index-installed+)))
                ((ppcre "^(search-installed|s-i)$")
                 (run `(xzgrep "--color" "-i" ,@a ,+index-installed+)
                      :error-output nil :on-error nil))
                ((ppcre "^(index-installed|i-i)$")
                 (run `(pipe (,self "query-installed") (xz "-c" (> ,+index-installed+)))))
                ((ppcre "^(describe-installed|d-i)$")
                 (run/i `(,self "query-installed" "--description" ,@a)))
                ((ppcre "^(query-installed|q-i)$")
                 (run/i `(,self "query" "--installed" ,@a)))

                ;; common
                ((ppcre "^(uninstall|ui)$")
                 (run/i `(,self "env" "--uninstall" ,@a)))
                ((ppcre "^(update|u)$")
                 (run/i `(,self "channel-update" ,@a)))
                ((ppcre "^(root-update|r-u)$")
                 (run/i `(,self "root-channel-update" ,@a)))
                ((ppcre "^(upstream-update|u-u)$")
                 (with-current-directory (+nixpkgs+)
                   (when (string= (run/ss `(git "rev-parse" "--abbrev-ref" "HEAD")) "master")
                     (run/i `(git "pull" "origin" "master")))))
                ((ppcre "^(build-index|index)$")
                 (loop :for command :in '("index-available" "upstream-index-available" "index-installed")
                    :do (run/i `(,self ,command))))
                ((ppcre "^(complete-update|c-u)$")
                 (loop :for command :in '("channel-update" "root-channel-update" "upstream-update" "build-index")
                    :do (run/i `(,self ,command))))
                ((ppcre "^(complete-upgrade|c-U)$")
                 (loop :for command :in '("complete-update" "upstream-upgrade" "rebuild-switch-upgrade")
                    :do (run/i `(,self ,command))))
                ((ppcre "^(complete-search|c-s)$")
                 (loop :for command :in '("search-available" "upstream-search-available")
                    :do (run/i `(,self ,command ,@a))))

                ;; miscellany
                ((ppcre "^(view-packages|v-p)$")
                 (run/i `(,self "query-available" "-A" ,(format nil "~A.~A" (run/ss `(,self "channel-name")) (first a)))))
                ((ppcre "^(make)$")
                 (run/i `(,self "pure-shell" "--run" "make" ,@a)))

                ;; prefetch
                ((ppcre "^(fetch-url|f-u)$")
                 (run/i `(nix-prefetch-url ,@a)))
                ((ppcre "^(fetch-file|f-f)$")
                 (run/i `(,self "fetch-url" ,(format nil "file://" (first a)))))
                ((ppcre "^(fetch-git|f-g)$")
                 (run/i `(nix-prefetch-git ,@a)))
                ((ppcre "^(fetch-zipl|f-z)$")
                 (run/i `(nix-prefetch-zip ,@a)))
                ((ppcre "^(fetch-hg|f-h)$")
                 (run/i `(nix-prefetch-hg ,@a)))
                ((ppcre "^(fetch-svn|f-s)$")
                 (run/i `(nix-prefetch-svn ,@a)))
                ((ppcre "^(fetch-bzr|f-b)$")
                 (run/i `(nix-prefetch-bzr ,@a)))
                ((ppcre "^(fetch-cvsl|f-c)$")
                 (run/i `(nix-prefetch-cvs ,@a)))))))
   (success)))

(register-commands :scripts/nix)
