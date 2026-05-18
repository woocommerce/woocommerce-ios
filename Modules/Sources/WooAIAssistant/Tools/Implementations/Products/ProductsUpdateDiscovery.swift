import Foundation

struct ProductsUpdateDiscovery {

    let client: WCRESTClient

    /// Chunked `GET /products?include=ids` pre-fetch. Variations are not surfaced and are
    /// resolved by per-id GETs inside the planner instead.
    func discover(entries: [ProductsUpdateTool.Entry]) async -> [Int: AnyCodableJSON] {
        let unique = Array(Set(entries.map(\.id)))
        guard !unique.isEmpty else { return [:] }
        let chunks = unique.chunked(into: ProductsUpdateTool.discoveryChunkSize)
        let client = client
        let partials = await BoundedTaskGroup.runOrdered(chunks,
                                                         limit: ProductsUpdateTool.concurrencyCap) { chunk in
            await Self.fetchDiscoveryChunk(ids: chunk, client: client)
        }
        var results: [Int: AnyCodableJSON] = [:]
        for partial in partials {
            results.merge(partial) { _, new in new }
        }
        return results
    }

    private static func fetchDiscoveryChunk(ids: [Int],
                                            client: WCRESTClient) async -> [Int: AnyCodableJSON] {
        let response = await client.request(
            method: "GET",
            path: "wc/v3/products",
            query: [
                "include": ids.map(String.init).joined(separator: ","),
                "per_page": String(ProductsUpdateTool.discoveryChunkSize),
                "orderby": "include"
            ],
            body: nil
        )
        guard HTTPStatusClassification.isSuccess(response.statusCode),
              let payload = RESTResponseParsing.decodeJSON(response.data),
              let rows = RESTResponseParsing.arrayItems(payload) else {
            return [:]
        }
        var keyed: [Int: AnyCodableJSON] = [:]
        for row in rows {
            guard let identifier = RESTResponseParsing.intField(row, "id") else { continue }
            keyed[Int(identifier)] = row
        }
        return keyed
    }
}
