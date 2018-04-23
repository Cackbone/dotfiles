(load "~/.emacs.d/hl-line+.el")

(menu-bar-modfe -1)

;; LOAD MELPA

(require 'package)(let* ((no-ssl (and (memq system-type '(windows-nt ms-dos))
				      (not (gnutls-available-p))))
			 (url (concat (if no-ssl "http" "https") "://melpa.org/packages/")))
		    (add-to-list 'package-archives (cons "melpa" url) t))
(when (< emacs-major-version 24)
  (add-to-list 'package-archives '("gnu" . "http://elpa.gnu.org/packages/")))
(package-initialize)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   (quote
    (yaml-mode helm-spotify minimap irony-eldoc flycheck-irony flymake-css flymake-php flymake-ruby flymake-rust flymake-sass flymake-yaml flymake-cppcheck flycheck flycheck-clang-analyzer flycheck-clang-tidy flycheck-clangcheck iedit emmet-mode yasnippet-snippets auto-complete-clang-async csharp-mode highlight-context-line rainbow-mode spotlight column-enforce-mode all-the-icons-dired neotree doom-themes realgud el-get multiple-cursors rainbow-delimiters linum-relative simpleclip ac-racer company-racer flycheck-rust rust-mode ac-php irony lsp-rust racer rust-playground 0blayout ac-c-headers ac-clang ac-emmet powerline dracula-theme company-shell company-c-headers company virtualenv jedi avk-emacs-themes))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
(when (not package-archive-contents)
    (package-refresh-contents))

;; END LOAD MELPA

;; LOAD ELGET
(add-to-list 'load-path "~/.emacs.d/el-get/el-get")

(unless (require 'el-get nil 'noerror)
  (with-current-buffer
      (url-retrieve-synchronously
       "https://raw.githubusercontent.com/dimitri/el-get/master/el-get-install.el")
    (goto-char (point-max))
    (eval-print-last-sexp)))

(add-to-list 'el-get-recipe-path "~/.emacs.d/el-get-user/recipes")
(el-get 'sync)

;; END LOAD ELGET


;; IRONY MODE FOR CLANG

(add-hook 'after-init-hook #'global-flycheck-mode)

(defun my-irony-mode-hook ()
  (define-key irony-mode-map
      [remap completion-at-point] 'counsel-irony)
  (define-key irony-mode-map
      [remap complete-symbol] 'counsel-irony))
(add-hook 'irony-mode-hook 'my-irony-mode-hook)
(add-hook 'irony-mode-hook 'irony-cdb-autosetup-compile-options)

(with-eval-after-load 'flycheck
  (require 'flycheck-clang-analyzer)
  (flycheck-clang-analyzer-setup))

;;(setq flycheck-check-syntax-automatically '(mode-enabled save))

(setq flycheck-clang-analyzer-executable "clang-6.0")
(flycheck-clang-analyzer-setup)

(eval-after-load 'flycheck
  '(add-hook 'flycheck-mode-hook #'flycheck-irony-setup))

(eval-after-load 'flycheck
  '(progn
     (require 'flycheck-cstyle)
     (flycheck-cstyle-setup)
     ;; chain after cppcheck since this is the last checker in the upstream
     ;; configuration
     (flycheck-add-next-checker 'c/c++-cppcheck '(warning . cstyle))))

(add-hook 'c++-mode-hook 'irony-mode)
(add-hook 'c-mode-hook 'irony-mode)
(add-hook 'objc-mode-hook 'irony-mode)

(add-hook 'irony-mode-hook 'irony-cdb-autosetup-compile-options)

(setq irony-additional-clang-options '("-std=c99"
				       "-include"
				       "-W"
				       "-Wall"
				       "-Werror"
				       "-Wextra"
				       "-I../include"
				       "-Iinclude"))

(setq flycheck-highlighting-mode 'lines)
 (setq flycheck-check-syntax-automatically '(mode-enabled new-line idle-change))
 (setq flycheck-idle-change-delay 1)
 (eval-after-load 'flycheck
     '(progn
       (set-face-attribute 'flycheck-error nil
                           :foreground "red"
			   :underline t
                           )))
 (eval-after-load 'flycheck
     '(progn
       (set-face-attribute 'flycheck-warning nil
                           :foreground "yellow"
                           )))
 (eval-after-load 'flycheck
     '(progn
       (set-face-attribute 'flycheck-info nil
                           :foreground "blue"
                           )))
;; END IRONY MODE FOR CLANG

;; AUTOCOMPLETE

(require 'auto-complete-config)

(require 'auto-complete-clang)

(setq ac-clang-flags
      (mapcar (lambda (item)(concat "-I" item))
	      (split-string
	       "
/usr/lib/gcc/x86_64-pc-linux-gnu/7.3.1/../../../../include/c++/7.3.1
/usr/lib/gcc/x86_64-pc-linux-gnu/7.3.1/../../../../include/c++/7.3.1/x86_64-pc-linux-gnu
/usr/lib/gcc/x86_64-pc-linux-gnu/7.3.1/../../../../include/c++/7.3.1/backward
/usr/lib/gcc/x86_64-pc-linux-gnu/7.3.1/include
/usr/local/include
/usr/lib/gcc/x86_64-pc-linux-gnu/7.3.1/include-fixed
/usr/include
../include
"
	       )))

(defun my:ac-c-headers-init ()
  (require 'auto-complete-c-headers)
  (add-to-list 'ac-sources 'ac-source-c-headers))

(add-hook 'c++-mode-hook 'my:ac-c-headers-init)
(add-hook 'c-mode-hook 'my:ac-c-headers-init)

(setq ac-auto-start nil)
(setq ac-quick-help-delay 0.5)
(ac-set-trigger-key "TAB")
(define-key ac-mode-map  [(control tab)] 'auto-complete)
(define-key ac-mode-map  [(control tab)] 'auto-complete)
(defun my-ac-config ()
  (setq-default ac-sources '(ac-source-abbrev ac-source-dictionary ac-source-words-in-same-mode-buffers))
  (add-hook 'emacs-lisp-mode-hook 'ac-emacs-lisp-mode-setup)
  (add-hook 'c-mode-common-hook 'ac-cc-mode-setup)
  (add-hook 'ruby-mode-hook 'ac-ruby-mode-setup)
  (add-hook 'css-mode-hook 'ac-css-mode-setup)
  (add-hook 'auto-complete-mode-hook 'ac-common-setup)
  (global-auto-complete-mode t))
(defun my-ac-cc-mode-setup ()
  (setq ac-sources (append '(ac-source-clang ac-source-yasnippet) ac-sources)))
(add-hook 'c-mode-common-hook 'my-ac-cc-mode-setup)
; ac-source-gtags
(my-ac-config)

(require 'yasnippet)
(yas-global-mode 1)

(let ((yas-map-entry (assq 'yas-minor-mode minor-mode-map-alist)))
  (setq minor-mode-map-alist
        (cons yas-map-entry
              (delq yas-map-entry minor-mode-map-alist))))

(require 'emmet-mode)
(add-hook 'sgml-mode-hook 'emmet-mode) ;; Auto-start on any markup modes
(add-hook 'css-mode-hook  'emmet-mode) ;; enable Emmet's css abbreviation.

;; END AUTOCOMPLETE

;; THEME

(add-to-list 'custom-theme-load-path "~/.emacs.d/themes")

(load "~/.emacs.d/column-marker.el")

(global-column-enforce-mode t)
(setq column-enforce-comments nil)

(load-theme 'dracula t)


(require 'neotree)
(require 'all-the-icons)

(setq all-the-icons-color-icons nil)

(require 'doom-themes)

(global-set-key [f8] 'neotree-toggle)
;;(setq neo-theme (if (display-graphic-p) 'icons 'arrow))
(setq neo-theme (if window-system 'icons 'arrow))

;; Global settings (defaults)
(setq doom-themes-enable-bold t    ; if nil, bold is universally disabled
      doom-themes-enable-italic t) ; if nil, italics is universally disabled

;; Load the theme (doom-one, doom-molokai, etc); keep in mind that each theme
;; may have their own settings.
(load-theme 'doom-one t)

;; Enable flashing mode-line on errors
(doom-themes-visual-bell-config)

;; Enable custom neotree theme
;(doom-themes-neotree-config)  ; all-the-icons fonts must be installed!

;; Corrects (and improves) org-mode's native fontification.

(doom-themes-org-config)


(set-face-attribute 'region nil :background "#5599FF")

(beacon-mode 1)
(setq beacon-color "#88BBFF")

;; END THEME

;; MULTIPLE CURSOR
(define-key global-map (kbd "C-c C-v") 'iedit-mode)


;; SIMPLECLIP
(require 'simpleclip)
(simpleclip-mode 1)

;; POWERLINE
(require 'powerline)
(powerline-default-theme)

;; WHITESPACES
(require 'whitespace)
(setq whitespace-display-mappings

      '((space-mark   ?\     [?.]     [?.])
        (newline-mark ?\n    [?◀ ?\n])
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

;; END WHITESPACE

;; LINUM

(require 'linum-relative)
(global-linum-mode t)
(setq linum-format "%4d \u2502 ")
(set-face-attribute 'linum nil :background "#000")
(set-face-attribute 'linum nil :foreground "#2196f3")

;; END LINUM

;; JEDI MODE
(add-hook 'python-mode-hook 'jedi:setup)
(setq jedi:complete-on-dot t)


;; ----------------------------------
;;           EPITECH CONFIG
;; ----------------------------------

;; Added by Package..  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
(package-initialize)

(add-to-list 'load-path "~/.emacs.d/lisp")
(load "~/.emacs.d/epitech/std.el")
(load "~/.emacs.d/epitech/std_comment.el")
