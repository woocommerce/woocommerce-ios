import Foundation

/// Sealed `Sendable` JSON value for tool parameter schemas and tool result envelopes.
///
/// Tool inputs and outputs are untyped JSON whose shape varies per tool, and results
/// are re-serialized to the model's next turn. We need one value type that round-trips
/// arbitrary JSON across actor boundaries. Explicit enum cases keep `Sendable`
/// type-safe; an `Any`-backed type would force `@unchecked Sendable` on every result.
public enum AnyCodableJSON: Codable, Sendable, Equatable {
    case null
    case bool(Bool)
    case int(Int64)
    case double(Double)
    case string(String)
    case array([AnyCodableJSON])
    case object([String: AnyCodableJSON])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int64.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([AnyCodableJSON].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: AnyCodableJSON].self) {
            self = .object(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized JSON value")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }
}
