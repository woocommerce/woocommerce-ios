import Foundation
@testable import Yosemite

/// Mock for `ShippingLabelCarrierRate`
///
final class MockShippingLabelCarrierRate {

    static func makeRate(title: String = "USPS - Parcel Select Mail",
                         rate: Double = 40.060000000000002,
                         insurance: String = "0") -> ShippingLabelCarrierRate {
        return ShippingLabelCarrierRate(title: title,
                                        insurance: insurance,
                                        retailRate: rate,
                                        rate: rate,
                                        rateID: "rate_a8a29d5f34984722942f466c30ea27ef",
                                        serviceID: "ParcelSelect",
                                        carrierID: "usps",
                                        shipmentID: "shp_e0e3c2f4606c4b198d0cbd6294baed56",
                                        hasTracking: true,
                                        isSelected: false,
                                        isPickupFree: true,
                                        deliveryDays: 2,
                                        deliveryDateGuaranteed: false)
    }
}
