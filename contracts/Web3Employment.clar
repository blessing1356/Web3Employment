;; Web3 Employment Agreement Smart Contract
;; Version: 1.0
;; Author: OpenAI (GPT-4o)
;; Description: Milestone-based contracts between employers and freelancers

(define-data-var contract-counter uint u0)

;; Contract Data
(define-map contracts
  {id: uint}
  {
    employer: principal,
    freelancer: principal,
    milestones: uint,
    current-milestone: uint,
    pay-per-milestone: uint,
    total-paid: uint,
    is-complete: bool,
    in-dispute: bool
  }
)

;; Submissions per milestone
(define-map submissions
  {contract-id: uint, milestone: uint}
  {
    content: (string-ascii 280),
    approved: bool
  }
)

;; Error constants
(define-constant ERR_NOT_FREELANCER (err u100))
(define-constant ERR_NOT_EMPLOYER (err u101))
(define-constant ERR_NOT_PARTICIPANT (err u102))
(define-constant ERR_INVALID_CONTRACT (err u103))
(define-constant ERR_ALREADY_COMPLETE (err u104))
(define-constant ERR_NO_SUBMISSION (err u105))

;; 1. Create a contract
(define-public (create-contract (freelancer principal) (milestones uint) (pay-per-milestone uint))
  (let (
    (total (* milestones pay-per-milestone))
    (id (var-get contract-counter))
  )
    (begin
      (match (stx-transfer? total tx-sender (as-contract tx-sender))
        success (begin
          (map-set contracts {id: id}
            {
              employer: tx-sender,
              freelancer: freelancer,
              milestones: milestones,
              current-milestone: u1,
              pay-per-milestone: pay-per-milestone,
              total-paid: u0,
              is-complete: false,
              in-dispute: false
            })
          (var-set contract-counter (+ id u1))
          (ok id))
        error (err error))
    )
  )
)

;; 2. Submit work for a milestone
(define-public (submit-work (contract-id uint) (content (string-ascii 280)))
  (let ((c (map-get? contracts {id: contract-id})))
    (match c
      contract
      (begin
        (asserts! (is-eq tx-sender (get freelancer contract)) ERR_NOT_FREELANCER)
        (asserts! (not (get is-complete contract)) ERR_ALREADY_COMPLETE)
        (map-set submissions {contract-id: contract-id, milestone: (get current-milestone contract)}
          {content: content, approved: false})
        (ok true)
      )
      ERR_INVALID_CONTRACT
    )
  )
)

;; 3. Approve work and release payment
(define-public (approve-work (contract-id uint))
  (let ((c (map-get? contracts {id: contract-id})))
    (match c
      contract
      (let ((m (get current-milestone contract)))
        (asserts! (is-eq tx-sender (get employer contract)) ERR_NOT_EMPLOYER)
        (let ((s (map-get? submissions {contract-id: contract-id, milestone: m})))
          (match s
            submission
            (begin
              (asserts! (not (get approved submission)) ERR_ALREADY_COMPLETE)
              ;; Transfer payment first
              (match (stx-transfer? (get pay-per-milestone contract) (as-contract tx-sender) (get freelancer contract))
                success (begin
                  ;; Mark approved
                  (map-set submissions {contract-id: contract-id, milestone: m}
                    {
                      content: (get content submission),
                      approved: true
                    })
                  ;; Check if complete
                  (let (
                    (next-milestone (+ m u1))
                    (is-final (>= next-milestone (+ (get milestones contract) u1)))
                  )
                    (map-set contracts {id: contract-id}
                      {
                        employer: (get employer contract),
                        freelancer: (get freelancer contract),
                        milestones: (get milestones contract),
                        current-milestone: next-milestone,
                        pay-per-milestone: (get pay-per-milestone contract),
                        total-paid: (+ (get total-paid contract) (get pay-per-milestone contract)),
                        is-complete: is-final,
                        in-dispute: false
                      })
                    (ok true)
                  )
                )
                error (err error)
              )
            )
            ERR_NO_SUBMISSION
          )
        )
      )
      ERR_INVALID_CONTRACT
    )
  )
)

;; 4. Raise dispute
(define-public (raise-dispute (contract-id uint))
  (let ((c (map-get? contracts {id: contract-id})))
    (match c
      contract
      (begin
        (asserts!
          (or (is-eq tx-sender (get freelancer contract)) (is-eq tx-sender (get employer contract)))
          ERR_NOT_PARTICIPANT)
        (map-set contracts {id: contract-id}
          (merge contract {in-dispute: true}))
        (ok true)
      )
      ERR_INVALID_CONTRACT
    )
  )
)

;; 5. Read-only: get contract
(define-read-only (get-contract (contract-id uint))
  (map-get? contracts {id: contract-id})
)

;; 6. Read-only: get submission
(define-read-only (get-submission (contract-id uint) (milestone uint))
  (map-get? submissions {contract-id: contract-id, milestone: milestone})
)
