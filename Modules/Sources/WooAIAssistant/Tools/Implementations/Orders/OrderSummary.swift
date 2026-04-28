import Foundation

enum OrderSummary {
    static func make(from entity: AnyCodableJSON) -> AnyCodableJSON {
        var fields: [String: AnyCodableJSON] = [:]
        for key in ["id", "number", "status", "total", "currency", "date_created", "payment_method_title"] {
            if case .object(let dict) = entity, let value = dict[key] {
                fields[key] = value
            }
        }
        if let billing = RESTResponseParsing.objectField(entity, "billing") {
            if let name = customerName(from: billing) {
                fields["customer_name"] = .string(name)
            }
            if let email = RESTResponseParsing.stringField(billing, "email") {
                fields["customer_email"] = .string(email)
            }
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
