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

public struct MetaDataValue: Codable, Equatable, Sendable {
    private let valueHolder: ValueHolder

    public var stringValue: String {
        valueHolder.stringValue
    }
    public var rawValue: String {
        valueHolder.rawValue
    }

    public var isJson: Bool {
        switch valueHolder {
        case .string:
            return false
        case .json:
            return true
        }
    }

    public init(rawValue: String) {
        let data = Data(rawValue.utf8)
        if let jsonObject = try? JSONDecoder().decode(AnyCodable.self, from: data),
           let value = try? ValueHolder(from: jsonObject.value) {
            valueHolder = value
        } else {
            valueHolder = .string(rawValue.removingPrefix("\"").removingSuffix("\""))
        }
    }

    public init(from decoder: Decoder) throws {
        let codable = try decoder.singleValueContainer().decode(AnyCodable.self)
        valueHolder = try ValueHolder(from: codable.value)
    }

    public func encode(to encoder: Encoder) throws {
        switch valueHolder {
        case .string(let value):
            try value.encode(to: encoder)
        case .json(let json):
            let encodable = try JSONDecoder().decode(AnyCodable.self, from: Data(json.utf8))
            try encodable.encode(to: encoder)
        }
    }
}

private extension MetaDataValue {
    private enum ValueHolder: Codable, Equatable {
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

        init(from object: Any) throws {
            switch object {
            case let value as String:
                self = .string(value)
            case is Bool:
                self = .string(String(describing: object))
            case is any Numeric:
                self = .string(String(describing: object))
            default:
                let encodedJson = try AnyCodable(object).encodeAsJSON()
                self = .json(encodedJson)
            }
        }
    }
}

private extension Encodable {
    func encodeAsJSON() throws -> String {
        let data = try JSONEncoder().encode(self)
        return String(data: data, encoding: .utf8) ?? ""
    }
}
