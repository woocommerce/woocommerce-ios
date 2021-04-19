import StripeTerminal

extension ReceiptDetails {

    /// Convenience initializer
    /// - Parameter reader: An instance of a StripeTerminal.ReceiptDetails
    init?(receiptDetails: StripeReceiptDetails?) {
        guard let details = receiptDetails else {
            return nil
        }

        self.applicationPreferredName = details.applicationPreferredName
        self.dedicatedFileName = details.dedicatedFileName
        self.authorizationResponseCode = details.authorizationResponseCode
        self.applicationCryptogram = details.applicationCryptogram
        self.terminalVerificationResults = details.terminalVerificationResults
        self.transactionStatusInformation = details.transactionStatusInformation
        self.accountType = details.accountType
    }
}

protocol StripeReceiptDetails {
    var applicationPreferredName: String { get }
    var dedicatedFileName: String { get }
    var authorizationResponseCode: String { get }
    var applicationCryptogram: String { get }
    var terminalVerificationResults: String { get }
    var transactionStatusInformation: String { get }
    var accountType: String? { get }
}


extension StripeTerminal.ReceiptDetails: StripeReceiptDetails { }
