import Foundation
import Codegen

/// Represents the metadata within an Order
/// Currently only handles `String` metadata values
///
struct OrderMetaData: Decodable {
    public let key: String
    public let value: String

    /// OrderMetaData struct initializer.
    ///
    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }

    /// The public initializer for OrderMetaData.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = try container.decode(String.self, forKey: .key)
        let value = container.failsafeDecodeIfPresent(String.self, forKey: .value) ?? ""

        self.init(key: key, value: value)
    }
}

/// Defines all of the OrderMetaData's CodingKeys.
///
private extension OrderMetaData {
    enum CodingKeys: String, CodingKey {
        case key = "key"
        case value = "value"
    }
}
