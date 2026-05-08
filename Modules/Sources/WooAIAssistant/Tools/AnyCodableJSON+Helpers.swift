import Foundation

public extension AnyCodableJSON {

    func assistantString(_ key: String) -> String? {
        guard case .object(let dict) = self, let value = dict[key] else { return nil }
        switch value {
        case .string(let raw):
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        case .int(let int): return String(int)
        case .double(let double): return String(double)
        case .bool(let bool): return bool ? "true" : "false"
        default: return nil
        }
    }

    func assistantInt(_ key: String) -> Int64? {
        guard case .object(let dict) = self, let value = dict[key] else { return nil }
        switch value {
        case .int(let int): return int
        case .double(let double): return Int64(double)
        case .string(let string): return Int64(string.trimmingCharacters(in: .whitespacesAndNewlines))
        default: return nil
        }
    }

    func assistantArray(_ key: String) -> [AnyCodableJSON]? {
        guard case .object(let dict) = self, let value = dict[key],
              case .array(let items) = value else { return nil }
        return items
    }

    func assistantObject(_ key: String) -> AnyCodableJSON? {
        guard case .object(let dict) = self, let value = dict[key],
              case .object = value else { return nil }
        return value
    }
}
