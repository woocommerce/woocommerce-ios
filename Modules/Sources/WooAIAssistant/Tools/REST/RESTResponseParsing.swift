import Foundation
import CocoaLumberjackSwift

enum RESTResponseParsing {
    static func decodeJSON(_ data: Data) -> AnyCodableJSON? {
        do {
            return try JSONDecoder().decode(AnyCodableJSON.self, from: data)
        } catch {
            DDLogError("⛔️ RESTResponseParsing failed to decode JSON: \(error)")
            return nil
        }
    }

    static func arrayItems(_ value: AnyCodableJSON) -> [AnyCodableJSON]? {
        if case .array(let items) = value { return items }
        return nil
    }

    static func objectField(_ value: AnyCodableJSON, _ key: String) -> AnyCodableJSON? {
        if case .object(let dict) = value { return dict[key] }
        return nil
    }

    static func intField(_ value: AnyCodableJSON, _ key: String) -> Int64? {
        guard case .object(let dict) = value, let raw = dict[key] else { return nil }
        switch raw {
        case .int(let int): return int
        case .double(let double): return Int64(double)
        case .string(let string): return Int64(string)
        default: return nil
        }
    }

    static func stringField(_ value: AnyCodableJSON, _ key: String) -> String? {
        guard case .object(let dict) = value, case .string(let text) = dict[key] else { return nil }
        return text
    }

    static func decimalField(_ value: AnyCodableJSON, _ key: String) -> Decimal? {
        guard case .object(let dict) = value, let raw = dict[key] else { return nil }
        switch raw {
        case .string(let text): return Decimal(string: text)
        case .double(let double): return Decimal(double)
        case .int(let int): return Decimal(int)
        default: return nil
        }
    }

    /// Rounds to 2 decimal places to keep summary payloads compact regardless of
    /// the upstream price precision.
    static func formatDecimal(_ value: Decimal) -> String {
        var copy = value
        var rounded = Decimal()
        NSDecimalRound(&rounded, &copy, 2, .plain)
        return NSDecimalNumber(decimal: rounded).stringValue
    }

    static func decimalRange(_ values: [Decimal], currency: String? = nil) -> AnyCodableJSON? {
        guard let min = values.min(), let max = values.max() else { return nil }
        var range: [String: AnyCodableJSON] = [
            "min": .string(formatDecimal(min)),
            "max": .string(formatDecimal(max))
        ]
        if let currency { range["currency"] = .string(currency) }
        return .object(range)
    }
}
