/// energy-token.clar

(define-trait energy-token-trait
  (
    ;; Transfers tokens from the sender to the recipient
    (transfer (recipient principal) (amount uint) (sender principal) (memo (optional (buff 34))) (ok bool))

    ;; Mints tokens to a recipient
    (mint (recipient principal) (amount uint) (ok bool))
  )
)
