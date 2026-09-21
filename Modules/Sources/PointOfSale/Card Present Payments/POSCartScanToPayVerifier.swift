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
    /// `.processing` and `.completed` cover the standard "paid" terminal states; `.onHold`
    /// is included because some gateways (Klarna for instance) park orders there post-payment
    /// pending fulfillment authorization.
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
