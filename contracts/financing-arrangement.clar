;; Financing Arrangement Contract
;; Links funding to sustainability goals and manages financing pools

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u300))
(define-constant ERR_INSUFFICIENT_FUNDS (err u301))
(define-constant ERR_ARRANGEMENT_NOT_FOUND (err u302))
(define-constant ERR_INVALID_TERMS (err u303))
(define-constant ERR_ARRANGEMENT_EXPIRED (err u304))

;; Financing arrangement structure
(define-map financing-arrangements
  { arrangement-id: uint }
  {
    entity-id: uint,
    funder: principal,
    amount: uint,
    target-score: uint,
    duration-blocks: uint,
    start-block: uint,
    interest-rate: uint, ;; basis points (e.g., 500 = 5%)
    status: uint, ;; 0=active, 1=completed, 2=defaulted
    disbursed: bool
  }
)

;; Arrangement counter
(define-data-var arrangement-counter uint u0)

;; Funding pool
(define-data-var total-pool uint u0)

;; Status constants
(define-constant STATUS_ACTIVE u0)
(define-constant STATUS_COMPLETED u1)
(define-constant STATUS_DEFAULTED u2)

;; Create financing arrangement
(define-public (create-arrangement
  (entity-id uint)
  (amount uint)
  (target-score uint)
  (duration-blocks uint)
  (interest-rate uint))

  (let ((arrangement-id (+ (var-get arrangement-counter) u1)))
    ;; Validate terms
    (asserts! (> amount u0) ERR_INVALID_TERMS)
    (asserts! (and (>= target-score u0) (<= target-score u100)) ERR_INVALID_TERMS)
    (asserts! (> duration-blocks u0) ERR_INVALID_TERMS)
    (asserts! (<= interest-rate u10000) ERR_INVALID_TERMS) ;; Max 100%

    ;; Check sufficient funds
    (asserts! (>= (stx-get-balance (as-contract tx-sender)) amount) ERR_INSUFFICIENT_FUNDS)

    ;; Create arrangement
    (map-set financing-arrangements
      { arrangement-id: arrangement-id }
      {
        entity-id: entity-id,
        funder: tx-sender,
        amount: amount,
        target-score: target-score,
        duration-blocks: duration-blocks,
        start-block: block-height,
        interest-rate: interest-rate,
        status: STATUS_ACTIVE,
        disbursed: false
      }
    )

    ;; Transfer funds to contract
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set total-pool (+ (var-get total-pool) amount))
    (var-set arrangement-counter arrangement-id)

    (ok arrangement-id)
  )
)

;; Disburse funds (when sustainability target is met)
(define-public (disburse-funds (arrangement-id uint) (entity-owner principal))
  (let ((arrangement (unwrap! (map-get? financing-arrangements { arrangement-id: arrangement-id }) ERR_ARRANGEMENT_NOT_FOUND)))
    ;; Only funder can disburse
    (asserts! (is-eq tx-sender (get funder arrangement)) ERR_UNAUTHORIZED)

    ;; Check arrangement is active and not disbursed
    (asserts! (is-eq (get status arrangement) STATUS_ACTIVE) ERR_INVALID_TERMS)
    (asserts! (not (get disbursed arrangement)) ERR_INVALID_TERMS)

    ;; Transfer funds to entity
    (try! (as-contract (stx-transfer? (get amount arrangement) tx-sender entity-owner)))

    ;; Update arrangement
    (map-set financing-arrangements
      { arrangement-id: arrangement-id }
      (merge arrangement { disbursed: true })
    )

    (var-set total-pool (- (var-get total-pool) (get amount arrangement)))
    (ok true)
  )
)

;; Complete arrangement
(define-public (complete-arrangement (arrangement-id uint))
  (let ((arrangement (unwrap! (map-get? financing-arrangements { arrangement-id: arrangement-id }) ERR_ARRANGEMENT_NOT_FOUND)))
    ;; Only funder can complete
    (asserts! (is-eq tx-sender (get funder arrangement)) ERR_UNAUTHORIZED)

    (map-set financing-arrangements
      { arrangement-id: arrangement-id }
      (merge arrangement { status: STATUS_COMPLETED })
    )

    (ok true)
  )
)

;; Get arrangement details
(define-read-only (get-arrangement (arrangement-id uint))
  (map-get? financing-arrangements { arrangement-id: arrangement-id })
)

;; Check if arrangement is expired
(define-read-only (is-arrangement-expired (arrangement-id uint))
  (match (map-get? financing-arrangements { arrangement-id: arrangement-id })
    arrangement
      (> block-height (+ (get start-block arrangement) (get duration-blocks arrangement)))
    false
  )
)

;; Get total funding pool
(define-read-only (get-total-pool)
  (var-get total-pool)
)

;; Get arrangement count
(define-read-only (get-arrangement-count)
  (var-get arrangement-counter)
)
