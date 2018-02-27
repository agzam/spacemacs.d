;;; funcs.el --- ag-general layer functions file for Spacemacs.
;;
;; Copyright (c) 2012-2016 Sylvain Benner & Contributors
;;
;; Author: Ag Ibragimov <agzam.ibragimov@gmail.com>
;; URL: https://github.com/agzam/dot-spacemacs
;;
;; This file is not part of GNU Emacs.
;;
;;; License: GPLv3

(defun ag/region-or-word-at-point-str ()
  "Returns string of selected region or word at point"
  (let* ((bds (if (use-region-p)
                  (cons (region-beginning) (region-end))
                (bounds-of-thing-at-point 'word)))
         (p1 (car bds))
         (p2 (cdr bds)))
    (buffer-substring-no-properties p1 p2)))

(defun notify-osx (title message)
  (when (eq system-type 'darwin)
    (call-process (executable-find "terminal-notifier")
                  nil 0 nil
                  "-group" "Emacs"
                  "-title" title
                  "-sender" "org.gnu.Emacs"
                  "-message" message)))

(defun hs-alert (message)
  "shows Hammerspoon's hs.alert popup with a MESSAGE"
  (when (and message (eq system-type 'darwin)) (call-process (executable-find "hs")
                  nil 0 nil
                  "-c"
                  (concat "hs.alert.show(\"" message "\", 1)"))))

(defun ag/atomic-edit-start ()
  (remove-hook 'markdown-mode-hook 'spacemacs/activate-mmm-mode)
  (remove-hook 'markdown-mode-hook 'spacemacs//cleanup-org-tables-on-save))

(defun ag/atomic-edit-done ()
  (kill-new (buffer-string) t)
  (when (eq system-type 'darwin)
    (shell-command "open -a \"Google Chrome\"")))

(defun ag/fix-frame ()
  "Toggle fullscreen off and on. OS X workaround."
  (when (spacemacs/toggle-fullscreen-frame-status)
    (spacemacs/toggle-fullscreen-frame-off)
    (spacemacs/toggle-fullscreen-frame-on)))

(defun ag/move-frame-one-display (direction)
  "Moves current frame to a monitor at given DIRECTION

DIRECTION - can be North, South, West, East"
  (when (eq system-type 'darwin)
    (let* ((hs (executable-find "hs"))
           (cmd (concat "hs.window.focusedWindow():moveOneScreen" direction "()")))
      (call-process hs nil 0 nil "-c" cmd)
      (ag/fix-frame))))

(spacemacs|define-transient-state zoom-frm
  :title "Zoom Frame Transient State"
  :doc "
 Zoom^^^^^^              Move^^^^^              Other^^
 ────^^^^^^───────────── ────^^^^^^───────────── ─────^^──────────
 [_+_/_=_/_j_] in        [_p_] prev. display [_f_]^^^ fullscreen
 [_-_/_k_]^^   out       [_n_] next display  [_m_]^^^ max-frame
 [_0_]^^^^   reset                         [_q_]^^^ quit
"

  :bindings
  ("+" zoom-frm-in)
  ("=" zoom-frm-in)
  ("j" zoom-frm-in)
  ("-" zoom-frm-out)
  ("k" zoom-frm-out)
  ("0" zoom-frm-unzoom)
  ("f" (spacemacs/toggle-frame-fullscreen-non-native))
  ("m" (spacemacs/toggle-maximize-frame))
  ("n" (ag/move-frame-one-display "North"))
  ("p" (ag/move-frame-one-display "South"))
  ("q" nil :exit t))

;; remove visual marks overlay after marks are deleted
(advice-add 'evil-delete-marks :after (lambda (&rest args) (evil-visual-mark-render)))

(defun ag/switch-to-app (pid)
  "Using third party tools tries to switch to the app with the given PID"
  (when (and pid (eq system-type 'darwin))
    (call-process (executable-find "hs") nil 0 nil "-c"
                  (concat "require(\"emacs\").switchToApp (\"" pid "\")"))))

(defun get-branch-at-point ()
  (interactive)
  (let ((b (magit-branch-at-point)))
    (kill-new b)
    (message b)))

(defvar ag/edit-with-emacs-mode-map
  (let ((map (make-keymap)))
    (define-key map (kbd "C-c C-c") 'ag/finish-edit-with-emacs)
    (define-key map (kbd "C-c k") 'ag/cancel-edit-with-emacs)
    map))

(define-minor-mode ag/edit-with-emacs-mode
  "Minor mode enabled on buffers opened by ag/edit-by-emacs"
  :init-value nil
  :lighter " editwithemacs"
  :keymap ag/edit-with-emacs-mode-map)

(defvar systemwide-edit-previous-app-pid nil
  "Last app that invokes `ag/edit-with-emacs'.")

(defun ag/edit-with-emacs (&optional pid title)
  "
PID is a pid of the app (the caller is responsible to set that right)
TITLE is a title of the window (the caller is responsible to set that right) "
  (setq systemwide-edit-previous-app-pid pid)
  (select-frame-by-name "edit")
  (set-frame-position nil 400 400)
  (set-frame-size nil 600 300 t)
  (let ((buffer (get-buffer-create (concat "*edit-with-emacs " title " *"))))
    (set-buffer-major-mode buffer)
    (with-current-buffer buffer
      (spacemacs/copy-clipboard-to-whole-buffer)
      (spacemacs/evil-search-clear-highlight)
      (delete-other-windows)
      (text-mode)
      (spacemacs/toggle-visual-line-navigation-on)
      (ag/edit-with-emacs-mode 1)
      (evil-insert 1))
    (switch-to-buffer buffer)))

(defun ag/finish-edit-with-emacs ()
  (interactive)
  (spacemacs/copy-whole-buffer-to-clipboard)
  (kill-buffer)
  (delete-frame)
  (call-process (executable-find "hs") nil 0 nil "-c"
                (concat "require(\"emacs\").switchToAppAndPasteFromClipboard (\"" systemwide-edit-previous-app-pid "\")"))
  (setq systemwide-edit-previous-app-pid nil))

(defun ag/cancel-edit-with-emacs ()
  (interactive)
  (kill-buffer)
  (delete-frame)
  (ag/switch-to-app systemwide-edit-previous-app-pid)
  (setq systemwide-edit-previous-app-pid nil))

;;; funcs.el ends here
