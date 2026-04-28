import Foundation

enum OrderSummary {
    static func make(from entity: AnyCodableJSON) -> AnyCodableJSON {
        let projected = RESTResponseParsing.project(entity,
                                                    keys: [
                                                        "id", "number", "status", "total", "currency",
                                                        "date_created", "payment_method_title"
                                                    ])
        guard case .object(var fields) = projected else { return projected }
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
