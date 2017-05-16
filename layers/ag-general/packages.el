(setq ag-general-packages '(
                            ;; editorconfig
                            rainbow-mode
                            atomic-chrome
                            page-break-lines
                            helm-pages
                            ))

(setq ag-general-excluded-packages '())

(defun ag-general/init-editorconfig ()
  (use-package editorconfig
    :defer t
    :init
    (editorconfig-mode 1)))

(defun ag-general/init-rainbow-mode ()
  (use-package rainbow-mode
    :defer t
    :init
    (add-hook 'css-mode-hook 'rainbow-mode)))

(defun ag-general/init-atomic-chrome ()
  (use-package atomic-chrome
    ;; :load-path "atomic-chrome/"
    :init
    (atomic-chrome-start-server)
    :config
    (setq atomic-chrome-default-major-mode 'org-mode
          atomic-chrome-enable-bidirectional-edit nil)
    (add-hook 'atomic-chrome-edit-mode-hook #'ag/switch-focus-to-emacs-frame)
    (add-hook 'atomic-chrome-edit-done-hook #'ag/switch-focus-to-chrome)))

(defun ag-general/init-page-break-lines ()
  (use-package page-break-lines
    :defer t
    :init
    (global-page-break-lines-mode 1)))

(defun ag-general/init-helm-pages ()
  (use-package helm-pages
    :defer t))
