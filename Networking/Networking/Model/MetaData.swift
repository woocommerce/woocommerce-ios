import Foundation
import Codegen

/// Represents the metadata within an Order or Product
/// Currently only handles `String` metadata values
///
public struct MetaData: Codable, Equatable, Sendable, GeneratedCopiable, GeneratedFakeable {
    public let metadataID: Int64 //read-only
    public let key: String
    public let value: String?

    /// MetaData struct initializer.
    ///
    public init(metadataID: Int64, key: String, value: String?) {
        self.metadataID = metadataID
        self.key = key
        self.value = value
    }

    /// The public initializer for MetaData.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let metadataID = try container.decode(Int64.self, forKey: .metadataID)
        let key = try container.decode(String.self, forKey: .key)
        let value = container.failsafeDecodeIfPresent(String.self, forKey: .value)

        self.init(metadataID: metadataID, key: key, value: value)
    }
}

/// Defines all of the MetaData's CodingKeys.
///
private extension MetaData {
    enum CodingKeys: String, CodingKey {
        case metadataID = "id"
        case key
        case value
    }
}
