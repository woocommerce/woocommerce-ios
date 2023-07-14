
import Foundation

/// Mapper: IAP-WPCOM transaction verification result
///
struct InAppPurchasesTransactionMapper: Mapper {
    let siteID: Int64

    func map(response: Data) throws -> Int64 {
        let decoder = JSONDecoder()
        decoder.userInfo = [ .siteID: siteID ]

        return try decoder.decode(Int64.self, from: response)
    }
}
