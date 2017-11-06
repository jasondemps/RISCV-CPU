                                        ; Give me a disassembly file with hex...and I'll give you the raw binary.
                                        ; We could even output the .hex file if we want eventually!
;; (defpackage dis2bin
;;   (:use cl-user bit-smasher cl-ppcre)
;;   (:export :parse-dis-file :find-hex :hex2bin)
;;   )

(defun find-hex (line)
  (multiple-value-bind (_ vec) (cl-ppcre:scan-to-strings "\\s+[0-9a-zA-Z]*:\\s+([0-9a-zA-Z]+)" line)
    (if (> (length vec) 0)
        (format nil "~A" (elt vec 0)))))

(defun strip-hex-from-dis (file-in file-out)
  (with-open-file (stream-in file-in :direction :input)
    (with-open-file (stream-out file-out :direction :output :if-exists :supersede)
      (do* ((line (read-line stream-in) (read-line stream-in nil 'eof)))
           ((eq line 'eof) "Reached end of file.")
        (let ((result (find-hex line)))
          (if (not (null result))
              (progn
                (format t "~A~%" result)
                (write-line result stream-out))))))))



(defun word-len (line)
  (multiple-value-bind (_ vec)
      (cl-ppcre:scan-to-strings ":(\\w{2})" line)
    (if (> (length vec) 0)
        (let ((byte-len 0))
          (multiple-value-bind (len)
              (parse-integer (elt vec 0) :radix 16)
            (setf byte-len (+ (mod len 2) len)))
          (bit-smasher:hex->int (format nil "~2,'0X" byte-len))))))

(defun find-instr (len line &key (start 9))
  (subseq line start (+ start len)))

(defun build-binary (line)
  (subseq (write-to-string (bit-smasher:hex->bits (find-instr (word-len line) line))) 2))

(defun generate-header (instance words-per-line)
  (format nil "// memory data file (do not edit the following line - required for mem load use)~%// instance=~A~%// format=mti addressradix=d dataradix=b version=1.0 wordsperline=~A" instance words-per-line))

(let ((hex-eof ":00000001FF"))
  (defun is-hex-eof (input)
    (string= hex-eof input)))

(defun hex2mem (file-in file-out instance &key (words-per-line 1))
  "Generates a Modelsim .mem file from a LITTLE-ENDIAN .hex file. The instance string is required to map the .mem to a position in Modelsim memory. i.e. /top/mem/rom"
  (with-open-file (stream-in file-in :direction :input)
    (with-open-file (stream-out file-out :direction :output :if-exists :supersede)
      (write-line (generate-header instance words-per-line) stream-out)
      (do* ((i 0 (1+ i))
            (line (read-line stream-in) (read-line stream-in nil 'eof)))
           ((or (is-hex-eof line) (eq line 'eof)) "Reached end of file.")
        (let ((result (build-binary line)))
          (if (not (null result))
              (let ((line (format nil "~A: ~A" i result)))
                (progn
                  (format t "~A~%" line)
                  (write-line line stream-out)))))))))
