import struct Yosemite.Order

/// Handles the post-payment confirmation step for a scan-to-pay flow.
/// The customer pays externally via the QR-encoded payment URL; this is invoked
/// once the merchant confirms the payment was received.
protocol POSScanToPayHandling {
    func completeScanToPayPayment(for order: Order) async throws
}
