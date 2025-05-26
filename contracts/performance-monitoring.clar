;; Performance Monitoring Contract
;; Tracks sustainability improvements and progress against goals

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u400))
(define-constant ERR_INVALID_DATA (err u401))
(define-constant ERR_MILESTONE_NOT_FOUND (err u402))

;; Performance milestone structure
(define-map performance-milestones
  { entity-id: uint, milestone-id: uint }
  {
    target-score: uint,
    current-score: uint,
    deadline-block: uint,
    achieved: bool,
    achievement-block: uint,
    verifier: principal
  }
)

;; Milestone counter per entity
(define-map entity-milestone-count { entity-id: uint } uint)

;; Performance history
(define-map performance-history
  { entity-id: uint, period: uint }
  {
    carbon-improvement: int,
    water-improvement: int,
    waste-improvement: int,
    energy-improvement: int,
    overall-improvement: int,
    timestamp: uint
  }
)

;; Authorized monitors
(define-map monitors principal bool)

;; Initialize contract owner as monitor
(map-set monitors CONTRACT_OWNER true)

;; Create performance milestone
(define-public (create-milestone
  (entity-id uint)
  (target-score uint)
  (deadline-block uint))

  (let (
    (milestone-count (default-to u0 (map-get? entity-milestone-count { entity-id: entity-id })))
    (milestone-id (+ milestone-count u1))
  )
    ;; Validate inputs
    (asserts! (and (>= target-score u0) (<= target-score u100)) ERR_INVALID_DATA)
    (asserts! (> deadline-block block-height) ERR_INVALID_DATA)

    ;; Create milestone
    (map-set performance-milestones
      { entity-id: entity-id, milestone-id: milestone-id }
      {
        target-score: target-score,
        current-score: u0,
        deadline-block: deadline-block,
        achieved: false,
        achievement-block: u0,
        verifier: tx-sender
      }
    )

    ;; Update milestone count
    (map-set entity-milestone-count { entity-id: entity-id } milestone-id)

    (ok milestone-id)
  )
)

;; Update milestone progress
(define-public (update-milestone-progress
  (entity-id uint)
  (milestone-id uint)
  (current-score uint))

  (let ((milestone (unwrap! (map-get? performance-milestones { entity-id: entity-id, milestone-id: milestone-id }) ERR_MILESTONE_NOT_FOUND)))
    ;; Only authorized monitors can update
    (asserts! (default-to false (map-get? monitors tx-sender)) ERR_UNAUTHORIZED)

    ;; Validate score
    (asserts! (and (>= current-score u0) (<= current-score u100)) ERR_INVALID_DATA)

    ;; Check if milestone achieved
    (let ((achieved (>= current-score (get target-score milestone))))
      (map-set performance-milestones
        { entity-id: entity-id, milestone-id: milestone-id }
        (merge milestone {
          current-score: current-score,
          achieved: achieved,
          achievement-block: (if achieved block-height u0)
        })
      )
    )

    (ok true)
  )
)

;; Record performance improvement
(define-public (record-improvement
  (entity-id uint)
  (carbon-change int)
  (water-change int)
  (waste-change int)
  (energy-change int))

  (let (
    (period block-height)
    (overall-change (/ (+ carbon-change water-change waste-change energy-change) 4))
  )
    ;; Only authorized monitors can record
    (asserts! (default-to false (map-get? monitors tx-sender)) ERR_UNAUTHORIZED)

    ;; Record improvement
    (map-set performance-history
      { entity-id: entity-id, period: period }
      {
        carbon-improvement: carbon-change,
        water-improvement: water-change,
        waste-improvement: waste-change,
        energy-improvement: energy-change,
        overall-improvement: overall-change,
        timestamp: block-height
      }
    )

    (ok true)
  )
)

;; Add authorized monitor
(define-public (add-monitor (monitor principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set monitors monitor true)
    (ok true)
  )
)

;; Get milestone details
(define-read-only (get-milestone (entity-id uint) (milestone-id uint))
  (map-get? performance-milestones { entity-id: entity-id, milestone-id: milestone-id })
)

;; Get performance history
(define-read-only (get-performance-history (entity-id uint) (period uint))
  (map-get? performance-history { entity-id: entity-id, period: period })
)

;; Check if milestone is achieved
(define-read-only (is-milestone-achieved (entity-id uint) (milestone-id uint))
  (match (map-get? performance-milestones { entity-id: entity-id, milestone-id: milestone-id })
    milestone (get achieved milestone)
    false
  )
)

;; Get entity milestone count
(define-read-only (get-milestone-count (entity-id uint))
  (default-to u0 (map-get? entity-milestone-count { entity-id: entity-id }))
)
