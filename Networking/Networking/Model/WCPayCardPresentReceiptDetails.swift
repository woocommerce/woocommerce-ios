import Foundation
import Codegen

/// Model containing information for inclusion on a receipt for a card present payment.
///
/// This is returned as part of the response from the `/payments/charges/<charge_id>` WCPay endpoint.
/// The endpoint returns a thin wrapper around the Stripe object, so
/// [these docs are relevant](https://stripe.com/docs/api/charges/object#charge_object-payment_method_details-card_present-receipt)
///
/// Custom receipt field details can be found in [Stripe's documentation](https://stripe.com/docs/terminal/features/receipts#custom)
///
public struct WCPayCardPresentReceiptDetails: Codable, GeneratedCopiable, GeneratedFakeable, Equatable {
    /// The funding method for the account used to pay, e.g. `credit`, `debit`, `prepaid`, `unknown`
    let accountType: WCPayCardFunding

    /// The EMV Application Identifier (AID)
    let applicationPreferredName: String

    /// The EMV Dedicated File (DF) Name
    let dedicatedFileName: String

    public init(accountType: WCPayCardFunding,
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
