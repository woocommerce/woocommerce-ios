enum AllowedOrderUpdateStatuses {
    static let values: Set<String> = [
        "pending", "processing", "on-hold", "completed", "cancelled", "failed"
    ]
}

enum OrderUpdateRefundGuard {
    static let blockedStatus = "refunded"
    static let message = "Refunds cannot be issued from the assistant. Tap an order to issue the refund manually."
}
