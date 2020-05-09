;;;; webcam.lisp

(uiop:define-package #:scripts/webcam
  (:use #:cl
        #:inferior-shell
        #:cl-scripting
        #:scripts/unix
        #:marie))

(in-package #:scripts/webcam)

(defparameter *device*
  "/dev/video0"
  "The default webcam device")

(defparameter *directory-wildcard*
  "/sys/bus/usb/devices/*/product"
  "The pathname wildcard for the USB devices")

(define-constant* +increments+
  10
  "The zoom increments.")

(define-constant* +program+
  "v4l2-ctl"
  "The program name to adjust webcam parameters")

(defun run-command/i (device &rest args)
  (inferior-shell:run/i `(,+program+ "-d" ,device ,@args)))

(defun run-command/ss (device &rest args)
  (inferior-shell:run/ss `(,+program+ "-d" ,device ,@args)))

(defun current-zoom (&optional (device *device*))
  "Return the current zoom settings."
  (let* ((output (run-command/ss device "-C" "zoom_absolute"))
         (value (parse-integer (second (cl-ppcre:split #\space output)))))
    value))

(defun zoom-settings (&optional (device *device*))
  "Return the zoom settings from DEVICE."
  (uiop:split-string
   (first (remove-if-not #'(lambda (line)
                             (search "zoom_absolute" line))
                         (inferior-shell:run/lines
                          `("v4l2-ctl" "-d" ,device "-l"))))
   :separator '(#\space)))

(defun zoom-value (type &optional (device *device*))
  "Return the current absolute zoom value for TYPE."
  (values
   (parse-integer
    (cl-ppcre:regex-replace
     (fmt "~A=(.*)" type)
     (first (remove-if-not #'(lambda (text) (search type text)) (zoom-settings device)))
     "\\1"))))

(defun get-default-zoom (&optional (device *device*))
  "Return the default zoom value."
  (zoom-value "default" device))

(defun get-minimum-zoom (&optional (device *device*))
  "Return the minimum zoom value for DEVICE."
  (zoom-value "min" device))

(defun get-maximum-zoom (&optional (device *device*))
  "Return the maximum zoom value for DEVICE."
  (zoom-value "max" device))

(defun search-device-id (name)
  "Return the device ID of device with NAME."
  (let* ((files (directory *directory-wildcard*))
         (entry (first (remove-if-not #'(lambda (device)
                                          (string-equal name (uiop:read-file-line device)))
                                      files)))
         (strings (remove-if #'empty-string-p
                             (cl-ppcre:split #\/
                                             (directory-namestring
                                              (uiop:native-namestring entry)))))
         (id (last* strings)))
    id))

(defun get-integrated-camera-id ()
  "Return the ID of the integrated camera."
  (search-device-id "Integrated Camera"))

(defun* (enable-integrated-webcam t) ()
  "Enable the integrated webcam."
  (let* ((id (get-integrated-camera-id))
         (fmt (fmt "echo ~A > /sys/bus/usb/drivers/usb/bind" id)))
    (sush fmt)))

(defun* (disable-integrated-webcam t) ()
  "Disable the integrated webcam."
  (let* ((id (get-integrated-camera-id))
         (fmt (fmt "echo ~A > /sys/bus/usb/drivers/usb/unbind" id)))
    (sush fmt)))

(defun* (set-zoom t) (device value)
  "Set a specific zoom value."
  (run-command/i device "-c" (fmt "zoom_absolute=~A" value))
  (current-zoom))

(defun* (reset-zoom t) (&optional (device *device*))
  "Set the zoom to the default vaule."
  (set-zoom device (get-default-zoom))
  (current-zoom))

(defun* (decrease-zoom t) (&optional (device *device*))
  "Decrease the zoom setting."
  (let* ((current (current-zoom))
         (new (- current +increments+))
         (value (if (< new (get-minimum-zoom))
                    (get-minimum-zoom)
                    new)))
    (set-zoom device value)))

(defun* (increase-zoom t) (&optional (device *device*))
  "Decrease the zoom setting."
  (let* ((current (current-zoom))
         (new (+ current +increments+))
         (value (if (> new (get-maximum-zoom))
                    (get-maximum-zoom)
                    new)))
    (set-zoom device value)))

(defun* (minimum-zoom t) (&optional (device *device*))
  "Set the zoom to the lowest setting."
  (set-zoom device (get-minimum-zoom)))

(defun* (maximum-zoom t) (&optional (device *device*))
  "Set the zoom to the highest setting."
  (set-zoom device (get-maximum-zoom)))

(register-commands :scripts/webcam)
