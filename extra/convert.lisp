(ql:quickload :bit-smasher)

;; (defpackage disasm2hex
;;   (:use :cl-user :bit-smasher)
;;   (:export :output-template))

(defparameter max-address #xFFFF)
(defparameter base-address 0)

(let ((address base-address))
  (defun next-address (&key (reset nil))
    "Increments the address by 1 and returns the actual address to use."
    (if reset
        (setf address base-address))
    (incf address)
    (1- address)))

(defun line-template (byte-count &key (reset nil))
  "Creates the template to emplace the rest of the data."
  (let ((address (next-address :reset reset)))
    (if (or (> byte-count 255) (< byte-count 0) (> address max-address))
        (format nil "Invalid byte-count (either greater than 255 or less than 0) or address is greater than ~A.~%" max-address)
        (let ((record-count 2))
          (concatenate 'string
                       ":"
                       (format nil "~2,'0X" byte-count)
                       (format nil "~4,'0X" address)
                       (make-string (+ record-count (+ (mod byte-count 2) byte-count)) :initial-element #\0))))))

(defun inject-data (line data)
  "Emplaces the hex data into the hex-formatted line."
  (concatenate 'string (subseq line 0 (- (length line) (length data))) data))

(defun char->hex (char)
  "Converts a character to hex (radix 16)"
  (digit-char-p char 16))

(defun append-checksum (line)
  "Appends the checksum calculation to the hex line. Leading colon will be stripped off the line."
  (concatenate 'string line (calculate-checksum (subseq line (position-if #'digit-char-p line)) #x0)))

(defun calculate-checksum (line chksum)
  "Calculates a checksum by adding each byte and taking two's complement. Once we hit the end, invert the bits."
  (if (< (length line) 2)
      (let ((two-comp-1 (+ (logorc1 chksum 0) 1)))
        (if (= two-comp-1 -1)
            "FF"
            (string-upcase (bit-smasher:int->hex two-comp-1))))
      (calculate-checksum (subseq line 2) (+
                                           (char->hex (char line 0))
                                           (char->hex (char line 1)) chksum))))

(let ((hex-eof ":00000001FF"))
  (defun output-eof ()
    "Outputs last sequence, based on hex standard."
     (format nil "~A" hex-eof)))

(defun output-hex-line (hex-in &key (byte-count nil))
  "Wedges everything together and outputs the formatted line."
  (format nil "~A" (append-checksum (inject-data
                                     (line-template (if byte-count
                                                        byte-count
                                                        (length hex-in)))
                                     hex-in))))

(defun find-longest-line (file)
  (with-open-file (stream file :direction :input)
    (do ((line (read-line stream) (read-line stream nil 'eof))
         (max-len 0))
        ((eq line 'eof) max-len)
      (setf max-len (max max-len (length line))))))

(defun disasm2hex (file-in file-out &key (byte-count nil))
  "Reads a file of hex values and outputs the resulting HEX format. If a max byte count is not supplied, it will be determined based on the longest line of hex in the file."
  (let ((max-length (if byte-count byte-count (find-longest-line file-in))))
    (with-open-file (stream-in file-in :direction :input)
      (with-open-file (stream-out file-out :direction :output :if-exists :supersede)
        (do ((line (read-line stream-in) (read-line stream-in nil 'eof)))
            ((eq line 'eof) (write-line (output-eof) stream-out))
          (let ((result (output-hex-line line :byte-count max-length)))
            (if (not (null result))
                (progn
                  (format t "~A~%" result)
                  (write-line result stream-out)))))))))
