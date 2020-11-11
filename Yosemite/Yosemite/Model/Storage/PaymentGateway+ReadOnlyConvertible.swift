import Foundation
import Storage

// MARK: - PaymentGateway: ReadOnlyConvertible
//
extension Storage.PaymentGateway: ReadOnlyConvertible {

    /// Updates the `Storage.PaymentGateway` with the ReadOnly type.
    ///
    public func update(with paymentGateway: Yosemite.PaymentGateway) {
        siteID = paymentGateway.siteID
        gatewayID = paymentGateway.gatewayID
        title = paymentGateway.title
        gatewayDescription = paymentGateway.description
        enabled = paymentGateway.enabled
        features = paymentGateway.features.map { $0.rawValue }
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.PaymentGateway {
        PaymentGateway(siteID: siteID,
                       gatewayID: gatewayID,
                       title: title,
                       description: gatewayDescription,
                       enabled: enabled,
                       features: features.compactMap { PaymentGateway.Feature(rawValue: $0) })
    }
}
