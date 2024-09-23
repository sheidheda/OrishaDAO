;; dao-core.clar

;; Import traits from the traits contract
(use-trait governance-token-trait .traits.governance-token-trait)
(use-trait treasury-trait .traits.treasury-trait)
(use-trait proposal-execution-trait .traits.proposal-execution-trait)

;; Define data structures
(define-map proposals
    { id: uint }
    { proposer: principal, description: (string-ascii 256), votesFor: uint, votesAgainst: uint, executed: bool, deadline: uint })

(define-map votes
    { voter: principal, proposalId: uint }
    { choice: bool })

;; Define variables and constants
(define-data-var proposal-counter uint u1)
(define-constant vote-duration-blocks u144) ;; 24 hours in blocks
(define-constant err-proposal-not-found (err u100))
(define-constant err-voting-period-expired (err u101))
(define-constant err-proposal-already-executed (err u103))
(define-constant err-proposal-rejected (err u104))

;; Submit a new proposal
;; @param description: A brief description of the proposal
;; @returns: The ID of the newly created proposal
(define-public (submit-proposal (description (string-ascii 256)))
    (let ((new-id (var-get proposal-counter)))
        (var-set proposal-counter (+ new-id u1))
        (map-set proposals
                 { id: new-id }
                 { proposer: tx-sender, 
                   description: description, 
                   votesFor: u0, 
                   votesAgainst: u0, 
                   executed: false, 
                   deadline: (+ block-height vote-duration-blocks) })
        (ok new-id)))

;; Vote on a proposal
;; @param proposal-id: The ID of the proposal to vote on
;; @param vote-for: True if voting in favor, false if voting against
;; @param token: The governance token contract
;; @returns: True if the vote was successfully cast
(define-public (vote (proposal-id uint) (vote-for bool) (token <governance-token-trait>))
    (let ((proposal (unwrap! (map-get? proposals { id: proposal-id }) err-proposal-not-found))
          (voting-power (unwrap! (contract-call? token get-voting-power tx-sender) (err u102))))
        (asserts! (<= block-height (get deadline proposal)) err-voting-period-expired)
        (map-set votes { voter: tx-sender, proposalId: proposal-id } { choice: vote-for })
        (map-set proposals
                 { id: proposal-id }
                 (merge proposal 
                        { votesFor: (if vote-for (+ (get votesFor proposal) voting-power) (get votesFor proposal)),
                          votesAgainst: (if (not vote-for) (+ (get votesAgainst proposal) voting-power) (get votesAgainst proposal)) }))
        (ok true)))

;; Execute a proposal that has passed
;; @param proposal-id: The ID of the proposal to execute
;; @param treasury: The treasury contract
;; @param execution: The proposal execution contract
;; @returns: The result of the proposal execution
(define-public (execute-proposal (proposal-id uint) (treasury <treasury-trait>) (execution <proposal-execution-trait>))
    (let ((proposal (unwrap! (map-get? proposals { id: proposal-id }) err-proposal-not-found)))
        (asserts! (not (get executed proposal)) err-proposal-already-executed)
        (asserts! (> block-height (get deadline proposal)) err-voting-period-expired)
        (asserts! (> (get votesFor proposal) (get votesAgainst proposal)) err-proposal-rejected)
        (map-set proposals
                 { id: proposal-id }
                 (merge proposal { executed: true }))
        (contract-call? execution execute-action proposal-id treasury)))