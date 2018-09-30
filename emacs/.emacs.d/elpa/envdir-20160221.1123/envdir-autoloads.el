;;; envdir-autoloads.el --- automatically extracted autoloads
;;
;;; Code:
(add-to-list 'load-path (directory-file-name (or (file-name-directory #$) (car load-path))))

;;;### (autoloads nil "envdir" "envdir.el" (23383 34570 531171 955000))
;;; Generated autoloads from envdir.el

(autoload 'envdir-set "envdir" "\
Set environment variables from DIRNAME.

\(fn DIRNAME)" t nil)

(autoload 'envdir-unset "envdir" "\
Unset environment variables from last activated directory.

\(fn)" t nil)

(defvar envdir-mode nil "\
Non-nil if Envdir mode is enabled.
See the `envdir-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `envdir-mode'.")

(custom-autoload 'envdir-mode "envdir" nil)

(autoload 'envdir-mode "envdir" "\
Minor mode for envdir interaction.
\\{envdir-mode-map}

\(fn &optional ARG)" t nil)

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; End:
;;; envdir-autoloads.el ends here
