import Foundation

public class ReceiptRemote: Remote {
    public func retrieveReceipt(siteID: Int64 = 121710041, orderID: Int64 = 7002, completion: @escaping (Result<Receipt, Error>) -> Void) {
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .post,
                                     siteID: 121710041,
                                     path: "orders/\(orderID)/receipt",
                                     parameters: [:],
                                     availableAsRESTRequest: true)
        let mapper = ReceiptMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }
}
