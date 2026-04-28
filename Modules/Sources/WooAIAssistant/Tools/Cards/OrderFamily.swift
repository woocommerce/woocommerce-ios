import Foundation

public struct OrderFamily: CardFamily {
    public static let id: CardFamilyID = .order

    public init() {}

    public func fetch(id: Int64, client: WCRESTClient) async -> CardFetchOutcome {
        let response = await client.request(method: "GET",
                                            path: "wc/v3/orders/\(id)",
                                            query: nil,
                                            body: nil,
                                            headers: nil)
        guard HTTPStatusClassification.isSuccess(response.statusCode) else {
            return .rejected(CardFetchOutcome.rejection(forStatusCode: response.statusCode))
        }
        guard let entity = RESTResponseParsing.decodeJSON(response.data) else {
            return .rejected(.internalError)
        }
        let pruned = RESTPayloadPruning.prune(entity)
        // WC returns `status: "trash"` with a 200 for soft-deleted rows; treat
        // as stale rather than render a card the merchant cannot act on.
        if RESTResponseParsing.stringField(pruned, "status") == "trash" {
            return .rejected(.staleReference)
        }
        return .found(pruned)
    }

    public func summarize(_ entity: AnyCodableJSON) -> AnyCodableJSON {
        let projected = RESTResponseParsing.project(entity,
                                                    keys: ["id", "number", "status", "total", "currency", "date_created"])
        guard case .object(var fields) = projected else { return projected }
        if let billing = RESTResponseParsing.objectField(entity, "billing"),
           let name = customerName(from: billing) {
            fields["customer_name"] = .string(name)
        }
        return .object(fields)
    }

    private func customerName(from billing: AnyCodableJSON) -> String? {
        let first = RESTResponseParsing.stringField(billing, "first_name") ?? ""
        let last = RESTResponseParsing.stringField(billing, "last_name") ?? ""
        let combined = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        return combined.isEmpty ? nil : combined
    }
}
