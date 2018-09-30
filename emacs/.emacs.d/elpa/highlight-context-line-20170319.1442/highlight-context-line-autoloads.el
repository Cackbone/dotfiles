;;; highlight-context-line-autoloads.el --- automatically extracted autoloads
;;
;;; Code:
(add-to-list 'load-path (directory-file-name (or (file-name-directory #$) (car load-path))))

;;;### (autoloads nil "highlight-context-line" "highlight-context-line.el"
;;;;;;  (23221 10807 350820 186000))
;;; Generated autoloads from highlight-context-line.el

(autoload 'highlight-context-line-mode "highlight-context-line" "\
Toggle highlighting of context line when scrolling.
With a prefix argument ARG, enable the mode if ARG is positive,
and disable it otherwise.  If called from Lisp, enable the mode
if ARG is omitted or nil.

When scrolling a buffer up this minor mode highlights the line
that was at the top of the window before scrolling. When
scrolling down, the bottommost line of the window at start of
scrolling is highlighted. The respective line is considered
the context line.

\(fn &optional ARG)" t nil)

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; End:
;;; highlight-context-line-autoloads.el ends here
