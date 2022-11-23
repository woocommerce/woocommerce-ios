import Foundation

public protocol PaymentRemoteProtocol {
    func loadPlan(thatMatchesID productID: Int64) async throws -> WPComPlan

    func createCart(siteID: Int64, productID: Int64) async throws -> CreateCartResponse
}

/// WPCOM Payment Endpoints
///
public class PaymentRemote: Remote, PaymentRemoteProtocol {
    public func loadPlan(thatMatchesID productID: Int64) async throws -> WPComPlan {
        let path = Path.products
        let request = DotcomRequest(wordpressApiVersion: .mark1_5, method: .get, path: path)
        let plans: [WPComPlan] = try await enqueue(request)
        guard let plan = plans.first(where: { $0.productID == productID }) else {
            throw LoadPlanError.noMatchingPlan
        }
        return plan
    }

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

public struct WPComPlan: Decodable {
    public let productID: Int64
    public let name: String
    public let formattedPrice: String

    private enum CodingKeys: String, CodingKey {
        case productID = "product_id"
        case name = "product_name"
        case formattedPrice = "formatted_price"
    }
}

public enum LoadPlanError: Error {
    case noMatchingPlan
}

public struct CreateCartResponse: Decodable {}

// MARK: - Constants
//
private extension PaymentRemote {
    enum Path {
        static let products = "plans"
        static let cartCreation = "me/shopping-cart"
    }
}
