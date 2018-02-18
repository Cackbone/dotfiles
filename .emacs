(menu-bar-mode -1)
(require 'package)(let* ((no-ssl (and (memq system-type '(windows-nt ms-dos))
				      (not (gnutls-available-p))))
			 (url (concat (if no-ssl "http" "https") "://melpa.org/packages/")))
		    (add-to-list 'package-archives (cons "melpa" url) t))
(when (< emacs-major-version 24)
  (add-to-list 'package-archives '("gnu" . "http://elpa.gnu.org/packages/")))
(package-initialize)(custom-set-variables
		     '(package-selected-packages
		       (quote
			(ac-racer company-racer flycheck-rust rust-mode ac-php irony lsp-rust racer rust-playground 0blayout ac-c-headers ac-clang ac-emmet powerline dracula-theme company-shell company-c-headers company virtualenv jedi avk-emacs-themes))))
(custom-set-faces
 )

(add-to-list 'custom-theme-load-path "~/.emacs.d/themes")
(load-theme 'dracula t)

(require 'powerline)
(powerline-default-theme)

(require 'whitespace)
(setq whitespace-display-mappings
      '((space-mark   ?\     [?·]     [?.])
        (newline-mark ?\n    [?$ ?\n])
	(tab-mark     ?\t    [?\u2502 ?\t] [?\\ ?\t])))
(setq whitespace-style '(face trailing tabs newline tab-mark newline-mark))
(set-face-background 'whitespace-tab "#000")
(set-face-foreground 'whitespace-tab "#666698")
(set-face-background 'whitespace-space "#000")
(set-face-foreground 'whitespace-space "#111111")
(set-face-background 'whitespace-newline "#000")
(set-face-foreground 'whitespace-newline "#666698")
(global-whitespace-mode t)
(add-hook 'before-save-hook 'whitespace-cleanup)

(global-linum-mode t)
(setq linum-format "%4d \u2502 ")
(set-face-attribute 'linum nil :background "#000")
(set-face-attribute 'linum nil :foreground "#2196f3")
(add-hook 'python-mode-hook 'jedi:setup)
(setq jedi:complete-on-dot t)

(require 'company)
(add-hook 'global-init-hook 'global-company-mode)
(add-to-list 'company-backends 'company-c-headers)

(add-hook 'c++-mode-hook 'irony-mode)
(add-hook 'c-mode-hook 'irony-mode)
(add-hook 'objc-mode-hook 'irony-mode)

;; ----------------------------------
;;           EPITECH CONFIG
;; ----------------------------------

;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
(package-initialize)

(add-to-list 'load-path "~/.emacs.d/lisp")
(load "~/.emacs.d/epitech/std.el")
(load "~/.emacs.d/epitech/std_comment.el")
