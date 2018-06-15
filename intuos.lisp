;;;; intuos.lisp

(uiop:define-package #:scripts/intuos
    (:use #:cl
          #:fare-utils
          #:inferior-shell
          #:cl-scripting
          #:cl-launch/dispatch
          #:scripts/misc
          #:scripts/unix)
  (:export #:intuos-map
           #:intuos-bind
           #:intuos-mode
           #:intuos-actions
           #:intuos-ring))

(in-package :scripts/intuos)

(defparameter *intuos-led-file*
  (first (directory #P"/sys/bus/usb/devices/*/*/wacom_led/status_led0_select"))
  "The device for controlling the LED states of the ring")

(defparameter *intuos-selector-key*
  "F10"
  "The key to bind the selector key to")

(defun intuos-device-name (type)
  "Return the name of the tablet by type NAME"
  (let* ((lines (inferior-shell:run/lines `(xsetwacom list devices)))
         (device (concatenate 'string "type: " (string-upcase type)))
         (line (first (remove-if-not #'(lambda (line) (search device line :test #'string=))
                                    lines))))
    (cl-ppcre:regex-replace "(^.*Pad pad).*"  line "\\1")))

(defun intuos-pad-name ()
  "Return the pad name of tablet detected"
  (intuos-device-name "pad"))

(defun intuos-ring-status ()
  "Return the current value of the LED file"
  (let ((value (uiop:read-file-form *intuos-led-file*)))
    value))

(exporting-definitions
  (defun intuos-map (name &rest args)
    "Bind a button using xsetwacom"
    (run/i `(xsetwacom "set" ,name ,@args)))

  (defun intuos-bind ()
    "Bind the middle selector key to the default value"
    (let ((name (intuos-pad-name))
          (key (format nil "key ~A" *intuos-selector-key*)))
      (intuos-map name "Button" "1" key)
      (success)))

  (defun intuos-mode (value)
    "Use sudo to set the value of the LED file"
    (let ((command (format nil "echo ~A > ~A" value *intuos-led-file*)))
      (sudo-sh command)))

  (defun intuos-actions (action-1 action-2)
    "Bind actions to the ring"
    (let ((name (intuos-pad-name)))
      (intuos-map name "AbsWheelUp" action-1)
      (intuos-map name "AbsWheelDown" action-2)))

  (defun intuos-ring (&optional mode)
    "Change the behavior of the ring depending on the current LED value"
    (let ((name (intuos-pad-name)))
      (when mode
        (intuos-mode mode))
      (ecase (intuos-ring-status)
        (0 (intuos-actions "button +4" "button +5"))                               ; scroll
        (1 (intuos-actions "key +ctrl - -ctrl" "key +ctrl +shift = -ctrl -shift")) ; zoom
        (2 (intuos-actions "key [" "key ]"))                                       ; brushes
        (3 (intuos-actions "key PgUp" "key PgDn"))))                               ; miscellany
    (success)))

(register-commands :scripts/intuos)
