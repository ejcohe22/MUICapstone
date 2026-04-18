(defun hertz-of (pair fundamental)
  (/ (* fundamental (car pair))
     (cdr pair)))

(defun sing (voice fundamental)
  (print (list 'voice
               (car voice)
               (cadr voice)
               (hertz-of (cadr voice) fundamental))))

(defun hit (voices fundamental)
  (cond ((null voices) 'amen)
        (t (cons (sing (car voices) fundamental)
                 (hit (cdr voices) fundamental)))))

(defun vamp (voices fundamental n)
  (cond ((zerop n) 'fin)
        (t (cons (hit voices fundamental)
                 (vamp voices fundamental (1- n))))))
