(use-package! cape
  :config
  (map! (:prefix "C-c f"
             :i "p" #'completion-at-point
             :i "d" #'cape-dabbrev
             :i "f" #'cape-file
             :i "k" #'cape-keyword
             :i "i" #'cape-ispell
             :i "s" #'cape-symbol
             :i "t" #'cape-tex))
  :init
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-keyword))

(use-package! corfu
  :bind (:map corfu-map
         ("<escape>" . corfu-quit)
         ("C-l" . corfu-insert)
         ("C-j" . corfu-next)
         ("C-k" . corfu-previous))
  :config
  (setq corfu-cycle t
        corfu-auto t
        corfu-auto-prefix 2
        corfu-auto-delay 0.01
        corfu-separator ?\s
        corfu-quit-at-boundary nil
        corfu-quit-no-match t
        corfu-preview-current nil
        corfu-preselect-first t
        corfu-on-exact-match nil
        corfu-echo-documentation t
        corfu-scroll-margin 10)
  (advice-add 'corfu--setup :after 'evil-normalize-keymaps)
  (advice-add 'corfu--teardown :after 'evil-normalize-keymaps)
  (evil-make-overriding-map corfu-map)
  (map! :i "C-e" #'completion-at-point)
  :init
  (corfu-global-mode +1)
  (corfu-doc-mode +1))

(after! evil-org
  (map! (:map evil-org-mode-map
         :i "C-j" nil
         :i "C-k" nil
         :i "C-;" nil
         :i "C-l" nil
         :i "<return>" nil
         :i "RET" nil)))

(use-package! corfu-doc
  :bind (:map corfu-map
         ("C-;" . corfu-doc-toggle)
         ("C-n" . corfu-doc-scroll-down)
         ("C-p" . corfu-doc-scroll-up))
  :config
  (setq corfu-doc-delay 0.2
        corfu-doc-max-width 80
        corfu-doc-max-height 40)
  :init
  (corfu-doc-mode +1))

(use-package! kind-icon
  :after corfu
  :custom
  (kind-icon-default-face 'corfu-default) ; to compute blended backgrounds correctly
  :config
  (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter))

(defvar fancy-splash-image-template
  (expand-file-name "emacs-e-template.svg" doom-private-dir)
  "Default template svg used for the splash image, with substitutions from ")

(defvar fancy-splash-sizes
  `((:height 300 :min-height 50 :padding (0 . 2))
    (:height 250 :min-height 42 :padding (2 . 4))



    (:height 200 :min-height 35 :padding (3 . 3))
    (:height 150 :min-height 28 :padding (3 . 3))
    (:height 100 :min-height 20 :padding (2 . 2))
    (:height 75  :min-height 15 :padding (2 . 1))
    (:height 50  :min-height 10 :padding (1 . 0))
    (:height 1   :min-height 0  :padding (0 . 0)))
  "list of plists with the following properties
  :height the height of the image
  :min-height minimum `frame-height' for image
  :padding `+doom-dashboard-banner-padding' (top . bottom) to apply
  :template non-default template file
  :file file to use instead of template")

(defvar fancy-splash-template-colours
  '(("$colour1" . fg) ("$colour2" . type) ("$colour3" . base5) ("$colour4" . base8))
  "list of colour-replacement alists of the form (\"$placeholder\" . 'theme-colour) which applied the template")

(unless (file-exists-p (expand-file-name "theme-splashes" doom-cache-dir))
  (make-directory (expand-file-name "theme-splashes" doom-cache-dir) t))

(defun fancy-splash-filename (theme-name height)
  (expand-file-name (concat (file-name-as-directory "theme-splashes")
                            theme-name
                            "-" (number-to-string height) ".svg")
                    doom-cache-dir))

(defun fancy-splash-clear-cache ()
  "Delete all cached fancy splash images"
  (interactive)
  (delete-directory (expand-file-name "theme-splashes" doom-cache-dir) t)
  (message "Cache cleared!"))

(defun fancy-splash-generate-image (template height)
  "Read TEMPLATE and create an image if HEIGHT with colour substitutions as
   described by `fancy-splash-template-colours' for the current theme"
  (with-temp-buffer
    (insert-file-contents template)
    (re-search-forward "$height" nil t)
    (replace-match (number-to-string height) nil nil)
    (dolist (substitution fancy-splash-template-colours)
      (goto-char (point-min))
      (while (re-search-forward (car substitution) nil t)
        (replace-match (doom-color (cdr substitution)) nil nil)))
    (write-region nil nil
                  (fancy-splash-filename (symbol-name doom-theme) height) nil nil)))

(defun fancy-splash-generate-images ()
  "Perform `fancy-splash-generate-image' in bulk"
  (dolist (size fancy-splash-sizes)
    (unless (plist-get size :file)
      (fancy-splash-generate-image (or (plist-get size :template)
                                       fancy-splash-image-template)
                                   (plist-get size :height)))))

(defun ensure-theme-splash-images-exist (&optional height)
  (unless (file-exists-p (fancy-splash-filename
                          (symbol-name doom-theme)
                          (or height
                              (plist-get (car fancy-splash-sizes) :height))))
    (fancy-splash-generate-images)))

(defun get-appropriate-splash ()
  (let ((height (frame-height)))
    (cl-some (lambda (size) (when (>= height (plist-get size :min-height)) size))
             fancy-splash-sizes)))

(setq fancy-splash-last-size nil)
(setq fancy-splash-last-theme nil)
(defun set-appropriate-splash (&rest _)
  (let ((appropriate-image (get-appropriate-splash)))
    (unless (and (equal appropriate-image fancy-splash-last-size)
                 (equal doom-theme fancy-splash-last-theme)))
    (unless (plist-get appropriate-image :file)
      (ensure-theme-splash-images-exist (plist-get appropriate-image :height)))
    (setq fancy-splash-image
          (or (plist-get appropriate-image :file)
              (fancy-splash-filename (symbol-name doom-theme) (plist-get appropriate-image :height))))
    (setq +doom-dashboard-banner-padding (plist-get appropriate-image :padding))
    (setq fancy-splash-last-size appropriate-image)
    (setq fancy-splash-last-theme doom-theme)
    (+doom-dashboard-reload)))

(setq doom-fallback-buffer-name "► Doom"
      +doom-dashboard-name "► Doom")

(add-hook 'window-size-change-functions #'set-appropriate-splash)
(add-hook 'doom-load-theme-hook #'set-appropriate-splash)
(remove-hook '+doom-dashboard-functions #'doom-dashboard-widget-shortmenu)
(remove-hook '+doom-dashboard-functions #'doom-dashboard-widget-footer)
(setq-hook! '+doom-dashboard-mode-hook evil-normal-state-cursor (list nil))

(map! :leader
      :desc "Dired"
      "d d" #'dired
      :leader
      :desc "Dired jump to current"
      "d j" #'dired-jump)

(after! dired
  (evil-define-key 'normal dired-mode-map
    (kbd "h")   'dired-single-up-directory
    (kbd "l")   'dired-single-buffer
    (kbd "RET") 'dired-open-file
    (kbd "H")   'dired-hide-dotfiles-mode))

(setq
 dired-open-extensions
 '(("gif" . "nsxiv -a")
   ("jpg" . "nsxiv")
   ("png" . "nsxiv")
   ("mkv" . "mpv")
   ("mp4" . "mpv"))
 delete-by-moving-to-trash t)

(setq eros-eval-result-prefix "==> ")

(map! :leader
      :desc "evaluate whole buffer"
      "e b" #'eval-buffer
      :leader
      :desc "evaluate a region"
      "e r" #'eval-region
      :leader
      :desc "evaluate defun"
      "e d" #'eval-defun
      :leader
      :desc "evaluate expression before point"
      "e l" #'eval-last-sexp)

(require 'elfeed-goodies)
(elfeed-goodies/setup)
(setq elfeed-goodies/entry-pane-size 0.7)

(setq elfeed-feeds '(("https://www.reddit.com/r/linux/new.rss" linux reddit)
                    ("https://www.reddit.com/r/linuxmasterrace/new/.rss" linuxmasterrace reddit memes)
                    ("https://blog.tecosaur.com/tmio/rss.xml" org emacs)
                    ("https://www.reddit.com/r/emacs/new.rss" emacs reddit editor)
                    ("https://www.reddit.com/r/neovim/new.rss" vim reddit editor)
                    ("https://www.reddit.com/r/cubers/new.rss" cubing)
                    ("https://www.reddit.com/r/simracing/new.rss" simracing)
                    ("https://www.reddit.com/r/wallstreetbets/new.rss" retards)))

(map! :leader
      :desc "Launch elfeed"
      "e f" #'elfeed
      :leader
      :desc "Update rss feeds"
      "e u" #'elfeed-update)

(map! :mnv "k"   #'evil-previous-visual-line
      :mnv "j"   #'evil-next-visual-line
      :mnv "gk"  #'evil-previous-line
      :mnv "gj"  #'evil-next-line
      :mnv "h"   #'evil-backward-char
      :mnv "l"   #'evil-forward-char)

(map! :i "C-SPC" #'just-one-space)

(after! evil-escape
  (setq evil-escape-excluded-major-modes nil
        evil-escape-excluded-states nil
        evil-escape-inhibit-functions nil))

(after! evil (setq evil-ex-substitute-global t))

(use-package! smart-semicolon
  :defer t
  :hook (c-mode . smart-semicolon-mode)
  :config
  (setq smart-semicolon-block-chars '(32 59)))

(set-default 'truncate-lines t)

(setq
 truncate-lines t
 truncate-partial-width-windows t)

(setq undo-limit 80000000)

(setq sentence-end-double-space nil)

(setq emojify-emoji-set "twemoji-v2")

(defvar emojify-disabled-emojis
  '("◼" "☑" "☸" "⚙" "⏩" "⏪" "⬆" "⬇" "❓" "✔" "▶" "◀"))

(defadvice! emojify-delete-from-data ()
  :after #'emojify-set-emoji-data
  (dolist (emoji emojify-disabled-emojis)
    (remhash emoji emojify-emojis)))

(set-file-template! "/LICEN[CS]E$" :trigger '+file-templates/insert-license)

(setq doom-font (font-spec :family "mononoki Nerd Font Mono" :size 13)
      doom-big-font (font-spec :family "mononoki Nerd Font Mono" :size 16)
      doom-serif-font (font-spec :family "mononoki Nerd Font Mono" :size 13)
      doom-unicode-font (font-spec :family "JoyPixels"))

(after! doom-themes
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t))

(custom-set-faces!
  '(font-lock-comment-face :inherit 'italic)
  '(font-lock-keyword-face :inherit 'italic)
  '(font-lock-type-face :inherit 'bold)
  '(org-document-title :foreground "#ffcb6b" :height 1.7 :inherit 'italic)
  '(org-document-info-keyword :foreground "#c792ea" :height 1.4)
  '(org-document-info :height 1.5 :inherit 'italic)
  '(org-date :foreground "#ffcb6b" :height 1.2 :inherit 'italic)
  '(org-block-begin-line :foreground "#82aaff" :background "#232635" :height 1.1 :inherit 'italic :extend t)
  '(org-block-end-line :foreground "#82aaff" :background nil :height 1.1 :inherit 'italic)
  '(org-tag :foreground "#8d92af" :height 0.7)
  '(calendar-weekday-header :foreground "#c792ea"))

(add-to-list 'default-frame-alist '(alpha . (100 . 100)))

(setq frame-title-format '("%b@" (:eval (or (file-remote-p default-directory 'host) system-name)) " — Emacs"))

(setq
 comp-deferred-compilation t
 comp-async-report-warnings-errors nil
 comp-always-compile t)

(map! :i
      "C-;" #'up-list)

(defhydra hd-consult (:exit t
                      :hint nil)
"

 _i_: consult imenu   _a_: consult org agenda   _b_: consult buffer other window
 _t_: consult theme   _d_: consult ma           _B_: consult buffer other frame
                    _f_: consult set font     _m_: consult minor mode menu
                    _h_: affe grep
                    _j_: consul org heading
                    _k_: consul buffer
                    _l_: consult line
                    _;_: affe find
                    _'_: consult find
--------------------------------------------------------------------------------------
 _q_: quit
"
  ("i" consult-imenu)
  ("t" consult-theme)
  ("a" consult-org-agenda)
  ("d" consult-man)
  ("f" consult-set-font)
  ("h" affe-grep)
  ("j" consult-org-heading)
  ("k" consult-buffer)
  ("l" consult-line)
  (";" affe-find)
  ("'" consult-find)
  ("m" consult-minor-mode-menu)
  ("b" consult-buffer-other-window)
  ("B" consult-buffer-other-frame)
  ("q" nil))

(defhydra hd-splits (:timeout 2
                     :hint nil)
"
 ^Windows^
---------------------
 _h_: decrease width
 _k_: decrease height
 _j_: increase height
 _l_: increase width
 _=_: balance windows
---------------------
 _q_: quit
"
  ("h" evil-window-decrease-width)
  ("l" evil-window-increase-width)
  ("k" evil-window-decrease-height)
  ("j" evil-window-increase-height)
  ("=" balance-windows)
  ("q" nil))

(map! :leader
      :desc "Consult functions"
      "k" #'hd-consult/body
      :leader
      :desc "Resize windows"
      "j" #'hd-splits/body)

(setq display-line-numbers-type 'relative)

(setq
 doom-modeline-height 23
 doom-modeline-bar-width 3
 doom-modeline-major-mode-icon t
 doom-modeline-enable-word-count t
 doom-modeline-buffer-file-name-style 'truncate-except-project
 all-the-icons-scale-factor 1)
(defun doom-modeline-conditional-buffer-encoding ()
  (setq-local doom-modeline-buffer-encoding
              (unless (or (eq buffer-file-coding-system 'utf-8-unix)
                          (eq buffer-file-coding-system 'utf-8)))))
(add-hook 'after-change-major-mode-hook #'doom-modeline-conditional-buffer-encoding)

(after! doom-modeline
  (doom-modeline-def-modeline 'main
    '(bar matches modals window-number buffer-info remote-host buffer-position word-count selection-info parrot)
    '(irc misc-info input-method buffer-encoding major-mode lsp process vcs checker "  ")))

(setq
 org-agenda-files '("~/my-stuff/Org/Agenda/")
 org-agenda-skip-scheduled-if-done t
 org-agenda-skip-deadline-if-done t
 org-agenda-include-deadlines t
 org-agenda-start-with-log-mode t
 org-agenda-align-tags-to-column 48
 org-agenda-time-leading-zero t
 org-agenda-skip-timestamp-if-done t
 org-agenda-custom-commands
 '(("o" "Overview"
    ((agenda "" (
                 (org-agenda-prefix-format " %?-12t% s")
                 (org-agenda-span 'week)
                 (org-agenda-start-day "-1d")
                 (org-agenda-overriding-header "⚡ This week")
                 (org-agenda-current-time-string "<----------- Now")
                 (org-agenda-scheduled-leaders '("SCHEDULED: " "Scheduled: "))
                 (org-agenda-deadline-leaders '("DEADLINE: " "Deadline: "))
                 (org-agenda-sorting-strategy '(priority-up))))
     (todo "" (
               (org-agenda-overriding-header "\n⚡ Today")
               (org-agenda-skip-timestamp-if-done t)
               (org-agenda-prefix-format " %?-12t% s")
               (org-agenda-span 'day)
               (org-agenda-start-day "+0d")
               (org-agenda-sorting-strategy '(priority-up))))
     (tags-todo "+PRIORITY=\"A\"" (
                                   (org-agenda-overriding-header "\n⚡ High priority")
                                   (org-agenda-skip-timestamp-if-done t)
                                   (org-agenda-prefix-format " %?-12t% s")))
     (tags-todo "+Effort<=20&+Effort>0" (
                                        (org-agenda-overriding-header "\n⚡ Low effort")
                                        (org-agenda-skip-timestamp-if-done t)
                                        (org-agenda-prefix-format " %?-12t% s")
                                        (org-agenda-sorting-strategy '(priority-up))
                                        (org-agenda-max-todos 10)))
     (todo "TODO" (
                   (org-agenda-overriding-header "\n⚡ To Do")
                   (org-agenda-skip-timestamp-if-done t)
                   (org-agenda-prefix-format " %?-12t% s")
                   (org-agenda-sorting-strategy '(priority-up))))
     (todo "PROJ" (
                   (org-agenda-overriding-header "\n⚡ Projects")
                   (org-agenda-skip-timestamp-if-done t)
                   (org-agenda-prefix-format " %?-12t% s")
                   (org-agenda-sorting-strategy '(priority-up))))))))

(use-package! org-appear
  :hook (org-mode . org-appear-mode)
  :config
  (setq org-appear-autolinks t
        org-appear-autosubmarkers t
        org-appear-autoemphasis t
        org-appear-autoentities t)
  (add-hook! 'org-appear-mode-hook
    ;; for proper first-time setup, `org-appear--set-elements' needs to
    ;; be run after other hooks have acted.
    (org-appear--set-elements)
    (add-hook! evil-insert-state-entry :local (org-appear-mode 1))
    (add-hook! evil-insert-state-exit :local (org-appear-mode -1))))

(use-package! org-autolist
  :defer t
  :hook (org-mode . org-autolist-mode))

(use-package! org-auto-tangle
  :defer t
  :hook (org-mode . org-auto-tangle-mode)
  :config
  (setq org-auto-tangle-default t))

(after! org
  (setq org-capture-templates
        `(("t" "Todo")
          ("ti" "Important" entry (file+olp "~/my-stuff/Org/Agenda/Inbox.org" "Important")
           "* TODO %?\n%U")
          ("tt" "Today" entry (file+olp "~/my-stuff/Org/Agenda/Inbox.org" "Today")
           "* TODO %?\n%U")
          ("tl" "Later" entry (file+olp "~/my-stuff/Org/Agenda/Inbox.org" "Later")
           "* TODO %?\n%U")
          ("c" "Contacts" entry (file "~/my-stuff/Org/Agenda/Birthdays.org")
           "* %^{Name} %^G
:PROPERTIES:
:ADDRESS: %^{Address}
:PHONE: %^{Phone number}
:BIRTHDAY: %^{Birthday: yyyy-mm-dd}
:EMAIL: %^{Email}
:NOTE: %^{Note}
:END:")
)))

(setq org-contacts-files '("/home/m3/my-stuff/Org/Agenda/Birthdays.org"))

(setq org-export-with-tags nil)

(use-package! org-fragtog
  :hook
  (org-mode . org-fragtog-mode)
  :config
  (setq org-startup-with-latex-preview t))

(setq org-habit-graph-column 60)

(map! :leader
      :desc "Eval calculations in org doc"
      "o c" #'literate-calc-eval-buffer
      :leader
      :desc "Eval calculation on selected line"
      "o l" #'literate-calc-eval-line
      :leader
      :desc "Counsel org capture"
      "n n" #'org-capture)

(defun or/org-insert-link-dwim ()
  "Like `org-insert-link' but with personal dwim preferences."
  (interactive)
  (let* ((point-in-link (org-in-regexp org-link-any-re 1))
         (clipboard-url (when (string-match-p "^http" (current-kill 0))
                          (current-kill 0)))
         (region-content (when (doom-region-active-p)
                           (buffer-substring-no-properties (doom-region-beginning)
                                                           (doom-region-end)))))
    (cond ((and region-content clipboard-url (not point-in-link))
           (delete-region (doom-region-beginning) (doom-region-end))
           (insert (org-make-link-string clipboard-url region-content)))
          ((and clipboard-url (not point-in-link))
           (insert (org-make-link-string
                    clipboard-url
                    (read-string "title: "
                                 (with-current-buffer (url-retrieve-synchronously clipboard-url)
                                   (dom-text (car
                                              (dom-by-tag (libxml-parse-html-region
                                                           (point-min)
                                                           (point-max))
                                                          'title))))))))
          (t
           (call-interactively 'org-insert-link)))))

(defun or/insert-link ()
  "Insert a link after calling this command twice with the same key."
  (interactive)
  (cond
   ((and (eq last-command #'or/insert-link)
         (eq (char-before) last-command-event))
    (delete-char -1)
    (call-interactively #'or/org-insert-link-dwim))
   (t (insert (string last-command-event)))))

(map! :after org
      :map org-mode-map
      :i "[" #'or/insert-link
      :leader
      "l l" #'or/org-insert-link-dwim)

(setq
 org-log-done 'time
 org-log-into-drawer t)

(setq
 org-ellipsis " ⬎ "
 org-list-allow-alphabetical t
 org-hide-emphasis-markers t)

(add-to-list 'org-modules 'org-habit)
(add-to-list 'org-modules 'org-contacts)
(add-to-list 'org-modules 'org-checklist)
(add-to-list 'org-modules 'org-drill)

(use-package! org-ol-tree
  :config
  (map! :map org-mode-map
        :localleader
        "O" #'org-ol-tree))

(setq org-directory "~/my-stuff/Org/")

(setq
 org-priority-lowest ?D
 org-priority-highest ?A
 org-priority-faces
 '((?A . error)
   (?B . warning)
   (?C . success)
   (?D . outline-4)))

(after! org-fancy-priorities
  (setq org-fancy-priorities-list '("⚡" "⬆" "⬇" "☕")))

(setq org-agenda-property-position 'next-line)

(after! org
  (setq org-refile-targets '(("~/my-stuff/Org/Archive.org" :maxlevel . 4))))

(advice-add 'org-refile :after 'org-save-all-org-buffers)

(add-hook 'org-mode-hook #'+org-pretty-mode)

(after! org
  (setq
   org-startup-folded 'content
   org-startup-with-inline-images t))

(use-package! org-table-sticky-header
  :defer t
  :hook (org-mode . org-table-sticky-header-mode))

(require 'ob-shell)

(after! org-superstar
  (setq
   org-superstar-headline-bullets-list '("⬢" "⬡" "◆" "◈" "◇" "●" "◉" "○" "✹" "✿" "✤" "✜")
   org-superstar-remove-leading-stars t
   org-superstar-special-todo-items t
   org-superstar-todo-bullet-alist
   '(("TODO"      . ?)
     ("NEXT"      . ?)
     ("PROJ"      . ?)
     ("WAIT"      . ?)
     ("CANCELLED" . ?)
     ("DONE"      . ?))
   org-superstar-item-bullet-alist
   '((?- . ?•)
     (?+ . ?➤))))

(setq org-tag-alist
      '((:startgrouptag)
        ("TOC"      . ?T)
        (:endgrouptag)
        (:startgrouptag)
        ("@school"  . ?s)
        ("exam"     . ?t)
        (:endgrouptag)
        (:startgrouptag)
        ("@home"    . ?h)
        ("homework" . ?H)
        (:endgrouptag)
        (:startgrouptag)
        ("@outside" . ?o)
        ("english"  . ?e)
        (:endgrouptag)))

(after! org
  (setq
   org-todo-keywords
   '((sequence
      "TODO(t)"
      "NEXT(n)"
      "PROJ(p)"
      "|"
      "WAIT(w)"
      "DONE(d)"
      "CANCELLED(c)"))
   org-todo-keyword-faces
   '(("TODO"      . (:foreground "#f78c6c" :inherit 'bold))
     ("NEXT"      . (:foreground "#ff5370" :inherit 'bold :height 1.15))
     ("PROJ"      . (:foreground "#5fafff" :inherit 'bold))
     ("WAIT"      . (:foreground "#eeffff" :inherit 'bold))
     ("DONE"      . (:foreground "#c3e88d" :inherit 'bold :box "#c3e88d"))
     ("CANCELLED" . (:foreground "#717cb4" :inherit 'bold :strike-through t)))))

(defun org-to-lower ()
  "Convert all #+KEYWORDS to #+keywords."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (let ((count 0)
          (case-fold-search nil))
      (while (re-search-forward "^[ \t]*#\\+[A-Z_]+" nil t)
        (unless (s-matches-p "RESULTS" (match-string 0))
          (replace-match (downcase (match-string 0)) t)
          (setq count (1+ count))))
      (message "Replaced %d occurances" count))))

(custom-set-faces
  '(org-level-1 ((t (:inherit outline-1 :height 1.5))))
  '(org-level-2 ((t (:inherit outline-2 :height 1.4))))
  '(org-level-3 ((t (:inherit outline-3 :height 1.3))))
  '(org-level-4 ((t (:inherit outline-4 :height 1.2))))
  '(org-level-5 ((t (:inherit outline-5 :height 1.1))))
  '(org-level-6 ((t (:inherit outline-6 :height 1.0)))))

(toc-org-mode)
(setq toc-org-max-depth 4)

(use-package! org-inline-pdf
  :config
  (add-hook 'org-mode-hook #'org-inline-pdf-mode))

(map! :leader
      "m D" #'org-display-inline-images)

(setq deft-directory "~/my-stuff/Org/")

(setq
 org-roam-directory "~/my-stuff/Org/Roam"
 org-roam-completion-everywhere t
 +org-roam-open-buffer-on-find-file nil)

(setq org-roam-dailies-directory "Journal/")

(setq org-roam-capture-templates
      '(("d" "default" plain "%?"
         :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+date: %U\n")
         :unnarrowed t))
      org-roam-dailies-capture-templates
      '(("d" "default" entry "* %<%H:%M>: %?" :target
          (file+head "%<%Y-%m-%d>.org" "#+title: Journal-%<%Y-%m-%d>\n#+category: Journal-%<%Y-%m-%d>\n#+filetags: Journal\n\n"))))

(defun org-roam-node-insert-immediate (arg &rest args)
  (interactive "P")
  (let ((args (cons arg args))
        (org-roam-capture-templates (list (append (car org-roam-capture-templates)
                                                  '(:immediate-finish t)))))
    (apply #'org-roam-node-insert args)))

(map! :i "C-c n i" #'org-roam-node-insert
      :i "C-c n I" #'org-roam-node-insert-immediate)

(defun orr/org-roam-filter-by-tag (tag-name)
  (lambda (node)
    (member tag-name (org-roam-node-tags node))))

(defun orr/org-roam-list-notes-by-tag (tag-name)
  (mapcar #'org-roam-node-file
          (seq-filter
           (orr/org-roam-filter-by-tag tag-name)
           (org-roam-node-list))))

(defun orr/org-roam-refresh-agenda-list ()
  (interactive)
  (setq! org-agenda-files (orr/org-roam-list-notes-by-tag "Journal"))
  (appendq! org-agenda-files '("/home/m3/my-stuff/Org/Agenda/")))

(orr/org-roam-refresh-agenda-list)

(use-package! parrot
  :config
  (parrot-mode)
  (setq parrot-rotate-dict
        '((:rot ("yes"     "no") :caps t :upcase t)
          (:rot ("left"    "right") :caps t :upcase t)
          (:rot ("min"     "max") :caps t :upcase t)
          (:rot ("on"      "off") :caps t :upcase t)
          (:rot ("prev"    "next") :caps t :upcase t)
          (:rot ("start"   "stop") :caps t :upcase t)
          (:rot ("true"    "false") :caps t :upcase t)
          (:rot ("t"       "nil"))
          (:rot ("&&"      "||"))
          (:rot ("=="      "!="))
          (:rot (">="      "<="))
          (:rot ("."       "->"))
          (:rot ("if"      "else"))
          (:rot ("ifdef"   "ifndef"))
          (:rot ("short"   "int"      "long"))
          (:rot ("float"   "double"))
          (:rot ("int8_t"  "int16_t"  "int32_t"     "int64_t"))
          (:rot ("uint8_t" "uint16_t" "uint32_t"    "uint64_t"))))
  (parrot-set-parrot-type 'emacs)
  (map! :leader
        :n "t u" #'parrot-rotate-next-word-at-point
        :n "t i" #'parrot-rotate-prev-word-at-point))

(map! :desc "Ripgrep on projects"
      "C-;" #'+default/search-project)
(setq projectile-ignored-projects '("~/" "/tmp/" "~/.emacs.d/"))

(map! :leader
      :desc "Toggle rainbow mode"
      "t c" #'rainbow-mode)

(add-hook! 'rainbow-mode-hook
  (hl-line-mode (if rainbow-mode -1 +1)))

(map! :leader "l r" #'vertico-repeat)

(vertico-posframe-mode)

(defun consult-set-font ()
  "Select xfont."
  (interactive)
  (set-frame-font
   (completing-read "Choose font:"
                    (x-list-fonts "*"))))

(map! :leader
      "," #'consult-buffer
      "<" #'consult-buffer-other-window)

(after! consult
  (consult-customize
   consult-buffer :preview-key (kbd "C-,")
   consult-buffer-other-window :preview-key (kbd "C-,")))

(use-package! affe
  :after orderless
  :config
  (consult-customize
   affe-grep
   :prompt "Search in Project  ")
  (consult-customize
   affe-find
   :prompt "Find file in Project  "))

(sp-local-pair
 '(org-mode)
 "<<" ">>"
 :actions '(insert))

(map! :leader
      :desc "Clone indirect buffer other window"
      "b c" #'clone-indirect-buffer-other-window)

(map! :map evil-window-map
      "SPC" #'rotate-layout)

(setq
 evil-vsplit-window-right t
 evil-split-window-below t
 window-divider-default-bottom-width 0
 window-divider-default-right-width 0)
(set-fringe-mode 0)

(custom-set-faces!
  '(aw-leading-char-face
    :foreground "#82aaff"
    :weight bold :height 3.5))

(super-save-mode +1)
(setq super-save-idle-duration 10)

(setq doom-theme 'doom-palenight
      doom-themes-treemacs-theme "doom-colors")

(set-popup-rule! "^\\*vterm" :size 0.20 :vslot -4 :select t :quit nil :ttl 0)

(setq
 which-key-idle-delay 0.3)
(after! which-key (setq-hook! 'which-key-init-buffer-hook line-spacing 0))

(use-package! transient-posframe
  :config
  (transient-posframe-mode))

(setq display-time-world-list
  '(("Etc/UTC" "UTC")
    ("Europe/Prague" "Prague")
    ("America/New_York" "New York")
    ("Europe/Athens" "Athens")
    ("Pacific/Auckland" "Auckland")
    ("Asia/Shanghai" "Shanghai")))
(setq display-time-world-time-format "%a, %d %b %I:%M %R %Z")

(setq calendar-date-style "european"
      calendar-day-abbrev-array '["Mon" "Tue" "Wed" "Thu" "Fri" "Sat" "Sun"])

(global-page-break-lines-mode)

(add-hook 'Info-selection-hook 'info-colors-fontify-node)
