import struct Yosemite.Order
import enum Yosemite.OrderStatusEnum

/// Polls the backend for the cart order to determine whether scan-to-pay completed.
struct POSCartScanToPayVerifier: POSScanToPayVerifying {
    let orderController: PointOfSaleOrderControllerProtocol

    func checkPaymentStatus() async throws -> POSScanToPayVerificationResult {
        let refreshed = try await orderController.reloadCurrentOrder()
        return Self.classify(order: refreshed)
    }

    /// Splits the classification logic so it's unit-testable without a network round trip.
    static func classify(order: Order) -> POSScanToPayVerificationResult {
        if order.datePaid != nil {
            return .paid
        }
        switch order.status {
        case .processing, .completed, .onHold:
            return .paid
        default:
            return .pending
        }
    }
}
