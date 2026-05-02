import Foundation

enum PointOfSalePaymentMethod {
    case card
    case cash
    /// Manually-confirmed payment for orders collected out-of-band (external reader, gift card,
    /// account credit, etc.). Gated by the `pointOfSaleMarkOrderAsPaid` feature flag.
    case markAsPaid
}
