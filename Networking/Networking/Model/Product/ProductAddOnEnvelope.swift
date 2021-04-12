import Foundation

/// Helper to unwrap the product add-ons envelope inside the product metadata.
/// Sample Json:
/// "meta_data": [
/// {
///  "id": 6469,
///  "key": "_last_editor_used_jetpack",
///  "value": "classic-editor"
/// },
/// {
///  "id": 6471,
///  "key": "_product_addons",
///  "value": [
///    {
///      "description": "Pizza topping",
///      "title_format": "label",
///      "required": 0,
///    }
///  ]
/// }
/// ]
///
internal struct ProductAddOnEnvelope: Decodable {

    private typealias DecodableDictionary = [String: AnyDecodable]
    private typealias AnyDictionary = [String: Any]

    /// Internal metadata representation
    ///
    private let metadata: [DecodableDictionary]

    /// Decode main metadata array as an untyped dictionary.
    ///
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.metadata = try container.decode([DecodableDictionary].self)
    }

    /// Searches product metadata for add-ons information and converts it to `ProductAddOn` objects if possible.
    ///
    internal func revolve() throws -> [ProductAddOn] {
        guard let addOnJsonObjects = getAddOnsJsonObjects() else {
            return []
        }

        let jsonDecoder = JSONDecoder()
        return try addOnJsonObjects.map { try decode(addOnJsonObject: $0, using: jsonDecoder) }
    }

    /// Searches for addOns json objects inside the product metadata
    /// Returns nil if none are found.
    ///
    private func getAddOnsJsonObjects() -> [AnyDictionary]? {
        guard let envelopeDictionary = getAddOnsEnvelopeDictionary() else {
            return nil
        }
        return envelopeDictionary["value"]?.value as? [AnyDictionary]
    }

    /// Returns the first object from the metadata where the `key` value is found to be `_product_addons`.
    /// Returns nil of not found.
    ///
    private func getAddOnsEnvelopeDictionary() -> DecodableDictionary? {
        metadata.first { object in
            let objectKey = object["key"]?.value as? String
            return objectKey == "_product_addons"
        }
    }

    /// Converts an addOnJsonObject(`Dictionary`) to a `ProductAddOn` entity.
    ///
    private func decode(addOnJsonObject: AnyDictionary, using decoder: JSONDecoder) throws -> ProductAddOn {
        let jsonData = try JSONSerialization.data(withJSONObject: addOnJsonObject, options: .fragmentsAllowed)
        return try decoder.decode(ProductAddOn.self, from: jsonData)
    }
}
