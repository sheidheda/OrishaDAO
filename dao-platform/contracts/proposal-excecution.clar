;; proposal-execution.clar

;; Import the proposal execution trait and treasury trait
(impl-trait .traits.proposal-execution-trait)
(use-trait treasury-trait .traits.treasury-trait)

;; Define the proposal execution trait
(define-trait proposal-execution-trait
    ((execute-action (uint <treasury-trait>) (response bool uint))))

;; Execute the action of a passed proposal
;; @param proposal-id: The ID of the proposal to execute
;; @param treasury: The treasury contract
;; @returns: The result of the proposal execution
(define-public (execute-action (proposal-id uint) (treasury <treasury-trait>))
    (contract-call? treasury withdraw-treasury u1000))