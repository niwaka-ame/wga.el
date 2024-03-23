;;; wga.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2024 Yu Huo
;;
;; Author: Yu Huo <yhuo@tuta.io>
;; Maintainer: Yu Huo <yhuo@tuta.io>
;; Created: March 23, 2024
;; Modified: March 23, 2024
;; Version: 0.0.1
;; Keywords: convenience data tools multimedia
;; Homepage: https://github.com/niwaka-ame/wga.el
;; Package-Requires: ((emacs "24.4"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;  A small program to allow quick search in the art catalog of the Web Gallery of Art (WGA).
;;  The program allows user to search and choose from the whole list of art pieces by and the title and the author's name.
;;
;;  Users are recommended to use a completion interface like `ivy' to achieve fuzzy search.
;;  Then the chosen item can be either opened in browser (to the WGA page) or inserted as a link in Org Mode.
;;  These correspond to two commands: `wga-open-in-browser' and `wga-insert-link-in-org-mode'.
;;
;;  This program is NOT part of WGA.
;;  The data associated with this program comes from WGA.
;;
;;; Code:

(require 'subr-x)

(defvar wga-catalog-data nil)

(defun wga--find-data-file (file)
  "Find curated data FILE in this repo."
  (let ((dir (file-name-directory
              (locate-library "wga.el"))))
    (concat dir file)))

(defun wga--load-catalog ()
  "load WGA catalog."
  ; (wga--parse-catalog (wga--file-data-file "catalog.txt"))
  (wga--parse-catalog "/home/yu/code/wga.el/catalog.txt"))

(defun wga--parse-catalog (file)
  (with-current-buffer (find-file-noselect file)
    (goto-char (point-min))
    ;; skip head
    (forward-line 1)
    (let ((line-number (count-lines (point-min) (point-max)))
          (table (make-hash-table :test 'equal :size 60000)))
      (while (<= (line-number-at-pos) line-number)
        ;; Puthash unless that row is to skip.
        (let* ((row (wga--read-line-at-pos "\t"))
               (key (elt row 0))
               (http (elt row 1)))
          (puthash key http table))
        (forward-line 1))
      (setq wga-catalog-data table))))

(defun wga-test ()
  (wga--load-catalog))

(defun wga--read-line-at-pos (sep)
  (let* ((splitted-line
         (split-string (buffer-substring-no-properties
                        (line-beginning-position)
                        (line-end-position)) sep)))
    `[,(concat (car splitted-line) "\t" (elt splitted-line 2)) ,(elt splitted-line 6)]))


(defun wga--query (table)
  (let* ((candidates (hash-table-keys table))
         (choice (completing-read
                  "Enter name: "
                  candidates)))
    `[,(gethash choice table) ,choice]))

(defun wga-open-in-browser ()
  (interactive)
  (unless wga-catalog-data
    (wga--load-catalog))
  (browse-url (elt (wga--query wga-catalog-data) 0)))

(defun wga-insert-link-in-org-mode ()
  (interactive)
  (unless wga-catalog-data
    (wga--load-catalog))
  (let* ((data (wga--query wga-catalog-data))
         (link (elt data 0))
         (text-list (split-string (elt data 1) "\"" t))
         (desc (concat (string-trim-left (elt text-list 1)) " by " (car text-list))))
    (insert (concat "[[" link "][" desc "]] "))))

(provide 'wga)
;;; wga.el ends here
