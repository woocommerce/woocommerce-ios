/// Allowed `status` values for `orders_update` and `orders_bulk_update`.
/// `trash` is excluded: trashing an order is destructive and outside the
/// v1 write-tool scope; deletion-style mutations require a different path.
/// `refunded` is excluded: refunds must be issued from WP-admin, not the
/// assistant.
enum AllowedOrderUpdateStatuses {
    static let values: Set<String> = [
        "pending", "processing", "on-hold", "completed", "cancelled", "failed"
    ]
}

/// Status value the assistant must never set on an order via the write tools.
/// Surfaced separately so callers can return a refund-specific message
/// instead of the generic allowlist error.
enum OrderUpdateRefundGuard {
    static let blockedStatus = "refunded"
    static let message = "Refunds cannot be issued from the assistant. Process the refund from WP-admin."
}
