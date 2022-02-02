import Foundation
import Codegen

// https://stripe.com/docs/api/charges/object#charge_object-payment_method_details-card_present-receipt
public struct WCPayCardPresentReceiptDetails: Codable, GeneratedCopiable, GeneratedFakeable, Equatable {
    let accountType: WCPayAccountType
    let applicationPreferredName: String
    let dedicatedFileName: String

    public init(accountType: WCPayAccountType,
                applicationPreferredName: String,
                dedicatedFileName: String) {
        self.accountType = accountType
        self.applicationPreferredName = applicationPreferredName
        self.dedicatedFileName = dedicatedFileName
    }
}

internal extension WCPayCardPresentReceiptDetails {
    enum CodingKeys: String, CodingKey {
        case accountType = "account_type"
        case applicationPreferredName = "application_preferred_name"
        case dedicatedFileName = "dedicated_file_name"
    }
}
