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


/// The initializers of StripeTerminal.ReceiptDetails are annotated as NS_UNAVAILABLE
/// So we can not create instances of that class in our tests.
/// A workaround is declaring this protocol, which matches the parts of
/// StripeTerminal.ReceiptDetails that we are interested in, make ReceiptDetails implement it,
/// and initialize Harware.ReceiptDetails with a type conforming to it.
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
