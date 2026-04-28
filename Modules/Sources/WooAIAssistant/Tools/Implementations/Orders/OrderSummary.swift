import Foundation

enum OrderSummary {
    static func make(from entity: AnyCodableJSON) -> AnyCodableJSON {
        var fields: [String: AnyCodableJSON] = [:]
        for key in ["id", "number", "status", "total", "currency", "date_created"] {
            if case .object(let dict) = entity, let value = dict[key] {
                fields[key] = value
            }
        }
        if let billing = RESTResponseParsing.objectField(entity, "billing"),
           let name = customerName(from: billing) {
            fields["customer_name"] = .string(name)
        }
        return .object(fields)
    }

    private static func customerName(from billing: AnyCodableJSON) -> String? {
        let first = RESTResponseParsing.stringField(billing, "first_name") ?? ""
        let last = RESTResponseParsing.stringField(billing, "last_name") ?? ""
        let combined = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        return combined.isEmpty ? nil : combined
    }
}
