@testable import Hardware
import StripeTerminal
// This structs emulates the properties of SCPReceiptDetails
// We can not mock SCPReceiptDetails directly, because its initializers
// are annotated as NS_UNAVAILABLE
struct MockStripeReceiptDetails {
    public let applicationPreferredName: String
    public let dedicatedFileName: String
    public let authorizationResponseCode: String
    public let applicationCryptogram: String
    public let terminalVerificationResults: String
    public let transactionStatusInformation: String
    public let accountType: String?
}

extension MockStripeReceiptDetails: StripeReceiptDetails {}

extension MockStripeReceiptDetails {
    static func mock() -> Self {
        MockStripeReceiptDetails(applicationPreferredName: "app-preferred-name",
                                 dedicatedFileName: "dedicated-file-name",
                                 authorizationResponseCode: "response-code",
                                 applicationCryptogram: "cryptogram",
                                 terminalVerificationResults: "verification-results",
                                 transactionStatusInformation: "status-information",
                                 accountType: "credit")
    }
}
