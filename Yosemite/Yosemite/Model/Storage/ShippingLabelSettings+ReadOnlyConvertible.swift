import Foundation
import Storage

// Storage.ShippingLabelSettings: ReadOnlyConvertible Conformance.
//
extension Storage.ShippingLabelSettings: ReadOnlyConvertible {
    /// Updates the Storage.ShippingLabelSettings with the a ReadOnly ShippingLabelSettings.
    ///
    public func update(with settings: Yosemite.ShippingLabelSettings) {
        self.siteID = settings.siteID
        self.orderID = settings.orderID
        self.paperSize = settings.paperSize.rawValue
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ShippingLabelSettings {
        .init(siteID: siteID, orderID: orderID, paperSize: .init(rawValue: paperSize))
    }
}
