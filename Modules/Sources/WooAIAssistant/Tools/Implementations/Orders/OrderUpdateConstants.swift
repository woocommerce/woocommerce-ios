/// Allowed `status` values for `orders_update` and `orders_bulk_update`.
/// `trash` is excluded: trashing an order is destructive and outside the
/// v1 write-tool scope; deletion-style mutations require a different path.
enum AllowedOrderUpdateStatuses {
    static let values: Set<String> = [
        "pending", "processing", "on-hold", "completed", "cancelled", "refunded", "failed"
    ]
}
