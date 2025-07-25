;; pledge-for-progress.clar
;; A contract for transparently pledging funds towards a public good.

;; ---
;; Constants
;; ---
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_GOAL_ALREADY_MET (err u100))
(define-constant ERR_DEADLINE_PASSED (err u101))
(define-constant ERR_PLEDGE_MUST_BE_POSITIVE (err u102))
(define-constant ERR_GOAL_NOT_MET (err u103))
(define-constant ERR_DEADLINE_NOT_REACHED (err u104))
(define-constant ERR_NOTHING_TO_REFUND (err u105))
(define-constant ERR_ONLY_BENEFICIARY (err u106))
(define-constant ERR_CAMPAIGN_ENDED (err u107))

;; ---
;; Data Variables
;; ---
;; NOTE: Replace with the actual beneficiary's Stacks address.
;; For testing, this is the address of `wallet_1` in a default Clarinet session.
(define-data-var beneficiary principal 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
(define-data-var funding-goal uint u100000000) ;; Goal: 100 STX (1 STX = 1,000,000 micro-STX)
(define-data-var deadline uint u100) ;; Deadline: 100 Stacks blocks from deployment
(define-data-var total-pledged uint u0)
(define-data-var goal-achieved bool false)
(define-data-var funds-claimed bool false)

;; Map to store how much each principal has pledged
(define-map pledges principal uint)

;; ---
;; Public Functions
;; ---

;; @desc Allows anyone to pledge STX to the campaign before the deadline.
;; @param amount The amount of STX (in micro-STX) to pledge.
;; @returns (ok bool) or (err uint)
(define-public (pledge (amount uint))
  (begin
    (asserts! (not (var-get goal-achieved)) ERR_GOAL_ALREADY_MET)
    (asserts! (is-eq (var-get funds-claimed) false) ERR_CAMPAIGN_ENDED)
    (asserts! (< block-height (var-get deadline)) ERR_DEADLINE_PASSED)
    (asserts! (> amount u0) ERR_PLEDGE_MUST_BE_POSITIVE)

    ;; Store the pledge amount for the user
    (map-set pledges tx-sender (+ (get-pledge-amount tx-sender) amount))

    ;; Update the total pledged amount
    (var-set total-pledged (+ (var-get total-pledged) amount))

    ;; Transfer STX from the sender to this contract
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

    ;; Check if the goal has been met
    (if (>= (var-get total-pledged) (var-get funding-goal))
      (var-set goal-achieved true)
      true
    )

    (ok true)
  )
)

;; @desc Allows the beneficiary to claim the collected funds if the goal is met.
;; @returns (ok bool) or (err uint)
(define-public (claim-funds)
  (begin
    (asserts! (is-eq tx-sender (var-get beneficiary)) ERR_ONLY_BENEFICIARY)
    (asserts! (var-get goal-achieved) ERR_GOAL_NOT_MET)
    (asserts! (is-eq (var-get funds-claimed) false) ERR_CAMPAIGN_ENDED)

    (var-set funds-claimed true)
    (as-contract (try! (stx-transfer? (var-get total-pledged) (as-contract tx-sender) (var-get beneficiary))))

    (ok true)
  )
)

;; @desc Allows a pledger to get a refund if the deadline passed and the goal was not met.
;; @returns (ok bool) or (err uint)
(define-public (refund)
  (begin
    (asserts! (>= block-height (var-get deadline)) ERR_DEADLINE_NOT_REACHED)
    (asserts! (not (var-get goal-achieved)) ERR_GOAL_NOT_MET)
    (asserts! (is-eq (var-get funds-claimed) false) ERR_CAMPAIGN_ENDED)

    (let ((pledge-amount (get-pledge-amount tx-sender)))
      (asserts! (> pledge-amount u0) ERR_NOTHING_TO_REFUND)

      (map-set pledges tx-sender u0) ;; Reset the user's pledge amount
      (as-contract (try! (stx-transfer? pledge-amount (as-contract tx-sender) tx-sender)))

      (ok true)
    )
  )
)

;; ---
;; Read-Only Functions
;; ---

;; @desc Returns the amount pledged by a specific principal.
(define-read-only (get-pledge-amount (who principal))
  (default-to u0 (map-get? pledges who))
)

;; @desc Returns the current status of the campaign.
(define-read-only (get-campaign-status)
  {
    beneficiary: (var-get beneficiary),
    funding-goal: (var-get funding-goal),
    deadline: (var-get deadline),
    total-pledged: (var-get total-pledged),
    goal-achieved: (var-get goal-achieved),
    funds-claimed: (var-get funds-claimed)
  }
)