import Foundation


/// Mapper: IAP Order Creation Result
///
struct InAppPurchaseOrderResultMapper: Mapper {

    /// (Attempts) to extract the order ID from a given JSON Encoded response.
    ///
    func map(response: Data) throws -> Int {

        let dictionary = try JSONDecoder().decode([String: AnyDecodable].self, from: response)
        guard let orderId = (dictionary[Constants.orderIdKey]?.value as? Int) else {
            throw Error.parseError
        }
        return orderId
    }
}

private extension InAppPurchaseOrderResultMapper {
    enum Constants {
        static let orderIdKey: String = "order_id"
    }

    enum Error: Swift.Error {
        case parseError
    }
}
