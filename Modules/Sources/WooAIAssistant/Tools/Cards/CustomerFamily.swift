import Foundation

public struct CustomerFamily: CardFamily {
    public static let id: CardFamilyID = .customer

    public init() {}

    /// `customers/{id}` requires `manage_woocommerce`, which most shop_manager
    /// roles lack; `customers?include=` works under `read_customers` and is
    /// the universal path even for permissive roles.
    public func fetch(id: Int64, client: WCRESTClient) async -> CardFetchOutcome {
        let response = await client.request(method: "GET",
                                            path: "wc/v3/customers",
                                            query: ["include": String(id)],
                                            body: nil,
                                            headers: nil)
        guard HTTPStatusClassification.isSuccess(response.statusCode) else {
            return .rejected(CardFetchOutcome.rejection(forStatusCode: response.statusCode))
        }
        guard let payload = RESTResponseParsing.decodeJSON(response.data),
              let rows = RESTResponseParsing.arrayItems(payload) else {
            return .rejected(.internalError)
        }
        guard let row = rows.first else {
            return .rejected(.notFound)
        }
        return .found(RESTPayloadPruning.prune(row))
    }

    public func summarize(_ entity: AnyCodableJSON) -> AnyCodableJSON {
        var fields: [String: AnyCodableJSON] = [:]
        guard case .object(let dict) = entity else { return .object(fields) }
        for key in ["id", "first_name", "last_name", "email", "orders_count"] {
            if let value = dict[key] { fields[key] = value }
        }
        return .object(fields)
    }
}
