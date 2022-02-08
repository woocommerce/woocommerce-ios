import Foundation
import Storage
import Networking

extension Storage.WCPayCardPresentPaymentDetails: ReadOnlyConvertible {
    public func update(with paymentDetails: Yosemite.WCPayCardPresentPaymentDetails) {
        brand = paymentDetails.brand.rawValue
        last4 = paymentDetails.last4
        funding = paymentDetails.funding.rawValue
    }

    public func toReadOnly() -> Yosemite.WCPayCardPresentPaymentDetails {
        let receiptDetails = receipt?.toReadOnly() ?? WCPayCardPresentReceiptDetails(accountType: .unknown, applicationPreferredName: "", dedicatedFileName: "")
        return WCPayCardPresentPaymentDetails(brand: WCPayCardBrand(rawValue: brand) ?? .unknown,
                                              last4: last4,
                                              funding: WCPayCardFunding(rawValue: funding) ?? .unknown,
                                              receipt: receiptDetails)
    }
}
