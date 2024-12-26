;; meters.clar
;; Smart meter management and data validation

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_METER (err u101))
(define-constant ERR_METER_EXISTS (err u102))
(define-constant ERR_INVALID_READING (err u103))
(define-constant ERR_INVALID_LOCATION (err u104))
(define-constant ERR_INVALID_EXPIRY (err u105))
(define-constant ERR_INVALID_INPUT (err u106))
(define-constant MAXIMUM_READING u1000000000000)
(define-constant MINIMUM_CERTIFICATION_PERIOD u52560) ;; One year in blocks

;; Data Maps
(define-map smart-meters
    uint
    {
        owner: principal,
        active: bool,
        last-reading: uint,
        last-update: uint,
        location: (string-utf8 50),
        certification-expiry: uint
    }
)

(define-map meter-validators 
    principal 
    {
        active: bool,
        added-height: uint
    }
)

(define-map meter-readings
    { meter-id: uint, timestamp: uint }
    {
        reading: uint,
        validator: (optional principal),
        validated: bool
    }
)

;; Input Validation Functions
(define-private (validate-location (location (string-utf8 50)))
    (and
        (> (len location) u0)
        (<= (len location) u50)
    )
)

(define-private (validate-certification-expiry (expiry uint))
    (and
        (>= expiry block-height)
        (>= (- expiry block-height) MINIMUM_CERTIFICATION_PERIOD)
    )
)

(define-private (validate-meter-reading (reading uint))
    (and
        (> reading u0)
        (<= reading MAXIMUM_READING)
    )
)

(define-private (validate-meter-id (meter-id uint))
    (is-some (map-get? smart-meters meter-id))
)

(define-private (validate-timestamp (timestamp uint))
    (and 
        (>= timestamp u0)
        (<= timestamp block-height)
    )
)

(define-private (validate-validator (validator principal))
    (and 
        (not (is-eq validator CONTRACT_OWNER))
        (not (is-eq validator tx-sender))
    )
)

;; Public Functions
(define-public (register-meter
    (meter-id uint)
    (location (string-utf8 50))
    (certification-expiry uint)
)
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (asserts! (is-none (map-get? smart-meters meter-id)) ERR_METER_EXISTS)
        (asserts! (validate-location location) ERR_INVALID_LOCATION)
        (asserts! (validate-certification-expiry certification-expiry) ERR_INVALID_EXPIRY)
        
        (ok (map-set smart-meters meter-id
            {
                owner: tx-sender,
                active: true,
                last-reading: u0,
                last-update: block-height,
                location: location,
                certification-expiry: certification-expiry
            }
        ))
    )
)

(define-public (submit-reading (meter-id uint) (reading uint))
    (begin
        (asserts! (validate-meter-id meter-id) ERR_INVALID_METER)
        (asserts! (validate-meter-reading reading) ERR_INVALID_READING)
        
        (ok (map-set meter-readings
            { meter-id: meter-id, timestamp: block-height }
            {
                reading: reading,
                validator: none,
                validated: false
            }
        ))
    )
)

(define-public (validate-reading (meter-id uint) (timestamp uint))
    (begin
        (asserts! (validate-meter-id meter-id) ERR_INVALID_METER)
        (asserts! (validate-timestamp timestamp) ERR_INVALID_INPUT)
        (asserts! (is-some (map-get? meter-validators tx-sender)) ERR_NOT_AUTHORIZED)
        (asserts! (is-some (map-get? meter-readings
            {
                meter-id: meter-id,
                timestamp: timestamp
            })) ERR_INVALID_READING)
        
        (ok (map-set meter-readings
            {
                meter-id: meter-id,
                timestamp: timestamp
            }
            (merge (unwrap! (map-get? meter-readings
                {
                    meter-id: meter-id,
                    timestamp: timestamp
                }
            ) ERR_INVALID_READING)
            { validated: true })
        ))
    )
)

(define-public (add-validator (validator principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (asserts! (validate-validator validator) ERR_INVALID_INPUT)
        
        (ok (map-set meter-validators validator {
            active: true,
            added-height: block-height
        }))
    )
)

;; Read-Only Functions
(define-read-only (get-meter-info (meter-id uint))
    (ok (map-get? smart-meters meter-id))
)

(define-read-only (get-reading (meter-id uint) (timestamp uint))
    (ok (map-get? meter-readings { meter-id: meter-id, timestamp: timestamp }))
)

(define-read-only (is-validator (account principal))
    (ok (is-some (map-get? meter-validators account)))
)
