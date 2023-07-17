
import Foundation

/// Mapper: IAP-WPCOM transaction verification result
///
struct InAppPurchasesTransactionMapper: Mapper {
    func map(response: Data) throws -> Int64 {
        let decoder = JSONDecoder()
        return try decoder.decode(InAppPurchasesTransactionContainer.self, from: response).siteID
    }
}

private struct InAppPurchasesTransactionContainer: Decodable {
    let siteID: Int64

    init(siteID: Int64) {
        self.siteID = siteID
    }

    fileprivate init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let siteID = try container.decodeIfPresent(Int64.self, forKey: .siteID) else {
            throw InAppPurchasesTransactionDecodingError.transactionNotHandled
        }

        self.init(siteID: siteID)
    }

    private enum CodingKeys: String, CodingKey {
        case siteID = "site_id"
    }
}

enum InAppPurchasesTransactionDecodingError: Error {
    case transactionNotHandled
}
