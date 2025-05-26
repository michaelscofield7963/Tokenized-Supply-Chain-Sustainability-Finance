;; Entity Verification Contract
;; Validates and manages supply chain participants

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ENTITY_EXISTS (err u101))
(define-constant ERR_ENTITY_NOT_FOUND (err u102))
(define-constant ERR_INVALID_STATUS (err u103))

;; Entity status types
(define-constant STATUS_PENDING u0)
(define-constant STATUS_VERIFIED u1)
(define-constant STATUS_SUSPENDED u2)
(define-constant STATUS_REVOKED u3)

;; Entity types
(define-constant TYPE_SUPPLIER u0)
(define-constant TYPE_MANUFACTURER u1)
(define-constant TYPE_DISTRIBUTOR u2)
(define-constant TYPE_RETAILER u3)

;; Entity data structure
(define-map entities
  { entity-id: uint }
  {
    owner: principal,
    entity-type: uint,
    name: (string-ascii 100),
    status: uint,
    verification-date: uint,
    verifier: principal
  }
)

;; Entity counter
(define-data-var entity-counter uint u0)

;; Authorized verifiers
(define-map verifiers principal bool)

;; Initialize contract owner as verifier
(map-set verifiers CONTRACT_OWNER true)

;; Register a new entity
(define-public (register-entity (entity-type uint) (name (string-ascii 100)))
  (let ((entity-id (+ (var-get entity-counter) u1)))
    (asserts! (<= entity-type TYPE_RETAILER) ERR_INVALID_STATUS)
    (asserts! (is-none (map-get? entities { entity-id: entity-id })) ERR_ENTITY_EXISTS)

    (map-set entities
      { entity-id: entity-id }
      {
        owner: tx-sender,
        entity-type: entity-type,
        name: name,
        status: STATUS_PENDING,
        verification-date: u0,
        verifier: CONTRACT_OWNER
      }
    )

    (var-set entity-counter entity-id)
    (ok entity-id)
  )
)

;; Verify an entity (only authorized verifiers)
(define-public (verify-entity (entity-id uint))
  (let ((entity (unwrap! (map-get? entities { entity-id: entity-id }) ERR_ENTITY_NOT_FOUND)))
    (asserts! (default-to false (map-get? verifiers tx-sender)) ERR_UNAUTHORIZED)

    (map-set entities
      { entity-id: entity-id }
      (merge entity {
        status: STATUS_VERIFIED,
        verification-date: block-height,
        verifier: tx-sender
      })
    )

    (ok true)
  )
)

;; Add authorized verifier (only contract owner)
(define-public (add-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set verifiers verifier true)
    (ok true)
  )
)

;; Get entity details
(define-read-only (get-entity (entity-id uint))
  (map-get? entities { entity-id: entity-id })
)

;; Check if entity is verified
(define-read-only (is-entity-verified (entity-id uint))
  (match (map-get? entities { entity-id: entity-id })
    entity (is-eq (get status entity) STATUS_VERIFIED)
    false
  )
)

;; Get total entities
(define-read-only (get-entity-count)
  (var-get entity-counter)
)
