;;; apps.lisp

(uiop:define-package #:scripts/apps
    (:use #:cl
          #:fare-utils
          #:uiop
          #:inferior-shell
          #:cl-scripting
          #:optima
          #:optima.ppcre
          #:cl-launch/dispatch
          #:scripts/misc
          #:scripts/utils
          #:scripts/unix)
  (:export #:bt
           #:dv
           #:e
           #:gpg
           #:par
           #:pm
           #:rz
           #:rl
           #:rm@
           #:s
           #:us
           #:vg
           #:xf
           #:xm
           #:zx

           #:ae
           #:au
           #:av
           #:bm
           #:cv
           #:dc
           #:earth
           #:ev
           #:fs
           #:lo
           #:lx
           #:mx
           #:p
           #:pc
           #:pe
           #:tx
           #:ty
           #:sm
           #:sp
           #:tb
           #:xb
           #:xo
           #:xs
           #:za

           #:bb
           #:cb
           #:fb

           #:b
           #:ca
           #:demu
           #:eb
           #:kp
           #:kt
           #:mb
           #:o
           #:ok
           #:qbt
           #:qt4
           #:qt5
           #:qtx
           #:rmd
           #:sw
           #:td
           #:vl

           #:fcade
           #:ui
           #:ni
           #:xu

           #:lc
           #:len
           #:leo
           #:vb
           #:vr
           #:zu

           #:rz!
           #:screenshot
           #:xmsg
           #:xrun
           #:xm

           #:ds
           #:sg2e
           #:smb
           #:hk
           #:cel

           #:lw
           #:lwc
           #:xp
           #:sbcl!))

(in-package #:scripts/apps)

(defvar +screenshots-dir+ (mof:home ".screenshots"))

(exporting-definitions
 (% bt "bluetoothctl")
 (% dv "gdrive upload --recursive")
 (% e "emacsclient -nw")
 (% gpg "gpg2")
 (% par "parallel")
 (% pm "pulsemixer")
 (% rz "rsync -rlptgoD -HAX -x -z")
 (% rl "rlwrap -s 1000000 -c -b \"(){}[].,=&^%$#@\\;|\"")
 (% rm@ "shred -vfzun 10")
 (% s "sudo")
 (% us "usync --one-way --prefer-local")
 (% vg "vagrant")
 (% xf "xmllint --format")
 (% zx "zsh -c"))

(exporting-definitions
 (% ae "aegisub")
 (% au "audacity")
 (% av "ahoviewer")
 (% bm "blueman-manager")
 (% cv "guvcview")
 (% dc "Discord")
 (% earth "googleearth")
 (% ev "evince")
 (% fs "gtk2fontsel")
 (% lo "libreoffice")
 (% lx "lxappearance")
 (% mx "len wxmaxima")
 (% p "mpv --mute")
 (% pc "pavucontrol")
 (% pe "pulseeffects")
 (% tx "len urxvt")
 (% ty "terminator")
 (% sm "stellarium")
 (% sp "speedcrunch")
 (% tb "tor-browser")
 (% xb "chromium")
 (% xo "xournal")
 (% xs "simple-scan")
 (% za "zathura"))

(exporting-definitions
 (% bb "brave")
 (% cb "google-chrome-stable")
 (% fb "firefox"))

(exporting-definitions
 ($ b "phototonic")
 ($ ca "calibre")
 ($ demu "dolphin-emu-master")
 ($ eb "ebook-viewer")
 ($ kp "keepassxc")
 ($ kt "krita")
 ($ mb "mumble")
 ($ o "qutebrowser")
 ($ ok "okular")
 ($ qbt "qbittorrent")
 ($ qt4 "qtconfig")
 ($ qt5 "qt5ct")
 ($ qtx "qtox")
 ($ rmd "qt-recordMyDesktop")
 ($ sw "Write")
 ($ td "telegram-desktop")
 ($ vl "vlc -I ncurses --playlist-autostart")
 ($ vbw "VirtualBox --startvm 'Windows\ XP\ (64-bit)'"))

(exporting-definitions
 (@ fcade "/pub/ludoj/emu/fightcade/FightCade.exe")
 (@ ui "uninstaller")
 (@+ ni "Neat Image Standalone/NeatImage.exe")
 (@+ xu "Xenu/Xenu.exe"))

(exporting-definitions
 (defun lc (&rest args) (run-with-locale "C" args))
 (defun len (&rest args) (run-with-locale "en_US.UTF-8" args))
 (defun leo (&rest args) (run-with-locale "eo.utf8" args))
 (defun vb () (run-with-nix-system "VirtualBox"))
 (defun vr () (run-with-docker-x "viber"))
 (defun zu (&rest args) (run-with-libgl-always-software "zoom-us" args)))

(exporting-definitions
 (defun rz! (&rest args)
   (apply-args-1
    'rz args
    :options '("-e" "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"))
   (success))

 (defun screenshot (mode)
   (let* ((dir (uiop:truenamize +screenshots-dir+))
          (file (mof:fmt "~A.png" (local-time:format-timestring nil (local-time:now))))
          (dest (mof:fmt "mv $f ~A" dir))
          (image (mof:fmt "~A~A" dir file)))
     (flet ((scrot (file dest &rest args)
              (run/i `("scrot" ,@args ,file -e ,dest))))
       (match mode
              ((ppcre "(full)") (scrot file dest))
              ((ppcre "(region)") (scrot file dest '-s))
              (_ (err (mof:fmt "invalid mode ~A~%" mode))))
       (run `("xclip" "-selection" "clipboard" "-t" "image/png" ,image))
       (success))))

 (defun xmsg (&rest args)
   (run/i `("xmessage"
            "-fn" "-*-speedy-*-*-*-*-12-*-*-*-*-*-*-*"
            "-fg" "white" "-bg" "black"
            "-timeout" "5" "-buttons" ""
            ,@args))
   (success))

 (defun xrun (&rest args)
   (run/i `("gmrun" "-geometry" "+0+0" ,@args))
   (success))

 (defun xm (&rest args)
   (run/i `("xmonad" "--recompile"))
   (run/i `("xmonad" "--restart"))
   (success))

 (defun ds (&rest args)
   (run `("sudo" "pkill" "-9" "ds4drv") :output :interactive :on-error nil)
   (run `("sudo" "rm" "-f" "/tmp/ds4drv.pid") :output :interactive :on-error nil)
   (run/i `("sudo" "ds4drv" "--daemon" "--config" ,(mof:expand-pathname "~/.config/ds4drv.conf")))
   (success)))

(exporting-definitions
 (% sg2e "steam -applaunch 245170")
 (% smb "steam -applaunch 40800")
 (% hk "steam -applaunch 367520")
 (% cel "steam -applaunch 504230"))

(exporting-definitions
 (defun lw (&rest args)
   (run/i `(zsh "-c" "cr /usr/local/lib/LispWorks/lispworks-7-0-0-x86-linux" ,@args))
   (success))

 (defun lwc (&rest args)
   (run/i `(zsh "-c" "cr /home/pub/hejmo/apoj/lispworks/save-image/lispworks-cli" ,@args))
   (success))

 (defun xp (&rest args)
   (run/i `("VirtualBox" "--startvm" "Windows XP (64-bit)"))
   (success))

 (defun sbcl! (&rest args)
   (let* ((path (mof:cat (xdg-dir "TEMPLATES") "/nix-shell/lisp/"))
          (command (build-command "sbcl" args)))
     (uiop:chdir path)
     (run/i `("baf" "shell" "--run" ,command))
     (success))))

(register-commands :scripts/apps)
