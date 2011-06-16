;;; cua-mode.el --- emulate CUA key bindings

;; Copyright (C) 1997,1998 Free Software Foundation, Inc.

;; Author: Kim F. Storm <storm@olicom.dk>
;; Adapted-By: SL Baur <steve@altrasoft.com>
;; Maintainer: SL Baur <steve@altrasoft.com>
;; Keywords: emulations
;; Revision: 1.3
;; Location: ftp://ftp.xemacs.org/pub/xemacs/contrib/cua-mode.el

;; This file is part of XEmacs.

;; XEmacs is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; XEmacs is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with XEmacs; see the file COPYING.  If not, write to the Free
;; Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
;; 02111-1307, USA.

;;; Commentary:

;; This is a version of Kim Storm's cua-mode.el.  The original version is
;; is so heavily dependent on FSF Emacs features that it didn't appear much
;; of a win to try to make it portable.
;; -- sb 26-Aug-1998

;; This is the CUA-mode package which provides a complete emulation of
;; the standard CUA key bindings (Motif/Windows/Mac GUI) for selecting
;; and manipulating the region where S-<movement> is used to
;; highlight & extend the region.
;;
;; This package allows the C-z, C-x, C-c, and C-v keys to be
;; bound appropriately according to the Motif/Windows GUI standard, i.e.
;;	C-z	-> undo
;;	C-x	-> cut
;;	C-c	-> copy
;;	C-v	-> paste
;;
;; The tricky part is the handling of the C-x and C-c keys which
;; are normally used as prefix keys for most of emacs' built-in
;; commands.  With CUA-mode they still perform these functions.
;;
;; Only when the region is currently active (highlighted) do the C-x and C-c
;; keys work as CUA keys.
;; 	C-x -> cut
;; 	C-c -> copy
;; When the region is not active, C-x and C-c works as prefix keys.

;; This has a few drawbacks (such as not being able to copy the region
;; into a register using C-x r x), but CUA-mode can automatically mirror
;; all region commands from the [C-x r] prefix to the [M-r] prefix as
;; well, depending on the setting of `CUA-register-command-prefix'.

;; In the rare cases when you make a mistake and delete the region - you
;; can undo the mistake with C-z.

;; CUA-mode is based on "the best of" pc-selection-mode, s-region, and
;; delete-selection-mode packages with some extra features which I think
;; are unique to this package.

;; It works in a very homogeneous way (via a versatile pre-command-hook)
;; and without rebinding any of the cursor movement or scrolling
;; keys. The interpretation of C-x and C-c as either emacs prefix keys
;; or CUA cut/copy keys is handled via emacs' key-translation-map
;; feature.

;; A few more details:
;; 
;; * Put cua-mode.el in your emacs' site-lisp directory and byte-compile it.
;;   
;; * To activate, place this in your .emacs:
;; 	(CUA-mode t)
;; 
;; * When the region is highlighted, TAB and S-TAB will indent the entire
;;   region by the normal tab-width (or the given prefix arg).
;; 
;; * C-x C-x (exchange point and mark) no longer activates the mark (i.e. 
;;   highlights the region).  I found that to be confusing since the
;;   sequence C-x C-x (exchange once) followed by C-x C-x (change back)
;;   would then cut the region!  To activate the region in this way,
;;   use C-u C-x C-x.
;; 
;; * [delete] will delete (not copy) the highlighted region.
;; 
;; * The highlighted region is automatically deleted if other text is
;;   typed or inserted.
;; 
;; * Use M-r as a prefix for the region commands instead of C-x r.
;;   The original binding of M-r (move-to-window-line) is now on
;;   M-r M-r.

;;; Code:

(defvar CUA-mode nil
  "*Non-nil means CUA emulation mode is enabled.
In CUA mode, shifted movement keys highlight the region.
When a region is highlighted, insertion commands first delete
the region and then insert.")

(defvar CUA-register-command-prefix
  (cond ((featurep 'infodock) nil)
	(t "\M-r"))
  "Remap register commands onto this key prefix.
If set to nil, register commands are not remapped.
Must be set before enabling CUA-mode.")

;;; User functions.

;; Don't ;;;###autoload
;(defun exchange-point-and-mark-nomark (arg)
;  "Exchanges point and mark, but don't activate the mark.
;Activates the mark if a prefix argument is given."
;  (interactive "P")
;  (if arg
;      (setq mark-active t)
;    (exchange-point-and-mark)
;    (setq mark-active nil)))
(defun exchange-point-and-mark-nomark (arg)
  "Exchanges point and mark, but don't activate the mark.
Activates the mark if a prefix argument is given."
  (interactive "_P")
  (if arg
      (zmacs-activate-region)
    (exchange-point-and-mark t)))

;;; Aux functions

(defun CUA-delete-active-region (&optional killp)
  (if killp
      (if (listp killp) 
	  (copy-region-as-kill (point) (mark))
	  (kill-region (point) (mark)))
    (delete-region (point) (mark)))
  ;; (setq mark-active nil)
  ;; (run-hooks 'deactivate-mark-hook)
  (zmacs-deactivate-region)
  t)

(defun CUA-indent-selection (arg backw)
  (message "Indenting...")
  (let ((a (point)) (b (mark)) c amount)
    (if (> a b) (setq c a a b b c))
    (save-excursion
      (goto-char a)
      (beginning-of-line)
      (setq a (point)))
    (if (equal arg '(4))
	(indent-region a b nil)
      (setq amount (if arg (prefix-numeric-value arg) tab-width))
      (indent-rigidly a b (if backw (- amount) amount))))
  ;; (setq deactivate-mark t)
  (setq zmacs-region-stays nil)
)


(defvar CUA-overriding-prefix-keys
  '((?\C-x "\C-x@\C-x" kill-region)
    (?\C-c "\C-x@\C-c" copy-region-as-kill))
  "List of prefix keys which are remapped via key-translation-map.")
					  
(defun CUA-prefix-override (prompt)
  (let (map)
    ;; (if (and mark-active transient-mark-mode 
    (if (and zmacs-region-active-p
	     (= (length (this-command-keys)) 1))
	(setq map (assq last-input-char CUA-overriding-prefix-keys)))
    (if map
	(cadr map)
      (char-to-string last-input-char))))

(defun CUA-pre-hook ()
  "Function run prior to each command to check for special region handling.
If the current command is a movement command and the key is shifted, set or
expand the region." 
  ;; (if (and CUA-mode transient-mark-mode (symbolp this-command))
  (if (and CUA-mode (symbolp this-command))
      (let ((type (get this-command 'CUA))
	    (ro buffer-read-only)
	    (supersede nil))
	(if (eq type 'move)
	    ;; (if (memq 'shift (event-modifiers (aref (this-single-command-keys) 0)))
		;; (and (not mark-active) (set-mark-command nil))
	      ;; (setq mark-active nil))
	    (if (memq 'shift (event-modifiers (aref (this-command-keys) 0)))
		(and (not zmacs-region-active-p) (set-mark-command nil))
	      ;; (message "Region OFF")
	      ;; (zmacs-deactivate-region))
	      )
	  ;; (if mark-active
	  (if zmacs-region-active-p
	      (progn
		(if (not ro)
		    (cond ((eq type 'kill)
			   (CUA-delete-active-region t))
			  ((eq type 'kill-sup)
			   (setq supersede (CUA-delete-active-region t)))
			  ((eq type 'yank)
			   ;; Before a yank command, make sure we don't yank
			   ;; the same region that we are going to delete.
			   ;; That would make yank a no-op.
			   (if (string= (buffer-substring (point) (mark))
					(car kill-ring))
			       (current-kill 1))
			   (CUA-delete-active-region nil))
			  ((eq type 'del-sup)
			   (setq supersede (CUA-delete-active-region nil)))
			  ((eq type 'del)
			   (CUA-delete-active-region nil))
			  ((eq type 'indent)
			   (setq supersede (CUA-indent-selection current-prefix-arg nil)))
			  ((eq type 'back-indent)
			   (setq supersede (CUA-indent-selection current-prefix-arg t)))
			  (t
			   (setq ro t))))
		(if ro ; or not handled above
		    (cond ((eq type 'copy)
			   (CUA-delete-active-region '(t)))
			  ((eq type 'copy-sup)
			   (setq supersede (CUA-delete-active-region '(t)))))))))
	(if supersede
	    ;; (setq this-command '(lambda () (interactive)))))))
	    (setq this-command #'(lambda () (interactive)))))))

(defvar CUA-region-commands
  '((del	; delete current region before command
     ;; self-insert-command self-insert-iso insert-register
     self-insert-command insert-register
     newline-and-indent newline open-line)
    (del-sup	; delete current region and ignore command
     delete-backward-char backward-delete-char-untabify delete-char)
    (kill	; kill region before command
     )
    (kill-sup	; kill region and ignore command
     kill-region)
    (copy	; copy region before command
     )
    (copy-sup	; copy region and ignore command
     copy-region-as-kill)
    (yank	; replace region with element on kill ring
     yank clipboard-yank)
    (indent	; indent all lines in region by same amount
     indent-for-tab-command tab-to-tab-stop c-indent-command)
    (back-indent ; unindent all lines in region by same amount
     back-tab-indent)
))

;(defvar CUA-movement-keys
;  '((forward-char	right)
;    (backward-char	left)
;    (next-line		down)
;    (previous-line	up)
;    (forward-word	C-right)
;    (backward-word	C-left)
;    (end-of-line	end)
;    (beginning-of-line	home)
;    (end-of-buffer	C-end)
;    (beginning-of-buffer C-home)
;    (scroll-up		next)
;    (scroll-down	prior)
;    (forward-paragraph	C-down)
;    (backward-paragraph	C-up)))
(defvar CUA-movement-keys
  '((forward-char	(right))
    (backward-char	(left))
    (next-line		(down))
    (previous-line	(up))
    (forward-word	(control right))
    (backward-word	(control left))
    (end-of-line	(end))
    (beginning-of-line	(home))
    (end-of-buffer	(control end))
    (beginning-of-buffer (control home))
    (scroll-up		(next))
    (scroll-down	(prior))
    (forward-paragraph	(control down))
    (backward-paragraph	(control up))))

;;;###autoload
(defun CUA-mode (arg)
  "Toggle C-z, C-x, C-c, C-v mapping mode.
When ON, C-x and C-c will cut and copy the selection if the selection
is active (i.e. the region is highlighted), and typed text replaces
the active selection.
When OFF, typed text is just inserted at point.
The register commands are remapped to use the [M-r] prefix in
addition to the normal [C-x r] prefix."
  (interactive "P")
  (setq CUA-mode
	(if (null arg) (not CUA-mode)
	  (> (prefix-numeric-value arg) 0)))
  (if CUA-mode
      (CUA-install)
    (CUA-deactivate))
  (if (get 'forward-char 'CUA)
      t
    (let ((list CUA-region-commands) type l)
      (while list
	(setq l (car list)
	      type (car l)
	      l (cdr l)
	      list (cdr list))
	(while l
	  (put (car l) 'CUA type)
	  (setq l (cdr l))))
      (let ((list CUA-movement-keys) cmd l)
	(while list
	  (setq l (car list)
		cmd (car l)
		l (cdr l)
		list (cdr list))
	  (while l
	    (put cmd 'CUA 'move)
	    (define-key global-map (vector (car l)) cmd)
	    ;; (define-key global-map (vector (intern (concat "S-" (symbol-name (car l))))) cmd)
	    (define-key global-map (vector (cons 'shift (car l))) cmd)
	    (setq l (cdr l))))
	))

    ;; Map the C-zxcv keys according to CUA.

    ;; (define-key global-map [?\C-z] 'advertised-undo)
    ;; (define-key global-map [?\C-v] 'yank)
    ;; (define-key ctl-x-map  [?\C-x] 'exchange-point-and-mark-nomark)
    (define-key global-map [(control z)] 'advertised-undo)
    (define-key global-map [(control v)] 'yank)
    (define-key ctl-x-map  [(control x)] 'exchange-point-and-mark-nomark)

    (or key-translation-map
	(setq key-translation-map (make-sparse-keymap)))
    (let ((map CUA-overriding-prefix-keys))
      (while map
	(define-key key-translation-map (vector (nth 0 (car map))) 'CUA-prefix-override)
	(define-key global-map (nth 1 (car map)) (nth 2 (car map)))
	(setq map (cdr map))))

    ;; Compatibility mappings

    ;; (define-key global-map [S-insert]  'yank)
    ;; (define-key global-map [M-insert]  'yank-pop)
    ;; (define-key global-map [C-insert]  'copy-region-as-kill)
    ;; (define-key global-map [S-delete]  'kill-region)
    (define-key global-map [(shift insert)]  'yank)
    (define-key global-map [(meta insert)]  'yank-pop)
    (define-key global-map [(control insert)]  'copy-region-as-kill)
    (define-key global-map [(shift delete)]  'kill-region)

    ;; The following bindings are useful on Sun Type 3 keyboards
    ;; They implement the Get-Delete-Put (copy-cut-paste)
    ;; functions from sunview on the L6, L8 and L10 keys
    ;;  (define-key global-map [f16]  'yank)
    ;;  (define-key global-map [f18]  'copy-region-as-kill)
    ;;  (define-key global-map [f20]  'kill-region)

    ;; The following bindings are from Pete Forman and RMS.
    ;; I have disabled them because I prefer to map my own
    ;; function keys and I don't like M-bs to undo.  ++KFS

    ;;  (global-set-key [f1] 'help)		; KHelp         F1
    ;;  (global-set-key [f6] 'other-window)	; KNextPane     F6
    ;;  (global-set-key [delete] 'delete-char)  ; KDelete       Del
    ;;  (global-set-key [M-backspace] 'undo)	; KUndo         aBS

    ;; (global-set-key [C-delete] 'kill-line)      ; KEraseEndLine cDel

    ;; (define-key global-map [S-tab]     'back-tab-indent)
    (global-set-key [(control delete)] 'kill-line)      ; KEraseEndLine cDel

    (define-key global-map [(shift tab)]     'back-tab-indent)

    ;; (setq transient-mark-mode t)
    ;; (setq mark-even-if-inactive t)
    ;; (setq highlight-nonselected-windows nil)
    (setq zmacs-regions t)

    (if CUA-register-command-prefix
	(let ((org (lookup-key global-map CUA-register-command-prefix)))
	  (global-set-key CUA-register-command-prefix (lookup-key ctl-x-map "r"))
	  (global-set-key (concat CUA-register-command-prefix CUA-register-command-prefix) org)))
))

;;;###autoload
(defun CUA-install ()
  "Enable cua-mode but don't turn it on."
  (interactive)
  (add-hook 'pre-command-hook 'CUA-pre-hook))

(defun CUA-deactivate ()
  "Disable cua-mode and turn it off."
  (interactive)
  (setq CUA-mode nil)
  (remove-hook 'pre-command-hook 'CUA-pre-hook))

(provide 'cua-mode)

;;; cua-mode.el ends here
