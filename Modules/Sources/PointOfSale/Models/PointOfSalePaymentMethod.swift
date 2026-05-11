import Foundation

enum PointOfSalePaymentMethod {
    case card
    case cash
    /// QR-code-based payment where the customer scans the order's gateway-hosted payment URL
    /// from their phone. Gated by the `pointOfSaleScanToPay` feature flag.
    case scanToPay
    /// Manually-confirmed payment for orders collected out-of-band (external reader, gift card,
    /// account credit, etc.). Gated by the `pointOfSaleMarkOrderAsPaid` feature flag.
    case markAsPaid
}
