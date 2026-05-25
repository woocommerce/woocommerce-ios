import Foundation

enum CustomersListSummary {
    static func make(from rows: [AnyCodableJSON]) -> AnyCodableJSON {
        var matches: [AnyCodableJSON] = []
        for row in rows {
            guard let id = RESTResponseParsing.intField(row, "id") else { continue }
            var match: [String: AnyCodableJSON] = ["id": .int(id)]
            putString(row, key: "first_name", into: &match)
            putString(row, key: "last_name", into: &match)
            putString(row, key: "email", into: &match)
            putString(row, key: "username", into: &match)
            putString(row, key: "date_created", into: &match)
            putString(row, key: "role", into: &match)
            putString(row, key: "avatar_url", into: &match)
            if let billing = compactBilling(row) {
                match["billing"] = billing
            }
            if let shipping = compactShipping(row) {
                match["shipping"] = shipping
            }
            matches.append(.object(match))
        }
        return .object([
            "count": .int(Int64(rows.count)),
            "matches": .array(matches)
        ])
    }

    private static func putString(_ row: AnyCodableJSON,
                                  key: String,
                                  into match: inout [String: AnyCodableJSON]) {
        if let value = RESTResponseParsing.stringField(row, key), !value.isEmpty {
            match[key] = .string(value)
        }
    }

    private static func compactBilling(_ row: AnyCodableJSON) -> AnyCodableJSON? {
        guard let billing = RESTResponseParsing.objectField(row, "billing") else { return nil }
        var out: [String: AnyCodableJSON] = [:]
        for key in ["phone", "city", "country"] {
            if let value = RESTResponseParsing.stringField(billing, key), !value.isEmpty {
                out[key] = .string(value)
            }
        }
        return out.isEmpty ? nil : .object(out)
    }

    private static func compactShipping(_ row: AnyCodableJSON) -> AnyCodableJSON? {
        guard let shipping = RESTResponseParsing.objectField(row, "shipping") else { return nil }
        var out: [String: AnyCodableJSON] = [:]
        for key in ["city", "country"] {
            if let value = RESTResponseParsing.stringField(shipping, key), !value.isEmpty {
                out[key] = .string(value)
            }
        }
        return out.isEmpty ? nil : .object(out)
    }
}
