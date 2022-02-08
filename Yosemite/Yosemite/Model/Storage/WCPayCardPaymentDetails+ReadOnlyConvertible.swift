import Foundation
import Storage
import Networking

extension Storage.WCPayCardPaymentDetails: ReadOnlyConvertible {
    public func update(with paymentDetails: Yosemite.WCPayCardPaymentDetails) {
        brand = paymentDetails.brand.rawValue
        last4 = paymentDetails.last4
        funding = paymentDetails.funding.rawValue
    }

    public func toReadOnly() -> Yosemite.WCPayCardPaymentDetails {
        WCPayCardPaymentDetails(brand: WCPayCardBrand(rawValue: brand) ?? .unknown,
                                last4: last4,
                                funding: WCPayCardFunding(rawValue: funding) ?? .unknown)
    }
}
