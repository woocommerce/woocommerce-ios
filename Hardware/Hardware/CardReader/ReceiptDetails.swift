/// Receipt details associated with a card present transaction.
public struct ReceiptDetails: Codable {
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

extension ReceiptDetails: Equatable {
    public static func ==(lhs: ReceiptDetails, rhs: ReceiptDetails) -> Bool {
        return lhs.applicationPreferredName == rhs.applicationPreferredName &&
            rhs.dedicatedFileName == rhs.dedicatedFileName &&
            lhs.authorizationResponseCode == rhs.authorizationResponseCode &&
            lhs.applicationCryptogram == rhs.applicationCryptogram &&
            lhs.terminalVerificationResults == rhs.terminalVerificationResults &&
            lhs.transactionStatusInformation == rhs.transactionStatusInformation &&
            lhs.accountType == rhs.accountType
    }
}
