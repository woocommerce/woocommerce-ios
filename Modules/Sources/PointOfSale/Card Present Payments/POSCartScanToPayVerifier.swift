import struct Yosemite.Order
import enum Yosemite.OrderStatusEnum

/// Polls the backend for the cart order to determine whether scan-to-pay completed.
/// Reloads the order each call and classifies status based on `datePaid` / `status`.
struct POSCartScanToPayVerifier: POSScanToPayVerifying {
    let orderController: PointOfSaleOrderControllerProtocol

    func checkPaymentStatus() async throws -> POSScanToPayVerificationResult {
        let refreshed = try await orderController.reloadCurrentOrder()
        return Self.classify(order: refreshed)
    }

    /// Splits the classification logic so it's unit-testable without a network round trip.
    /// `.processing` and `.completed` indicate payment received. An on-hold order can still
    /// be awaiting an offline payment, so it requires a paid date before reporting success.
    static func classify(order: Order) -> POSScanToPayVerificationResult {
        if order.datePaid != nil {
            return .paid(order)
        }
        switch order.status {
        case .processing, .completed:
            return .paid(order)
        default:
            return .pending
        }
    }
}
