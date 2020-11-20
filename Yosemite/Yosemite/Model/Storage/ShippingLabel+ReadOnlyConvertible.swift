import Foundation
import Storage

// Storage.ShippingLabel: ReadOnlyConvertible Conformance.
//
extension Storage.ShippingLabel: ReadOnlyConvertible {
    /// Updates the Storage.ShippingLabel with the a ReadOnly ShippingLabel.
    ///
    public func update(with shippingLabel: Yosemite.ShippingLabel) {
        self.siteID = shippingLabel.siteID
        self.orderID = shippingLabel.orderID
        self.shippingLabelID = shippingLabel.shippingLabelID
        self.carrierID = shippingLabel.carrierID
        self.dateCreated = shippingLabel.dateCreated
        self.packageName = shippingLabel.packageName
        self.rate = shippingLabel.rate
        self.currency = shippingLabel.currency
        self.trackingNumber = shippingLabel.trackingNumber
        self.serviceName = shippingLabel.serviceName
        self.refundableAmount = shippingLabel.refundableAmount
        self.status = shippingLabel.status.rawValue
        self.productIDs = shippingLabel.productIDs
        self.productNames = shippingLabel.productNames
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ShippingLabel {
        .init(siteID: siteID,
              orderID: orderID,
              shippingLabelID: shippingLabelID,
              carrierID: carrierID,
              dateCreated: dateCreated,
              packageName: packageName,
              rate: rate,
              currency: currency,
              trackingNumber: trackingNumber,
              serviceName: serviceName,
              refundableAmount: refundableAmount,
              status: .init(rawValue: status),
              refund: refund?.toReadOnly(),
              originAddress: originAddress?.toReadOnly() ?? ShippingLabelAddress.empty,
              destinationAddress: destinationAddress?.toReadOnly() ?? ShippingLabelAddress.empty,
              productIDs: productIDs,
              productNames: productNames)
    }
}

private extension ShippingLabelAddress {
    static var empty: ShippingLabelAddress {
        .init(company: "", name: "", phone: "", country: "", state: "", address1: "", address2: "", city: "", postcode: "")
    }
}
