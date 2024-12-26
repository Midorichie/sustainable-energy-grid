;; energy-grid.clar
;; Main contract for energy grid management

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_INPUT (err u101))
(define-constant ERR_INVALID_METER (err u102))
(define-constant ERR_OVERFLOW (err u103))
(define-constant MAXIMUM_ENERGY_AMOUNT u1000000000) ;; Set reasonable maximum
(define-constant MINIMUM_METER_ID u1)
(define-constant MAXIMUM_METER_ID u1000000) ;; Set reasonable maximum

;; Data Variables
(define-data-var total-energy-supplied uint u0)
(define-data-var grid-active bool true)

;; Data Maps
(define-map grid-participants 
    principal 
    {
        active: bool,
        energy-balance: uint,
        smart-meter-id: (optional uint)
    }
)

(define-map energy-trades 
    uint 
    {
        seller: principal,
        buyer: principal,
        amount: uint,
        timestamp: uint
    }
)

(define-map valid-meter-ids uint bool)

;; Private Functions
(define-private (validate-meter-id (meter-id uint))
    (and 
        (>= meter-id MINIMUM_METER_ID)
        (<= meter-id MAXIMUM_METER_ID)
        (is-some (map-get? valid-meter-ids meter-id))
    )
)

(define-private (check-energy-amount (amount uint))
    (and 
        (> amount u0)
        (<= amount MAXIMUM_ENERGY_AMOUNT)
    )
)

(define-private (validate-trade (seller principal) (buyer principal) (amount uint))
    (let
        (
            (seller-info (default-to {active: false, energy-balance: u0, smart-meter-id: none} (map-get? grid-participants seller)))
            (buyer-info (default-to {active: false, energy-balance: u0, smart-meter-id: none} (map-get? grid-participants buyer)))
        )
        (and
            (get active seller-info)
            (get active buyer-info)
            (>= (get energy-balance seller-info) amount)
            (check-energy-amount amount)
        )
    )
)

;; Admin Functions
(define-public (register-valid-meter (meter-id uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (asserts! (and 
            (>= meter-id MINIMUM_METER_ID)
            (<= meter-id MAXIMUM_METER_ID)
        ) ERR_INVALID_INPUT)
        (ok (map-set valid-meter-ids meter-id true))
    )
)

;; Public Functions
(define-public (register-participant (smart-meter-id uint))
    (let
        (
            (participant tx-sender)
        )
        ;; Input validation
        (asserts! (validate-meter-id smart-meter-id) ERR_INVALID_METER)
        (asserts! (is-none (get smart-meter-id (default-to 
            {active: false, energy-balance: u0, smart-meter-id: none} 
            (map-get? grid-participants participant)
        ))) ERR_INVALID_INPUT)
        
        (ok (map-set grid-participants 
            participant
            {
                active: true,
                energy-balance: u0,
                smart-meter-id: (some smart-meter-id)
            }
        ))
    )
)

(define-public (supply-energy (amount uint))
    (let
        (
            (supplier tx-sender)
            (current-balance (get energy-balance (default-to 
                {active: false, energy-balance: u0, smart-meter-id: none} 
                (map-get? grid-participants supplier)
            )))
            (new-total (+ (var-get total-energy-supplied) amount))
        )
        ;; Input validation
        (asserts! (is-some (map-get? grid-participants supplier)) ERR_NOT_AUTHORIZED)
        (asserts! (check-energy-amount amount) ERR_INVALID_INPUT)
        (asserts! (<= new-total MAXIMUM_ENERGY_AMOUNT) ERR_OVERFLOW)
        
        (var-set total-energy-supplied new-total)
        (ok (map-set grid-participants
            supplier
            (merge (default-to 
                {active: false, energy-balance: u0, smart-meter-id: none} 
                (map-get? grid-participants supplier))
                {energy-balance: (+ current-balance amount)}
            )
        ))
    )
)

;; Read-Only Functions
(define-read-only (get-participant-info (participant principal))
    (ok (map-get? grid-participants participant))
)

(define-read-only (get-total-energy)
    (ok (var-get total-energy-supplied))
)

(define-read-only (is-valid-meter (meter-id uint))
    (ok (validate-meter-id meter-id))
)
