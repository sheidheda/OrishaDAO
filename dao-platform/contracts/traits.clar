;; traits.clar
;; This file defines all the traits used across the DAO contracts

(define-trait governance-token-trait
  (
    (get-voting-power (principal) (response uint uint))
    (mint-tokens (principal uint) (response bool uint))
    (transfer (principal uint) (response bool uint))
  )
)

(define-trait treasury-trait
  (
    (deposit-treasury (uint) (response bool uint))
    (withdraw-treasury (uint) (response bool uint))
  )
)

(define-trait proposal-execution-trait
  (
    (execute-action (uint <treasury-trait>) (response bool uint))
  )
)