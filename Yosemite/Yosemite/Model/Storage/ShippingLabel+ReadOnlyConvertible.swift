import Foundation
import Storage

// Storage.ShippingLabel: ReadOnlyConvertible Conformance.
//
extension Storage.ShippingLabel: ReadOnlyConvertible {
    /// Updates the Storage.ShippingLabel with the a ReadOnly ShippingLabel.
    ///
    public func update(with shippingLabel: Yosemite.ShippingLabel) {
        siteID = shippingLabel.siteID
        orderID = shippingLabel.orderID
        shippingLabelID = shippingLabel.shippingLabelID
        carrierID = shippingLabel.carrierID
        dateCreated = shippingLabel.dateCreated
        packageName = shippingLabel.packageName
        rate = shippingLabel.rate
        currency = shippingLabel.currency
        trackingNumber = shippingLabel.trackingNumber
        serviceName = shippingLabel.serviceName
        refundableAmount = shippingLabel.refundableAmount
        status = shippingLabel.status.rawValue
        productIDs = shippingLabel.productIDs
        productNames = shippingLabel.productNames
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
              originAddress: originAddress?.toReadOnly() ?? .empty,
              destinationAddress: destinationAddress?.toReadOnly() ?? .empty,
              productIDs: productIDs,
              productNames: productNames)
    }
}

private extension ShippingLabelAddress {
    static var empty: Self {
        .init(company: "", name: "", phone: "", country: "", state: "", address1: "", address2: "", city: "", postcode: "")
    }
}
