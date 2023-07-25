
import Foundation

/// Mapper: IAP-WPCOM transaction verification result
///
struct InAppPurchasesTransactionMapper: Mapper {
    func map(response: Data) throws -> InAppPurchasesTransactionResponse {
        let decoder = JSONDecoder()
        return try decoder.decode(InAppPurchasesTransactionResponse.self, from: response)
    }
}

public struct InAppPurchasesTransactionResponse: Decodable {
    public let siteID: Int64?
    public let message: String?
    public let code: Int?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let siteID = try container.decodeIfPresent(Int64.self, forKey: .siteID)
        let errorMessage = try container.decodeIfPresent(String.self, forKey: .message)
        let errorCode = try container.decodeIfPresent(Int.self, forKey: .code)
        self.siteID = siteID
        self.message = errorMessage
        self.code = errorCode
    }

    private enum CodingKeys: String, CodingKey {
        case siteID = "site_id"
        case message
        case code
    }
}
