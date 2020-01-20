// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

/// Mapper: ProductVariation List
///
struct ProductVariationListMapper: Mapper {
    /// (Attempts) to convert a dictionary into [ProductVariation].
    ///
    func map(response: Data) throws -> [ProductVariation] {
        let decoder = JSONDecoder()
        // TODO: add any custom decoding strategies like date
        // TODO: uncomment the code below for siteID injection
        // decoder.userInfo = [
        //     .siteID: siteID
        // ]

        return try decoder.decode(ProductVariationListEnvelope.self, from: response).data
    }
}


/// ProductVariationListEnvelope Disposable Entity
///
/// `Load All ProductVariation` endpoint returns the requested data in the `data` key. This entity
/// allows us to parse all the things with JSONDecoder.
///
private struct ProductVariationListEnvelope: Decodable {
    let data: [ProductVariation]

    private enum CodingKeys: String, CodingKey {
        case data = "data"
    }
}
