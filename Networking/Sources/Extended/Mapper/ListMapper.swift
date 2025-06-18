import Foundation

/// Shared error types for mappers.
///
public enum MapperError: LocalizedError {
    case dataTooLarge

    public var errorDescription: String? {
        switch self {
        case .dataTooLarge:
            return NSLocalizedString(
                "mapper.error.data.too.large",
                value: "The response data is too large to process.",
                comment: "Error message when API response data exceeds the maximum allowed size."
            )
        }
    }
}

/// ListMapper: Maps generic WooCommerce REST API Lists
///
struct ListMapper<Output: Decodable>: Mapper {
    /// Site Identifier associated to the items that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned by our endpoints.
    ///
    let siteID: Int64

    let maxSizeInBytes: Int64?

    /// - Parameters:
    ///   - siteID: The site identifier associated with the items that will be parsed.
    ///   - maxSizeInBytes: Optional maximum size of the response data in bytes. Defaults to 100MB.
    init(siteID: Int64, maxSizeInBytes: Int64? = 100 * 1024 * 1024) {
        self.siteID = siteID
        self.maxSizeInBytes = maxSizeInBytes
    }

    /// (Attempts) to convert a dictionary into [Output].
    ///
    func map(response: Data) throws -> [Output] {
        if let maxSizeInBytes, Int64(response.count) > maxSizeInBytes {
            throw MapperError.dataTooLarge
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]

        if hasDataEnvelope(in: response) {
            return try decoder.decode(ListEnvelope<Output>.self, from: response).items
        } else {
            return try decoder.decode([Output].self, from: response)
        }
    }
}

/// ListEnvelope Disposable Entity:
/// Our list endpoints return the items in the `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct ListEnvelope<Output: Decodable>: Decodable {
    let items: [Output]

    private enum CodingKeys: String, CodingKey {
        case items = "data"
    }
}
