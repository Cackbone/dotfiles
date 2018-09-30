;; Makes *scratch* empty.
(setq initial-scratch-message "")

;; Removes *scratch* from buffer after the mode has been set.
(defun remove-scratch-buffer ()
  (if (get-buffer "*scratch*")
      (kill-buffer "*scratch*")))
(add-hook 'after-change-major-mode-hook 'remove-scratch-buffer)

;; Removes *messages* from the buffer.
(setq-default message-log-max nil)
(kill-buffer "*Messages*")

;; Removes *Completions* from buffer after you've opened a file.
(add-hook 'minibuffer-exit-hook
      '(lambda ()
         (let ((buffer "*Completions*"))
           (and (get-buffer buffer)
                (kill-buffer buffer)))))

;; Don't show *Buffer list* when opening multiple files at the same time.
(setq inhibit-startup-buffer-menu t)

;; Show only one active window when opening multiple files at the same time.
(add-hook 'window-setup-hook 'delete-other-windows)
(menu-bar-mode -1)
(tool-bar-mode -1)
(set-frame-font "Hasklig 12" nil t)

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
 '(inhibit-startup-screen t)
 '(package-selected-packages
   (quote
    (node-resolver lsp-mode doom-modeline less-css-mode markdown-preview-mode markdown-mode envdir js-doc nix-mode web-mode-edit-element dockerfile-mode indium php-mode xref-js2 rainbow-identifiers rainbow-blocks vue-mode company-tern exec-path-from-shell web-mode eslint-fix js2-refactor ac-js2 pug-mode yaml-mode helm-spotify minimap irony-eldoc flycheck-irony flymake-css flymake-php flymake-ruby flymake-rust flymake-sass flymake-yaml flymake-cppcheck flycheck flycheck-clang-analyzer flycheck-clang-tidy flycheck-clangcheck iedit emmet-mode yasnippet-snippets auto-complete-clang-async csharp-mode highlight-context-line rainbow-mode spotlight column-enforce-mode all-the-icons-dired neotree doom-themes realgud el-get multiple-cursors rainbow-delimiters linum-relative simpleclip ac-racer company-racer flycheck-rust rust-mode ac-php irony lsp-rust racer rust-playground 0blayout ac-c-headers ac-clang ac-emmet powerline dracula-theme company-shell company-c-headers company virtualenv jedi avk-emacs-themes)))
 '(scroll-bar-mode nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
(when (not package-archive-contents)
    (package-refresh-contents))

(add-to-list 'package-archives
              '("melpa" . "http://melpa.milkbox.net/packages/") t)

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

;;Prettymode
(require 'pretty-mode)
(global-pretty-mode t)

(pretty-deactivate-groups
 '(:function :logic :nil :equality :greek-capitals :greek-lowercase:sets :sets-operations :sets-relations))


;; WHITESPACES
(require 'whitespace)
(setq whitespace-display-mappings

      '((space-mark   ?\     [?.]     [?.])
        (newline-mark ?\n    [?◀ ?\n])
	(tab-mark     ?\t    [?\u2502 ?\t] [?\\ ?\t])))
(setq whitespace-style '(face trailing tabs newline tab-mark newline-mark))
(set-face-background 'whitespace-tab "#unspecified-bg")
(set-face-foreground 'whitespace-tab "#666698")
(set-face-background 'whitespace-space "unspecified-bg")
(set-face-foreground 'whitespace-space "#111111")
(set-face-background 'whitespace-newline "unspecified-bg")
(set-face-foreground 'whitespace-newline "#666698")
(global-whitespace-mode t)
(add-hook 'before-save-hook 'whitespace-cleanup)

;; END WHITESPACE


;; WEB MODE EMACS
(add-to-list 'load-path "~/emacs.d/emmet-mode")
(require 'emmet-mode)
(add-hook 'sgml-mode-hook 'emmet-mode) ;; Auto-start on any markup modes
(add-hook 'css-mode-hook  'emmet-mode) ;; enable Emmet's css abbreviation.
(add-hook 'html-mode-hook  'emmet-mode) ;; enable html.
(use-package web-mode
    :ensure t
    :config
    (add-to-list 'auto-mode-alist '("\\.html?\\'" . web-mode))
    (add-to-list 'auto-mode-alist '("\\.ejs?\\'" . web-mode))
    (setq web-mode-ac-sources-alist
          '(("css" . (ac-source-css-property))
            ("html" . (ac-source-words-in-buffer ac-source-abbrev))))

(setq web-mode-enable-auto-closing t)
(setq web-mode-enable-auto-quoting t))

(add-hook 'web-mode-hook
      '(lambda()
        (setq indent-tabs-mode nil)))

;; JS MODE
(setq-default indent-tabs-mode nil)
(require 'js2-mode)
(add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))
(add-hook 'js2-mode-hook
      '(lambda()
        (setq indent-tabs-mode nil)))

;; Better imenu
(add-hook 'js2-mode-hook #'js2-imenu-extras-mode)
(require 'js2-refactor)
(require 'xref-js2)

(add-hook 'js2-mode-hook #'js2-refactor-mode)
(js2r-add-keybindings-with-prefix "C-c C-r")
(define-key js2-mode-map (kbd "C-k") #'js2r-kill)

;; js-mode (which js2 is based on) binds "M-." which conflicts with xref, so
;; unbind it.
(define-key js-mode-map (kbd "M-.") nil)

(add-hook 'js2-mode-hook (lambda ()
  (add-hook 'xref-backend-functions #'xref-js2-xref-backend nil t)))

;; use web-mode for .jsx files
(add-to-list 'auto-mode-alist '("\\.jsx$" . web-mode))

;; http://www.flycheck.org/manual/latest/index.html
(require 'flycheck)

;; turn on flychecking globally
(add-hook 'after-init-hook #'global-flycheck-mode)

;; disable jshint since we prefer eslint checking
(setq-default flycheck-disabled-checkers
  (append flycheck-disabled-checkers
    '(javascript-jshint)))

;; use eslint with web-mode for jsx files
(flycheck-add-mode 'javascript-eslint 'web-mode)

;; customize flycheck temp file prefix
(setq-default flycheck-temp-prefix ".flycheck")

;; disable json-jsonlist checking for json files
(setq-default flycheck-disabled-checkers
  (append flycheck-disabled-checkers
    '(json-jsonlist)))

;; https://github.com/purcell/exec-path-from-shell
;; only need exec-path-from-shell on OSX
;; this hopefully sets up path and other vars better
(when (memq window-system '(mac ns))
  (exec-path-from-shell-initialize))

;; use local eslint from node_modules before global
;; http://emacs.stackexchange.com/questions/21205/flycheck-with-file-relative-eslint-executable
(defun my/use-eslint-from-node-modules ()
  (let* ((root (locate-dominating-file
                (or (buffer-file-name) default-directory)
                "node_modules"))
         (eslint (and root
                      (expand-file-name "node_modules/eslint/bin/eslint.js"
                                        root))))
    (when (and eslint (file-executable-p eslint))
      (setq-local flycheck-javascript-eslint-executable eslint))))
(add-hook 'flycheck-mode-hook #'my/use-eslint-from-node-modules)

(add-hook 'js2-mode-hook 'ac-js2-mode)
(setq ac-js2-evaluate-calls t)

;; RACER FOR RUST
(add-hook 'rust-mode-hook #'racer-mode)
(add-hook 'racer-mode-hook #'eldoc-mode)
;;(add-hook 'after-init-hook 'global-company-mode)

(require 'rust-mode)
(define-key rust-mode-map (kbd "TAB") #'company-indent-or-complete-common)
;;(setq company-tooltip-align-annotations t)


;; IRONY MODE FOR CLANG

(add-hook 'after-init-hook #'global-flycheck-mode)

(defun my-irony-mode-hook ()
  (define-key irony-mode-map
      [remap completion-at-point] 'counsel-irony)
  (define-key irony-mode-map
      [remap complete-symbol] 'counsel-irony))
(add-hook 'irony-mode-hook 'my-irony-mode-hook)
(add-hook 'irony-mode-hook 'irony-cdb-autosetup-compile-options)

(with-eval-after-load 'lsp-mode
  (setq lsp-rust-rls-command '("rustup" "run" "nightly" "rls"))
  (require 'lsp-rust))

(with-eval-after-load 'flycheck
  (require 'flycheck-clang-analyzer)
  (flycheck-clang-analyzer-setup))

;;(setq flycheck-check-syntax-automatically '(mode-enabled save))


;; ;; AUTOCOMPLET JS
;; (require 'company)
;; (require 'company-tern)

;; (add-to-list 'company-backends 'company-tern)
;; (add-hook 'js2-mode-hook (lambda ()
;;                            (tern-mode)
;;                            (company-mode)))
;; ;; Disable completion keybindings, as we use xref-js2 instead
;; (define-key tern-mode-keymap (kbd "M-.") nil)
;; (define-key tern-mode-keymap (kbd "M-,") nil)
;; (add-hook 'js2-mode-hook 'ac-js2-mode)
;; (setq ac-js2-evaluate-calls t)



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

(setq irony-additional-clang-options '("-W"
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

(add-hook 'prog-mode-hook #'rainbow-delimiters-mode)

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
(add-hook 'web-mode-hook 'emmet-mode)

;; END AUTOCOMPLETE

;; THEME
(add-to-list 'custom-theme-load-path "~/.emacs.d/themes")

(global-column-enforce-mode t)
(setq column-enforce-comments nil)

(load-theme 'dracula t)


(require 'neotree)
(require 'all-the-icons)

(setq all-the-icons-color-icons 11)

(require 'doom-themes)

(global-set-key [f8] 'neotree-toggle)
(setq neo-theme (if  'icons 'arrow))
(setq neo-theme (if window-system 'icons 'arrow))
(setq inhibit-compacting-font-caches t)
(add-hook 'after-init-hook #'neotree-toggle)

(setq neo-autorefresh 'true)

(setq neo-force-change-root t)

;; Global settings (defaults)
(setq doom-themes-enable-bold t    ; if nil, bold is universally disabled
      doom-themes-enable-italic t) ; if nil, italics is universally disabled

;; Load the theme (doom-one, doom-molokai, etc); keep in mind that each theme
;; may have their own settings.
(load-theme 'doom-one t)

;; LINUM

(require 'linum-relative)
(global-linum-mode t)
(setq linum-format "%4d \u2502 ")
(set-face-attribute 'linum nil :background "unspecified-bg")
(set-face-attribute 'linum nil :foreground "#2196f3")

;; END LINUM




;; Enable flashing mode-line on errors
;; (doom-themes-visual-bell-config)

;; Corrects (and improves) org-mode's native fontification.

(doom-themes-org-config)
(require 'doom-modeline)
(doom-modeline-init)

;; (defun on-after-init ()
;;   (unless (display-graphic-p (selected-frame))
;;     (set-face-background 'default "unspecified-bg" (selected-frame))))

(add-hook 'window-setup-hook 'on-after-init)
;; (set-face-attribute 'region nil :background "unspecified-bg")

(beacon-mode 1)
(setq beacon-color "#88BBFF")


;; END THEME




;; MULTIPLE CURSOR
(define-key global-map (kbd "C-c C-v") 'iedit-mode)

;; POWERLINE
;; (require 'powerline)
;; (powerline-default-theme)

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

