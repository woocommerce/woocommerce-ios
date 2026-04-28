import Foundation

enum RESTResponseParsing {
    static func decodeJSON(_ data: Data) -> AnyCodableJSON? {
        try? JSONDecoder().decode(AnyCodableJSON.self, from: data)
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
}
