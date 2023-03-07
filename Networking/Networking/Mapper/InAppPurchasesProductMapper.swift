import Foundation

/// Mapper: IAP Product
///
struct InAppPurchasesProductMapper: Mapper {
    /// (Attempts) to convert a dictionary into a list of product identifiers.
    ///
    func map(response: Data) throws -> [String] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        return try decoder.decode([String].self, from: response)
    }
}
