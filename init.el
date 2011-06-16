(setq load-path (cons "~/.emacs.d" load-path))
(add-hook 'shell-mode-hook 'ansi-color-for-comint-mode-on)
(add-hook 'before-save-hook 'delete-trailing-whitespace)

(setq line-number-mode t)
(setq next-line-add-newlines nil)

;; turn word wrap on for split windows
(setq-default truncate-partial-width-windows nil)

;; Add clipboard copy paste at all times
(setq x-select-enable-clipboard t)

(add-to-list 'load-path "~/.emacs.d/haml/extra")
(require 'haml-mode)
(require 'sass-mode)
(require 'ruby-mode)
(require 'inf-ruby)
;loads ruby mode when a .rb file is opened.
(autoload 'ruby-mode "ruby-mode" "Major mode for editing ruby scripts." t)
(setq auto-mode-alist  (cons '(".rb$" . ruby-mode) auto-mode-alist))
(setq auto-mode-alist  (cons '(".rhtml$" . html-mode) auto-mode-alist))
;;(load "~/.emacs.d/nxhtml/autostart.el")

;; remove toolbar
;;(tool-bar-mode -1)

;; remove scrollbar
(scroll-bar-mode -1)

;loads ruby mode when a .rb file is opened.
(autoload 'ruby-mode "ruby-mode" "Major mode for editing ruby scripts." t)
(setq auto-mode-alist  (cons '(".rb$" . ruby-mode) auto-mode-alist))
(setq auto-mode-alist  (cons '(".rhtml$" . html-mode) auto-mode-alist))

(setq indent-tabs-mode nil)

(when (require 'tabbar nil t)
  (setq tabbar-buffer-groups-function (lambda (b) (list "All Buffers")) )
  (tabbar-mode)
  (define-key esc-map [left] 'tabbar-backward)
  (define-key esc-map [right] 'tabbar-backward)
  (global-set-key [(meta left)] 'tabbar-backward)
  (global-set-key [(meta right)] 'tabbar-forward))

;;Select All
(global-set-key [(control a)] 'mark-whole-buffer)

(add-to-list 'load-path "~/.emacs.d/color-theme.el")
(load-file "~/.emacs.d/color-theme-twilight.el")
(require 'color-theme)
;;(color-theme-twilight)
(load-file "~/.emacs.d/color-theme-blackboard.el")
(color-theme-blackboard)

(setq global-font-lock-mode t)

;disable backup
(setq backup-inhibited t)
;disable auto save
(setq auto-save-default nil)

(global-font-lock-mode 1)

(defun fullscreen ()
  (interactive)
  (set-frame-parameter nil 'fullscreen
    (if (frame-parameter nil 'fullscreen) nil 'fullboth)))
(global-set-key [f11] 'fullscreen)

;Disable temp backups
(defvar user-temporary-file-directory
  (concat temporary-file-directory user-login-name "/"))
(make-directory user-temporary-file-directory t)
(setq backup-by-copying t)
(setq backup-directory-alist
      `(("." . ,user-temporary-file-directory)
        (,tramp-file-name-regexp nil)))
(setq auto-save-list-file-prefix
      (concat user-temporary-file-directory ".auto-saves-"))
(setq auto-save-file-name-transforms
      `((".*" ,user-temporary-file-directory t)))

;Cucumber feature stories
(add-to-list 'load-path "~/.emacs.d/feature-mode")
; and load it
(autoload 'feature-mode "feature-mode" "Mode for editing cucumber files" t)
(add-to-list 'auto-mode-alist '("\.feature$" . feature-mode))

;Adding rinari
(add-to-list 'load-path "~/.emacs.d/rinari")
(require 'rinari)

;emacs-rails
(require 'find-recursive)
(require 'snippet)
(require 'ruby-electric)
(setq load-path (cons "~/.emacs.d/emacs-rails" load-path))
(require 'rails)


;cua mode

(global-set-key [(control o)] 'find-file)              ; use Ctrl-o to open a (new) file
(global-set-key [(control n)] 'find-file-other-frame)  ; open a file in a new window with Ctrl-n
(global-set-key [(control s)] 'save-buffer)            ; save with Ctrl-s
(global-set-key [(meta s)]    'write-file)             ; 'save file as...' with Alt-s ('meta' is
                                                       ; just another name for the 'Alt' key)
(global-set-key [(control q)] 'save-buffers-kill-emacs); exit XEmacs with Ctrl-q
(global-set-key [(meta q)]    'kill-this-buffer)       ; delete changes (don't save) with Alt-q

(global-set-key [(control t)] 'ispell-buffer)          ; spell-check with Ctrl-t
(global-set-key [(control r)] 'replace-string)         ; search and replace with Ctrl-r

(require 'redo)                                        ; load the 'redo' package
(global-set-key [(meta z)]    'redo)                   ; 'redo', that is, revert the last 'undo'
(global-set-key [(control z)] 'undo)

; search forward with Ctrl-f
(global-set-key [(control f)] 'isearch-forward)
(define-key isearch-mode-map [(control f)] (lookup-key isearch-mode-map "\C-s"))
(define-key minibuffer-local-isearch-map [(control f)]
  (lookup-key minibuffer-local-isearch-map "\C-s"))

; search backward with Alt-f
(global-set-key [(meta f)] 'isearch-backward)
(define-key isearch-mode-map [(meta f)] (lookup-key isearch-mode-map "\C-r"))
(define-key minibuffer-local-isearch-map [(meta f)]
  (lookup-key minibuffer-local-isearch-map "\C-r"))

(set-face-attribute 'default nil :height 100)
(delete-selection-mode t)
(custom-set-variables
  ;; custom-set-variables was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 )
(custom-set-faces
  ;; custom-set-faces was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 )

  (set-face-attribute
   'tabbar-default-face nil
   :background "gray60")
  (set-face-attribute
   'tabbar-unselected-face nil
   :background "gray85"
   :foreground "gray30"
   :box nil)
  (set-face-attribute
   'tabbar-selected-face nil
   :background "#f2f2f6"
   :foreground "black"
   :box nil)
  (set-face-attribute
   'tabbar-button-face nil
   :box '(:line-width 1 :color "gray72" :style released-button))
  (set-face-attribute
   'tabbar-separator-face nil
   :height 0.7)

  (tabbar-mode 1)
  (define-key global-map [(alt j)] 'tabbar-backward)
  (define-key global-map [(alt k)] 'tabbar-forward)
(setq inhibit-splash-screen t)
