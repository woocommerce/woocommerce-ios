import Alamofire
import Foundation

public typealias RequestParameterDictionary = [String: RequestParameterValue]
public typealias RequestParameterConvertibleDictionary = [String: any RequestParameterValueConvertible]
public typealias OptionalRequestParameterConvertibleDictionary = [String: (any RequestParameterValueConvertible)?]

public protocol RequestParameterValueConvertible {
    var requestParameterValue: RequestParameterValue { get }
}

public enum RequestParameterValue: Sendable, Equatable {
    case string(String)
    case bool(Bool)
    case int(Int)
    case int64(Int64)
    case uint(UInt)
    case uint64(UInt64)
    case double(Double)
    case decimal(Decimal)
    case null
    case array([RequestParameterValue])
    case dictionary(RequestParameterDictionary)
}

public extension RequestParameterValue {
    init(jsonObject: Any) throws {
        switch jsonObject {
        case let value as String:
            self = .string(value)
        case let value as Bool where Self.isBoolean(jsonObject):
            self = .bool(value)
        case let value as Int:
            self = .int(value)
        case let value as Int64:
            self = .int64(value)
        case let value as UInt:
            self = .uint(value)
        case let value as UInt64:
            self = .uint64(value)
        case let value as Float:
            self = .double(Double(value))
        case let value as Double:
            self = .double(value)
        case let value as Decimal:
            self = .decimal(value)
        case let value as NSDecimalNumber:
            self = .decimal(value.decimalValue)
        case let value as NSNumber:
            if CFGetTypeID(value) == CFBooleanGetTypeID() {
                self = .bool(value.boolValue)
            } else {
                self = .decimal(value.decimalValue)
            }
        case is NSNull:
            self = .null
        case let value as [Any]:
            self = .array(try value.map { try RequestParameterValue(jsonObject: $0) })
        case let value as [String: Any]:
            self = .dictionary(try value.requestParameterDictionaryFromJSONObject())
        case let value as NSDictionary:
            self = .dictionary(try value.requestParameterDictionaryFromJSONObject())
        default:
            throw RequestParameterJSONError.unsupportedValue(type: String(describing: type(of: jsonObject)))
        }
    }
}

private extension RequestParameterValue {
    static func isBoolean(_ value: Any) -> Bool {
        guard let object = value as? NSNumber else {
            return false
        }
        return CFGetTypeID(object) == CFBooleanGetTypeID()
    }
}

public enum RequestParameterJSONError: Error, Equatable, LocalizedError, Sendable {
    case unsupportedValue(type: String)
    case nonStringKey(type: String)

    public var errorDescription: String? {
        switch self {
        case .unsupportedValue(let type):
            return "Unsupported request parameter JSON value type: \(type)"
        case .nonStringKey(let type):
            return "Unsupported request parameter JSON dictionary key type: \(type)"
        }
    }
}

extension RequestParameterValue: RequestParameterValueConvertible {
    public var requestParameterValue: RequestParameterValue {
        self
    }
}

extension RequestParameterValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension RequestParameterValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension RequestParameterValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .int(value)
    }
}

extension RequestParameterValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .double(value)
    }
}

extension RequestParameterValue: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}

extension RequestParameterValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: RequestParameterValue...) {
        self = .array(elements)
    }
}

extension RequestParameterValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, any RequestParameterValueConvertible)...) {
        self = .dictionary(Dictionary(uniqueKeysWithValues: elements.map { key, value in
            (key, value.requestParameterValue)
        }))
    }
}

public extension RequestParameterValue {
    static func array(_ values: [any RequestParameterValueConvertible]) -> RequestParameterValue {
        .array(values.map { $0.requestParameterValue })
    }

    static func dictionary(_ values: RequestParameterConvertibleDictionary) -> RequestParameterValue {
        .dictionary(values.requestParameterDictionary)
    }
}

extension String: RequestParameterValueConvertible {
    public var requestParameterValue: RequestParameterValue {
        .string(self)
    }
}

extension Bool: RequestParameterValueConvertible {
    public var requestParameterValue: RequestParameterValue {
        .bool(self)
    }
}

extension Int: RequestParameterValueConvertible {
    public var requestParameterValue: RequestParameterValue {
        .int(self)
    }
}

extension Int8: RequestParameterValueConvertible {
    public var requestParameterValue: RequestParameterValue {
        .int(Int(self))
    }
}

extension Int16: RequestParameterValueConvertible {
    public var requestParameterValue: RequestParameterValue {
        .int(Int(self))
    }
}

extension Int32: RequestParameterValueConvertible {
    public var requestParameterValue: RequestParameterValue {
        .int(Int(self))
    }
}

extension Int64: RequestParameterValueConvertible {
    public var requestParameterValue: RequestParameterValue {
        .int64(self)
    }
}

extension UInt: RequestParameterValueConvertible {
    public var requestParameterValue: RequestParameterValue {
        .uint(self)
    }
}

extension UInt8: RequestParameterValueConvertible {
    public var requestParameterValue: RequestParameterValue {
        .uint(UInt(self))
    }
}

extension UInt16: RequestParameterValueConvertible {
    public var requestParameterValue: RequestParameterValue {
        .uint(UInt(self))
    }
}

extension UInt32: RequestParameterValueConvertible {
    public var requestParameterValue: RequestParameterValue {
        .uint(UInt(self))
    }
}

extension UInt64: RequestParameterValueConvertible {
    public var requestParameterValue: RequestParameterValue {
        .uint64(self)
    }
}

extension Float: RequestParameterValueConvertible {
    public var requestParameterValue: RequestParameterValue {
        .double(Double(self))
    }
}

extension Double: RequestParameterValueConvertible {
    public var requestParameterValue: RequestParameterValue {
        .double(self)
    }
}

extension Decimal: RequestParameterValueConvertible {
    public var requestParameterValue: RequestParameterValue {
        .decimal(self)
    }
}

extension Optional: RequestParameterValueConvertible where Wrapped: RequestParameterValueConvertible {
    public var requestParameterValue: RequestParameterValue {
        switch self {
        case .some(let value):
            return value.requestParameterValue
        case .none:
            return .null
        }
    }
}

extension Array: RequestParameterValueConvertible where Element: RequestParameterValueConvertible {
    public var requestParameterValue: RequestParameterValue {
        .array(map { $0.requestParameterValue })
    }
}

extension Dictionary: RequestParameterValueConvertible where Key == String, Value: RequestParameterValueConvertible {
    public var requestParameterValue: RequestParameterValue {
        .dictionary(mapValues { $0.requestParameterValue })
    }
}

extension Dictionary where Key == String, Value: RequestParameterValueConvertible {
    public var requestParameterDictionary: RequestParameterDictionary {
        mapValues { $0.requestParameterValue }
    }
}

public extension Dictionary where Key == String, Value == any RequestParameterValueConvertible {
    var requestParameterDictionary: RequestParameterDictionary {
        mapValues { $0.requestParameterValue }
    }
}

public extension Dictionary where Key == String, Value == Any {
    func requestParameterDictionaryFromJSONObject() throws -> RequestParameterDictionary {
        try reduce(into: RequestParameterDictionary()) { output, element in
            output[element.key] = try RequestParameterValue(jsonObject: element.value)
        }
    }
}

public extension NSDictionary {
    func requestParameterDictionaryFromJSONObject() throws -> RequestParameterDictionary {
        try reduce(into: RequestParameterDictionary()) { output, element in
            guard let key = element.key as? String else {
                throw RequestParameterJSONError.nonStringKey(type: String(describing: type(of: element.key)))
            }
            output[key] = try RequestParameterValue(jsonObject: element.value)
        }
    }
}

/// Sendable snapshot of JSON-compatible request parameters.
struct RequestParameters: Sendable {
    private let storage: RequestParameterDictionary?

    init(_ parameters: RequestParameterDictionary? = nil) {
        self.storage = parameters
    }

    init<Value: RequestParameterValueConvertible>(_ parameters: [String: Value]) {
        self.storage = parameters.requestParameterDictionary
    }

    init(_ parameters: RequestParameterConvertibleDictionary) {
        self.storage = parameters.requestParameterDictionary
    }

    var isEmpty: Bool {
        storage?.isEmpty ?? true
    }

    var dictionary: RequestParameterDictionary? {
        storage
    }

    func validatedAlamofireParameters() throws -> Parameters? {
        try storage.map { try Self.alamofireParameters(from: $0, path: "parameters") }
    }

    func validatedDictionary() throws -> [String: Any]? {
        try storage.map { try Self.dictionary(from: $0, path: "parameters") }
    }

    func validatedDictionaryOrEmpty() throws -> [String: Any] {
        try validatedDictionary() ?? [:]
    }
}

enum RequestParameterError: Error, Equatable, LocalizedError, Sendable {
    case nonFiniteNumber(path: String)

    var errorDescription: String? {
        switch self {
        case .nonFiniteNumber(let path):
            return "Unsupported non-finite request parameter at \(path)"
        }
    }
}

private extension RequestParameters {
    typealias AlamofireParameterValue = any Any & Sendable

    static func alamofireParameters(from parameters: RequestParameterDictionary, path: String) throws -> Parameters {
        try parameters.reduce(into: Parameters()) { output, element in
            output[element.key] = try alamofireValue(from: element.value, path: "\(path).\(element.key)")
        }
    }

    static func dictionary(from parameters: RequestParameterDictionary, path: String) throws -> [String: Any] {
        try parameters.reduce(into: [String: Any]()) { output, element in
            output[element.key] = try anyValue(from: element.value, path: "\(path).\(element.key)")
        }
    }

    static func alamofireValue(from value: RequestParameterValue, path: String) throws -> AlamofireParameterValue {
        switch value {
        case .string(let value):
            return value
        case .bool(let value):
            return value
        case .int(let value):
            return value
        case .int64(let value):
            return value
        case .uint(let value):
            return value
        case .uint64(let value):
            return value
        case .double(let value):
            return try finite(value, path: path)
        case .decimal(let value):
            return try finite(value, path: path)
        case .null:
            return NSNull()
        case .array(let values):
            return try values.enumerated().map { index, value in
                try alamofireValue(from: value, path: "\(path)[\(index)]")
            }
        case .dictionary(let values):
            return try alamofireParameters(from: values, path: path)
        }
    }

    static func anyValue(from value: RequestParameterValue, path: String) throws -> Any {
        switch value {
        case .string(let value):
            return value
        case .bool(let value):
            return value
        case .int(let value):
            return value
        case .int64(let value):
            return value
        case .uint(let value):
            return value
        case .uint64(let value):
            return value
        case .double(let value):
            return try finite(value, path: path)
        case .decimal(let value):
            return try finite(value, path: path)
        case .null:
            return NSNull()
        case .array(let values):
            return try values.enumerated().map { index, value in
                try anyValue(from: value, path: "\(path)[\(index)]")
            }
        case .dictionary(let values):
            return try dictionary(from: values, path: path)
        }
    }

    static func finite(_ value: Double, path: String) throws -> Double {
        guard value.isFinite else {
            throw RequestParameterError.nonFiniteNumber(path: path)
        }
        return value
    }

    static func finite(_ value: Decimal, path: String) throws -> Decimal {
        guard value.isNaN == false else {
            throw RequestParameterError.nonFiniteNumber(path: path)
        }
        return value
    }
}
