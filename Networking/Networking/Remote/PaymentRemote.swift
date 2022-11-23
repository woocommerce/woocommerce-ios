import Foundation

public protocol PaymentRemoteProtocol {
    func createCart(siteID: Int64, productID: Int64) async throws -> CreateCartResponse
}

/// WPCOM Payment Endpoints
///
public class PaymentRemote: Remote, PaymentRemoteProtocol {
    public func createCart(siteID: Int64, productID: Int64) async throws -> CreateCartResponse {
        let path = "\(Path.cartCreation)/\(siteID)"

        let parameters: [String: Any] = [
            "products": [
                [
                    "product_id": productID,
                    "volume": 1
                ]
            ],
            "temporary": false
        ]
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .post, path: path, parameters: parameters)
        return try await enqueue(request)
    }
}

public struct CreateCartResponse: Decodable {}

// MARK: - Constants
//
private extension PaymentRemote {
    enum Path {
        static let cartCreation = "me/shopping-cart"
    }
}
