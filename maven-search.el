;;; maven-search.el --- Search maven artifacts from Emacs -*- lexical-binding: t; -*-

;; Copyright (C) 2014 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL: https://github.com/syohex/emacs-maven-search
;; Version: 0.01
;; Package-Requires: ((cl-lib "0.5"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Search `maven' artifacts from Emacs

;; Inspired by https://github.com/koron/maven-search

;;; Code:

(require 'cl-lib)
(require 'url)
(require 'json)

(defgroup maven-search nil
  "Search maven artifacts."
  :group 'maven)

(defcustom maven-search-rows 20
  "Number of searchs."
  :type 'integer
  :group 'maven-search)

(defsubst maven-search--construct-url (query)
  (concat "http://search.maven.org/solrsearch/select?" query))

(defun maven-search--parse-response ()
  (goto-char (point-min))
  (when (re-search-forward "\r?\n\r?\n" nil t)
    (let ((response (json-read-from-string
                     (buffer-substring-no-properties (point) (point-max)))))
      (cl-loop for doc across (assoc-default 'docs (assoc-default 'response response))
               for id = (assoc-default 'id doc)
               for latest-version = (assoc-default 'latestVersion doc)
               collect (list :id id :latest-version latest-version)))))

(defun maven-search--request-query (keyword)
  (let ((url-request-method "GET")
        (query (format "rows=%d&wt=json&q=%s" maven-search-rows keyword)))
    (url-retrieve
     (maven-search--construct-url query)
     (lambda (_status)
       (let ((docs (maven-search--parse-response)))
         (with-current-buffer (get-buffer-create "*maven-search*")
           (setq buffer-read-only nil)
           (erase-buffer)
           (cl-loop for doc in docs
                    for line = (concat (plist-get doc :id) ":"
                                       (plist-get doc :latest-version) "\n")
                    do
                    (insert line))
           (goto-char (point-min))
           (setq buffer-read-only t)
           (pop-to-buffer (current-buffer))))))))

;;;###autoload
(defun maven-search (keyword)
  (interactive
   (list (read-string "Search query: " nil 'maven-search--history)))
  (unless (stringp keyword)
    (error "Error: keyword must be string."))
  (when (string= keyword "")
    (error "Error: keyword is empty string"))
  (maven-search--request-query keyword))

(provide 'maven-search)

;;; maven-search.el ends here
