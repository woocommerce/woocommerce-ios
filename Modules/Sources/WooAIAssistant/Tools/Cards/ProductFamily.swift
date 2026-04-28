import Foundation

public struct ProductFamily: CardFamily {
    public static let id: CardFamilyID = .product

    public init() {}

    public func fetch(id: Int64, client: WCRESTClient) async -> CardFetchOutcome {
        let response = await client.request(method: "GET",
                                            path: "wc/v3/products/\(id)",
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
        // Soft-deleted catalog rows come back as `status: "trash"` with a 200.
        if RESTResponseParsing.stringField(pruned, "status") == "trash" {
            return .rejected(.staleReference)
        }
        return .found(pruned)
    }

    public func summarize(_ entity: AnyCodableJSON) -> AnyCodableJSON {
        RESTResponseParsing.project(entity, keys: ["id", "name", "sku", "price", "stock_status"])
    }
}
