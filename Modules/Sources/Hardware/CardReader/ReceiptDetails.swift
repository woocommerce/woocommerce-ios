/// Receipt details associated with a card present transaction.
public struct ReceiptDetails: Codable, Equatable {
    /// Also known as “Application Name”. Required on EMV receipts.
    public let applicationPreferredName: String

    /// Also known as “AID”. Required on EMV receipts.
    public let dedicatedFileName: String

    /// Authorization Response Code
    public let authorizationResponseCode: String

    /// Application Cryptogram
    public let applicationCryptogram: String

    /// TVR
    public let terminalVerificationResults: String

    /// TSI
    public let transactionStatusInformation: String

    /// The type of account being debited or credited
    public let accountType: String?
}

extension ReceiptDetails {
    enum CodingKeys: String, CodingKey {
        case applicationPreferredName = "application_preferred_name"
        case dedicatedFileName = "dedicated_file_name"
        case authorizationResponseCode = "authorization_response_code"
        case applicationCryptogram = "application_cryptogram"
        case terminalVerificationResults = "terminal_verification_results"
        case transactionStatusInformation = "transaction_status_information"
        case accountType = "account_type"
    }
}
