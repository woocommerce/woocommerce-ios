import Foundation
import Yosemite

/// Generates mock `ShippingLabel`
///
public struct MockShippingLabel {
    /// Consider setting a subset of properties using `.copy`.
    public static func emptyLabel() -> ShippingLabel {
        .init(siteID: 0,
              orderID: 0,
              shippingLabelID: 0,
              carrierID: "",
              dateCreated: Date(),
              packageName: "",
              rate: 0,
              currency: "",
              trackingNumber: "",
              serviceName: "",
              refundableAmount: 0,
              status: .purchased,
              refund: nil,
              originAddress: MockShippingLabelAddress.sampleAddress(),
              destinationAddress: MockShippingLabelAddress.sampleAddress(),
              productIDs: [],
              productNames: [])
    }
}
