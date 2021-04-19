/// Receipt details associated with a card present transaction.
public struct ReceiptDetails {
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
