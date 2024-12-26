/// energy-grid.clar

(use-trait energy-token-trait './energy-token')
(impl-trait .energy-token.energy-token-trait)

(define-data-var total-supplied-energy uint u0)
(define-data-var grid-balance uint u0)

(define-public (settle-energy (amount uint))
  (let ((current-grid-balance (var-get grid-balance)))
    (if (<= amount current-grid-balance)
      (begin
        (var-set grid-balance (- current-grid-balance amount))
        (var-set total-supplied-energy (+ (var-get total-supplied-energy) amount))
        (ok true)
      )
      (err u500) ; Invalid settlement amount
    )
  ))

(define-public (supply-energy (amount uint))
  (begin
    (var-set grid-balance (+ (var-get grid-balance) amount))
    (ok true)
  ))

(define-read-only (get-grid-balance)
  (var-get grid-balance))

(define-read-only (get-total-supplied-energy)
  (var-get total-supplied-energy))
