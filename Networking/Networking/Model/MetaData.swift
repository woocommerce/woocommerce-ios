import Foundation
import Codegen

/// Represents the metadata within an Order or Product
/// Currently only handles `String` metadata values
///
public struct MetaData: Codable, Equatable, Sendable, GeneratedCopiable, GeneratedFakeable {
    public let metadataID: Int64
    public let key: String
    public let value: MetaDataValue

    /// MetaData struct initializer.
    ///
    public init(metadataID: Int64, key: String, value: String) {
        self.metadataID = metadataID
        self.key = key
        self.value = MetaDataValue(rawValue: value)
    }

    /// MetaData struct initializer.
    ///
    public init(metadataID: Int64, key: String, value: MetaDataValue) {
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
        let value = try MetaDataValue(from: container.superDecoder(forKey: CodingKeys.value))

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

public enum MetaDataValue: Codable, Equatable, Sendable, GeneratedCopiable {
    case string(_ value: String)
    case json(_ json: String)

    public var stringValue: String {
        switch self {
        case .string(let value):
            return value
        case .json(let json):
            return json
        }
    }
    public var rawValue: String {
        switch self {
        case .string(let value):
            return "\"\(value)\""
        case .json(let json):
            return json
        }
    }
    public var isJson: Bool {
        switch self {
        case .string:
            return false
        case .json:
            return true
        }
    }

    public init(rawValue: String) {
        if let data = rawValue.data(using: .utf8), (try? JSONSerialization.jsonObject(with: data)) != nil {
            self = .json(rawValue)
        } else {
            self = .string(rawValue.removingPrefix("\"").removingSuffix("\""))
        }
    }

    public init(from decoder: Decoder) throws {
        let decodable = try decoder.singleValueContainer().decode(AnyDecodable.self)

        switch decodable.value {
        case let value as String:
            self = .string(value)
        case is Bool:
            self = MetaDataValue.string(decodable.description)
        case is any Numeric:
            self = MetaDataValue.string(decodable.description)
        default:
            if JSONSerialization.isValidJSONObject(decodable.value) {
                let data = (try? JSONSerialization.data(withJSONObject: decodable.value)) ?? Data()
                self = MetaDataValue.json(String(data: data, encoding: .utf8) ?? "")
            } else {
                self = MetaDataValue.string("")
            }
        }
    }
}
