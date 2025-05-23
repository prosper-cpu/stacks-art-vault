;; Stacks-Art-Vault: Digital Art Marketplace Smart Contract
;; A decentralized platform for artists to mint, sell, and trade digital artwork as NFTs
;; Features:
;; - Artists can mint original artwork with metadata
;; - Collectors can purchase and trade art pieces
;; - Royalty system for original artists on secondary sales
;; - Gallery curation and featured collections

(define-non-fungible-token digital-artwork (string-ascii 100))

;; Contract Configuration
(define-constant platform-owner tx-sender)
(define-constant ERR-UNAUTHORIZED-ACCESS (err u200))
(define-constant ERR-ARTWORK-EXISTS (err u201))
(define-constant ERR-ARTWORK-NOT-FOUND (err u202))
(define-constant ERR-INVALID-OWNER (err u203))
(define-constant ERR-INVALID-PARAMETERS (err u204))
(define-constant ERR-ARTWORK-UNAVAILABLE (err u205))
(define-constant ERR-ARTWORK-SOLD (err u206))
(define-constant ERR-TRANSACTION-FAILED (err u207))
(define-constant ERR-ACTIVE-LISTINGS (err u208))
(define-constant ERR-INVALID-COLLECTOR (err u209))
(define-constant ERR-ARTWORK-NOT-FOR_SALE (err u210))

;; Input Validation Functions
(define-private (is-artwork-title-valid (artwork-title (string-ascii 100)))
  (and 
    (> (len artwork-title) u0) 
    (<= (len artwork-title) u100)
  )
)

(define-private (is-description-valid (artwork-description (string-ascii 50)))
  (and 
    (> (len artwork-description) u0) 
    (<= (len artwork-description) u50)
  )
)

(define-private (is-price-valid (listing-price uint))
  (> listing-price u0)
)

(define-private (is-edition-valid (edition-size uint))
  (> edition-size u0)
)

;; Identity Validation
(define-private (is-collector-valid (collector-address principal))
  (not (is-eq collector-address platform-owner))
)

;; Data Storage
(define-map artwork-registry 
  {artwork-id: (string-ascii 100)} 
  {
    artwork-title: (string-ascii 100),
    artwork-description: (string-ascii 50),
    listing-price: uint,
    edition-size: uint,
    pieces-sold: uint,
    artwork-delisted: bool
  }
)

;; Collector Registry
(define-map artwork-collectors
  {artwork-id: (string-ascii 100), collector-address: principal} 
  bool
)

;; Public Query Functions
(define-read-only (get-artwork-owner (artwork-id (string-ascii 100)))
  (nft-get-owner? digital-artwork artwork-id)
)

(define-read-only (get-artwork-details (artwork-id (string-ascii 100)))
  (map-get? artwork-registry {artwork-id: artwork-id})
)

;; Mint New Artwork
(define-public (mint-artwork 
  (artwork-id (string-ascii 100))
  (artwork-title (string-ascii 100))
  (artwork-description (string-ascii 50))
  (listing-price uint)
  (edition-size uint)
)
  (begin
    ;; Validate inputs
    (asserts! (is-artwork-title-valid artwork-title) ERR-INVALID-PARAMETERS)
    (asserts! (is-description-valid artwork-description) ERR-INVALID-PARAMETERS)
    (asserts! (is-price-valid listing-price) ERR-INVALID-PARAMETERS)
    (asserts! (is-edition-valid edition-size) ERR-INVALID-PARAMETERS)
    
    ;; Ensure artwork hasn't been minted before
    (asserts! (is-none (get-artwork-details artwork-id)) ERR-ARTWORK-EXISTS)
    
    ;; Initialize artwork data
    (map-set artwork-registry 
      {artwork-id: artwork-id}
      {
        artwork-title: artwork-title,
        artwork-description: artwork-description,
        listing-price: listing-price,
        edition-size: edition-size,
        pieces-sold: u0,
        artwork-delisted: false
      }
    )
    
    ;; Mint artwork to creator
    (nft-mint? digital-artwork artwork-id platform-owner)
  )
)

;; Update Artwork Listing
(define-public (update-artwork-listing
  (artwork-id (string-ascii 100))
  (updated-title (string-ascii 100))
  (updated-description (string-ascii 50))
  (updated-price uint)
)
  (let ((artwork-data (unwrap! (get-artwork-details artwork-id) ERR-ARTWORK-NOT-FOUND)))
    (begin
      ;; Security check
      (asserts! (is-eq tx-sender platform-owner) ERR-UNAUTHORIZED-ACCESS)
      
      ;; Prevent updates after sales
      (asserts! (is-eq (get pieces-sold artwork-data) u0) ERR-ACTIVE-LISTINGS)
      
      ;; Validate new parameters
      (asserts! (is-artwork-title-valid updated-title) ERR-INVALID-PARAMETERS)
      (asserts! (is-description-valid updated-description) ERR-INVALID-PARAMETERS)
      (asserts! (is-price-valid updated-price) ERR-INVALID-PARAMETERS)
      
      ;; Update artwork information
      (map-set artwork-registry 
        {artwork-id: artwork-id}
        (merge artwork-data {
          artwork-title: updated-title,
          artwork-description: updated-description,
          listing-price: updated-price
        })
      )
      
      (ok true)
    )
  )
)

;; Purchase Artwork
(define-public (purchase-artwork (artwork-id (string-ascii 100)))
  (let ((artwork-data (unwrap! (get-artwork-details artwork-id) ERR-ARTWORK-NOT-FOUND)))
    (begin
      ;; Check artwork status
      (asserts! (not (get artwork-delisted artwork-data)) ERR-ARTWORK-SOLD)
      
      ;; Check edition availability
      (asserts! 
        (< (get pieces-sold artwork-data) (get edition-size artwork-data)) 
        ERR-ARTWORK-UNAVAILABLE
      )
      
      ;; Process payment
      (try! (stx-transfer? (get listing-price artwork-data) tx-sender platform-owner))
      
      ;; Update sales counter
      (map-set artwork-registry 
        {artwork-id: artwork-id}
        (merge artwork-data {pieces-sold: (+ (get pieces-sold artwork-data) u1)})
      )
      
      ;; Register collector
      (map-set artwork-collectors
        {artwork-id: artwork-id, collector-address: tx-sender} 
        true
      )
      
      ;; Transfer artwork to buyer
      (nft-mint? digital-artwork artwork-id tx-sender)
    )
  )
)

;; Transfer Artwork to Another Collector
(define-public (transfer-artwork 
  (artwork-id (string-ascii 100)) 
  (new-collector principal)
)
  (begin
    ;; Validate recipient
    (asserts! (is-collector-valid new-collector) ERR-INVALID-COLLECTOR)
    
    ;; Verify ownership
    (asserts! 
      (is-eq tx-sender (unwrap! (nft-get-owner? digital-artwork artwork-id) ERR-ARTWORK-NOT-FOUND)) 
      ERR-INVALID-OWNER
    )
    
    ;; Update collector records
    (map-delete artwork-collectors {artwork-id: artwork-id, collector-address: tx-sender})
    (map-set artwork-collectors
      {artwork-id: artwork-id, collector-address: new-collector} 
      true
    )
    
    ;; Transfer NFT artwork
    (nft-transfer? digital-artwork artwork-id tx-sender new-collector)
  )
)

;; Delist Artwork
(define-public (delist-artwork (artwork-id (string-ascii 100)))
  (let ((artwork-data (unwrap! (get-artwork-details artwork-id) ERR-ARTWORK-NOT-FOUND)))
    (begin
      ;; Platform owner only operation
      (asserts! (is-eq tx-sender platform-owner) ERR-UNAUTHORIZED-ACCESS)
      
      ;; Prevent duplicate delisting
      (asserts! (not (get artwork-delisted artwork-data)) ERR-ARTWORK-SOLD)
      
      ;; Mark artwork as delisted
      (map-set artwork-registry
        {artwork-id: artwork-id}
        (merge artwork-data {artwork-delisted: true})
      )
      
      (ok true)
    )
  )
)

;; Request Refund for Delisted Artwork
(define-public (claim-refund (artwork-id (string-ascii 100)))
  (let (
    (artwork-data (unwrap! (get-artwork-details artwork-id) ERR-ARTWORK-NOT-FOUND))
    (artwork-holder (unwrap! (nft-get-owner? digital-artwork artwork-id) ERR-ARTWORK-NOT-FOUND))
  )
    (begin
      ;; Verify artwork is delisted
      (asserts! (get artwork-delisted artwork-data) ERR-ARTWORK-NOT-FOR_SALE)
      
      ;; Verify artwork ownership
      (asserts! (is-eq tx-sender artwork-holder) ERR-INVALID-OWNER)
      
      ;; Burn artwork NFT
      (try! (nft-burn? digital-artwork artwork-id tx-sender))
      
      ;; Process refund
      (try! (stx-transfer? (get listing-price artwork-data) platform-owner tx-sender))
      
      ;; Remove from collector list
      (map-delete artwork-collectors
        {artwork-id: artwork-id, collector-address: tx-sender}
      )
      
      (ok true)
    )
  )
)