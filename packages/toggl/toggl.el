;;; toggl.el --- Simple Toggl API support

;; Copyright (c) 2017 Chris Done. All rights reserved.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(require 'url)

(defvar toggl-api-key nil
  "Your API key.")

(defun toggl-clients ()
  "Synchronously return all your visible clients."
  (unless toggl-api-key
    (error "Set the value of `toggle-api-key' to your key."))
  (let ((url-request-method "GET")
        (url-request-extra-headers
         `(("Content-Type" .
            "Content-Type: application/json")
           ("Authorization" .
            ,(concat "Basic "
                     (base64-encode-string
                      (concat toggl-api-key ":api_token")))))))
    (let ((buffer (url-retrieve-synchronously
                   "https://www.toggl.com/api/v8/clients"
                   t)))
      (with-current-buffer buffer
        (goto-char (point-min))
        (search-forward-regexp "\r?\n\r?\n" nil nil 1)
        (json-read)))))

(defun toggl-client-projects (client-id)
  "Synchronously return all projects for CLIENT-ID."
  (unless toggl-api-key
    (error "Set the value of `toggle-api-key' to your key."))
  (let ((url-request-method "GET")
        (url-request-extra-headers
         `(("Content-Type" .
            "Content-Type: application/json")
           ("Authorization" .
            ,(concat "Basic "
                     (base64-encode-string
                      (concat toggl-api-key ":api_token")))))))
    (let ((buffer (url-retrieve-synchronously
                   (format "https://www.toggl.com/api/v8/clients/%d/projects" client-id)
                   t)))
      (with-current-buffer buffer
        (goto-char (point-min))
        (search-forward-regexp "\r?\n\r?\n" nil nil 1)
        (json-read)))))

(defun toggl-submit (description start-date-time duration)
  "Asynchronously submit a tracking item to toggl.

DESCRIPTION is the name of the item, START-DATE-TIME should be a
standard Emacs date-time, and DURATION is a number of seconds."
  (unless toggl-api-key
    (error "Set the value of `toggle-api-key' to your key."))
  (let ((url-request-method "POST")
        (url-request-extra-headers
         `(("Content-Type" .
            "Content-Type: application/json")
           ("Authorization" .
            ,(concat "Basic "
                     (base64-encode-string
                      (concat toggl-api-key ":api_token"))))))
        (url-request-data
         (json-encode-plist
          (list
           :time_entry
           (list
            :description description
            :created_with "Emacs"
            :billable t
            :start (replace-regexp-in-string "\\(.+?\\)\\+\\([0-9][0-9]\\)\\([0-9][0-9]\\)" "\\1+\\2:\\3" (format-time-string "%Y-%m-%dT%H:%M:%S%z" start-date-time))
            :duration duration)))))
    (url-retrieve
     "https://www.toggl.com/api/v8/time_entries"
     (lambda (&rest args)
       (when (plist-get args :error)
         (error "Error submitting to toggl: %S" (plist-get args :error))))
     t)))

(provide 'toggl)
