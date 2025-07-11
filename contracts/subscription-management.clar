;; Subscription Management Contract
;; Handles recurring meal plan preferences and billing

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u500))
(define-constant ERR_SUBSCRIPTION_NOT_FOUND (err u501))
(define-constant ERR_INVALID_PLAN (err u502))
(define-constant ERR_INSUFFICIENT_BALANCE (err u503))
(define-constant ERR_SUBSCRIPTION_ACTIVE (err u504))
(define-constant ERR_PAYMENT_FAILED (err u505))

;; Data Variables
(define-data-var total-subscriptions uint u0)
(define-data-var next-subscription-id uint u1)
(define-data-var platform-fee-rate uint u250) ;; 2.5% in basis points

;; Data Maps
(define-map subscription-plans
  { plan-id: uint }
  {
    name: (string-ascii 100),
    description: (string-ascii 300),
    meals-per-week: uint,
    price-per-week: uint,
    delivery-days: (list 7 uint),
    dietary-options: (list 10 (string-ascii 30)),
    is-active: bool,
    created-at: uint
  }
)

(define-map user-subscriptions
  { subscription-id: uint }
  {
    subscriber: principal,
    plan-id: uint,
    start-date: uint,
    end-date: (optional uint),
    status: (string-ascii 20),
    payment-method: (string-ascii 50),
    auto-renew: bool,
    delivery-address: (string-ascii 300),
    special-instructions: (string-ascii 500),
    meals-delivered: uint,
    total-paid: uint,
    next-billing-date: uint,
    created-at: uint
  }
)

(define-map subscription-preferences
  { subscriber: principal }
  {
    preferred-cuisines: (list 10 (string-ascii 50)),
    meal-size: (string-ascii 20),
    spice-level: uint,
    avoid-ingredients: (list 20 (string-ascii 50)),
    delivery-time-preference: (string-ascii 50),
    packaging-preference: (string-ascii 30),
    updated-at: uint
  }
)

(define-map billing-history
  { billing-id: uint }
  {
    subscription-id: uint,
    subscriber: principal,
    amount: uint,
    billing-date: uint,
    payment-status: (string-ascii 20),
    payment-method: (string-ascii 50),
    transaction-id: (optional (string-ascii 100))
  }
)

(define-map user-balances
  { user: principal }
  { balance: uint, last-updated: uint }
)

;; Public Functions

;; Create subscription plan (admin only)
(define-public (create-subscription-plan
  (name (string-ascii 100))
  (description (string-ascii 300))
  (meals-per-week uint)
  (price-per-week uint)
  (delivery-days (list 7 uint))
  (dietary-options (list 10 (string-ascii 30))))
  (let ((plan-id (var-get next-subscription-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set subscription-plans
      { plan-id: plan-id }
      {
        name: name,
        description: description,
        meals-per-week: meals-per-week,
        price-per-week: price-per-week,
        delivery-days: delivery-days,
        dietary-options: dietary-options,
        is-active: true,
        created-at: block-height
      }
    )
    (var-set next-subscription-id (+ plan-id u1))
    (ok plan-id)
  )
)

;; Subscribe to meal plan
(define-public (subscribe-to-plan
  (plan-id uint)
  (payment-method (string-ascii 50))
  (delivery-address (string-ascii 300))
  (special-instructions (string-ascii 500))
  (auto-renew bool))
  (let (
    (subscriber tx-sender)
    (subscription-id (var-get next-subscription-id))
  )
    (asserts! (is-some (map-get? subscription-plans { plan-id: plan-id })) ERR_INVALID_PLAN)
    (let (
      (plan (unwrap-panic (map-get? subscription-plans { plan-id: plan-id })))
      (weekly-cost (get price-per-week plan))
    )
      ;; Check if user has sufficient balance
      (asserts! (>= (get-user-balance subscriber) weekly-cost) ERR_INSUFFICIENT_BALANCE)

      ;; Deduct payment
      (try! (deduct-balance subscriber weekly-cost))

      ;; Create subscription
      (map-set user-subscriptions
        { subscription-id: subscription-id }
        {
          subscriber: subscriber,
          plan-id: plan-id,
          start-date: block-height,
          end-date: none,
          status: "active",
          payment-method: payment-method,
          auto-renew: auto-renew,
          delivery-address: delivery-address,
          special-instructions: special-instructions,
          meals-delivered: u0,
          total-paid: weekly-cost,
          next-billing-date: (+ block-height u1008), ;; ~1 week in blocks
          created-at: block-height
        }
      )
      (var-set next-subscription-id (+ subscription-id u1))
      (var-set total-subscriptions (+ (var-get total-subscriptions) u1))
      (ok subscription-id)
    )
  )
)

;; Update subscription preferences
(define-public (update-preferences
  (preferred-cuisines (list 10 (string-ascii 50)))
  (meal-size (string-ascii 20))
  (spice-level uint)
  (avoid-ingredients (list 20 (string-ascii 50)))
  (delivery-time-preference (string-ascii 50))
  (packaging-preference (string-ascii 30)))
  (let ((subscriber tx-sender))
    (map-set subscription-preferences
      { subscriber: subscriber }
      {
        preferred-cuisines: preferred-cuisines,
        meal-size: meal-size,
        spice-level: spice-level,
        avoid-ingredients: avoid-ingredients,
        delivery-time-preference: delivery-time-preference,
        packaging-preference: packaging-preference,
        updated-at: block-height
      }
    )
    (ok true)
  )
)

;; Cancel subscription
(define-public (cancel-subscription (subscription-id uint))
  (let ((subscriber tx-sender))
    (match (map-get? user-subscriptions { subscription-id: subscription-id })
      subscription-data
      (begin
        (asserts! (is-eq (get subscriber subscription-data) subscriber) ERR_UNAUTHORIZED)
        (asserts! (is-eq (get status subscription-data) "active") ERR_SUBSCRIPTION_ACTIVE)
        (map-set user-subscriptions
          { subscription-id: subscription-id }
          (merge subscription-data {
            status: "cancelled",
            end-date: (some block-height)
          })
        )
        (ok true)
      )
      ERR_SUBSCRIPTION_NOT_FOUND
    )
  )
)

;; Add balance to user account
(define-public (add-balance (amount uint))
  (let ((user tx-sender))
    (let ((current-balance (get-user-balance user)))
      (map-set user-balances
        { user: user }
        { balance: (+ current-balance amount), last-updated: block-height }
      )
      (ok (+ current-balance amount))
    )
  )
)

;; Process recurring billing (admin only)
(define-public (process-billing (subscription-id uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? user-subscriptions { subscription-id: subscription-id })
      subscription-data
      (let (
        (subscriber (get subscriber subscription-data))
        (plan-id (get plan-id subscription-data))
        (plan (unwrap! (map-get? subscription-plans { plan-id: plan-id }) ERR_INVALID_PLAN))
        (weekly-cost (get price-per-week plan))
      )
        (if (and
          (is-eq (get status subscription-data) "active")
          (get auto-renew subscription-data)
          (>= block-height (get next-billing-date subscription-data)))
          (if (>= (get-user-balance subscriber) weekly-cost)
            (begin
              ;; Deduct payment
              (try! (deduct-balance subscriber weekly-cost))
              ;; Update subscription
              (map-set user-subscriptions
                { subscription-id: subscription-id }
                (merge subscription-data {
                  total-paid: (+ (get total-paid subscription-data) weekly-cost),
                  next-billing-date: (+ (get next-billing-date subscription-data) u1008)
                })
              )
              (ok true)
            )
            (begin
              ;; Suspend subscription due to insufficient funds
              (map-set user-subscriptions
                { subscription-id: subscription-id }
                (merge subscription-data { status: "suspended" })
              )
              ERR_INSUFFICIENT_BALANCE
            )
          )
          (ok false) ;; Not time to bill yet
        )
      )
      ERR_SUBSCRIPTION_NOT_FOUND
    )
  )
)

;; Read-only Functions

;; Get subscription plan
(define-read-only (get-subscription-plan (plan-id uint))
  (map-get? subscription-plans { plan-id: plan-id })
)

;; Get user subscription
(define-read-only (get-user-subscription (subscription-id uint))
  (map-get? user-subscriptions { subscription-id: subscription-id })
)

;; Get user preferences
(define-read-only (get-user-preferences (subscriber principal))
  (map-get? subscription-preferences { subscriber: subscriber })
)

;; Get user balance
(define-read-only (get-user-balance (user principal))
  (default-to u0 (get balance (map-get? user-balances { user: user })))
)

;; Get total subscriptions
(define-read-only (get-total-subscriptions)
  (var-get total-subscriptions)
)

;; Check subscription status
(define-read-only (is-subscription-active (subscription-id uint))
  (match (map-get? user-subscriptions { subscription-id: subscription-id })
    subscription-data
    (is-eq (get status subscription-data) "active")
    false
  )
)

;; Private Functions

;; Deduct balance from user account
(define-private (deduct-balance (user principal) (amount uint))
  (let ((current-balance (get-user-balance user)))
    (if (>= current-balance amount)
      (begin
        (map-set user-balances
          { user: user }
          { balance: (- current-balance amount), last-updated: block-height }
        )
        (ok true)
      )
      ERR_INSUFFICIENT_BALANCE
    )
  )
)
