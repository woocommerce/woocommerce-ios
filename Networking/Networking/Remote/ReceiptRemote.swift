import Foundation

public final class ReceiptRemote: Remote {
    /// Retrieves a `Receipt`for a given `siteID`and `orderID`
    ///
    /// - Parameters:
    ///    - siteID: site ID which contains the receipt
    ///    - orderID: ID of the order that the receipt is associated to
    ///    - expirationDays: validity of the receipt before a new one needs to be regenerated. Defaults to `2`
    ///    - forceRegenerate: whether a new receipt is generated. Defaults to `true`
    ///    - completion: callback with the expected `Receipt` object, or an error.
    ///
    public func retrieveReceipt(siteID: Int64,
                                orderID: Int64,
                                expirationDays: Int = 2,
                                forceRegenerate: Bool = true,
                                completion: @escaping (Result<Receipt, Error>) -> Void) {
        let path = "orders/\(orderID)/receipt"
        let parameters: [String: String] = [
            ParameterKeys.expirationDays: String(expirationDays),
            ParameterKeys.forceRegenerate: String(forceRegenerate)
        ]
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .post,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = ReceiptMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }
}

private extension ReceiptRemote {
    enum ParameterKeys {
        static let expirationDays: String = "expiration_days"
        static let forceRegenerate: String = "force_new"
    }
}
