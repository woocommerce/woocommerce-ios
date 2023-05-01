import Foundation

/// Helper to extract specific data from inside `Product` metadata.
/// Sample Json:
/// "meta_data": [
/// {
///  "id": 6469,
///  "key": "_last_editor_used_jetpack",
///  "value": "classic-editor"
/// },
/// {
///  "id": 6471,
///  "key": "_subscription_price",
///  "value": "5"
/// },
/// {
///  "id": 6472,
///  "key": "_subscription_period",
///  "value": "month"
/// }
/// ]
///
internal struct ProductMetadataExtractor: Decodable {

    private typealias DecodableDictionary = [String: AnyDecodable]
    private typealias AnyDictionary = [String: Any?]

    /// Internal metadata representation
    ///
    private let metadata: [DecodableDictionary]

    /// Decode main metadata array as an untyped dictionary.
    ///
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.metadata = try container.decode([DecodableDictionary].self)
    }

    /// Searches product metadata for subscription data and converts it to a `ProductSubscription` if possible.
    ///
    internal func extractProductSubscription() throws -> ProductSubscription? {
        let subscriptionMetadata = filterMetadata(with: Constants.subscriptionPrefix)

        guard !subscriptionMetadata.isEmpty else {
            return nil
        }

        let keyValueMetadata = getKeyValueDictionary(from: subscriptionMetadata)
        let jsonData = try convertToJSON(keyValueMetadata)
        let decoder = JSONDecoder()
        return try decoder.decode(ProductSubscription.self, from: jsonData)
    }

    /// Extracts a `String` metadata value for the provided key.
    ///
    internal func extractStringValue(forKey key: String) -> String? {
        let metaData = filterMetadata(with: key)
        let keyValueMetadata = getKeyValueDictionary(from: metaData)
        return keyValueMetadata.valueAsString(forKey: key)
    }

    /// Filters product metadata using the provided prefix.
    ///
    private func filterMetadata(with prefix: String) -> [DecodableDictionary] {
        metadata.filter { object in
            let objectKey = object["key"]?.value as? String ?? ""
            return objectKey.hasPrefix(prefix)
        }
    }

    /// Parses provided metadata to return a dictionary with each metadata object's key and value.
    ///
    private func getKeyValueDictionary(from metadata: [DecodableDictionary]) -> AnyDictionary {
        metadata.reduce(AnyDictionary()) { (dict, object) in
            var newDict = dict
            let objectKey = object["key"]?.value as? String ?? ""
            let objectValue = object["value"]?.value
            newDict.updateValue(objectValue, forKey: objectKey)
            return newDict
        }
    }

    /// Converts the provided key/value dictionary to `JSON Data` that can be decoded.
    ///
    private func convertToJSON(_ keyValueMetadata: AnyDictionary) throws -> Data {
        // Confirm the provided metadata is valid JSON that can be serialized.
        guard JSONSerialization.isValidJSONObject(keyValueMetadata) else {
            throw ProductMetadataExtractorError.invalidJSONObject(keyValueMetadata)
        }

        return try JSONSerialization.data(withJSONObject: keyValueMetadata)
    }
}

// MARK: Constants

private extension ProductMetadataExtractor {
    enum Constants {
        static let subscriptionPrefix = "_subscription"
    }
}

// MARK: Errors

/// Custom errors that can happen during the `ProductMetadataExtractor` decoding.
///
public enum ProductMetadataExtractorError: Error {
    /// Represents an error when a provided `key/value JSON object` can't be converted to `JSON data`.
    ///
    case invalidJSONObject([String: Any?])
}
