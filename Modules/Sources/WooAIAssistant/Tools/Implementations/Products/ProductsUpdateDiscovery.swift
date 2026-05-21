import Foundation

struct ProductsUpdateDiscovery {

    let client: WCRESTClient

    /// Chunked `GET /products?include=ids` pre-fetch. Variation-target entries skip discovery
    /// entirely; their routing comes from the explicit target object so the planner can fast-path
    /// directly to the variations batch without probing `/products`.
    func discover(entries: [ProductsUpdateTool.Entry]) async -> [Int: AnyCodableJSON] {
        let productEntries = entries.filter { $0.target.kind == .product }
        let unique = Array(Set(productEntries.map(\.target.id)))
        guard !unique.isEmpty else { return [:] }
        let chunks = unique.chunked(into: ProductsUpdateTool.discoveryChunkSize)
        let partials = await BoundedTaskGroup.runOrdered(chunks,
                                                         limit: ProductsUpdateTool.concurrencyCap) { chunk in
            await self.fetchDiscoveryChunk(ids: chunk)
        }
        var results: [Int: AnyCodableJSON] = [:]
        for partial in partials {
            results.merge(partial) { _, new in new }
        }
        return results
    }

    private func fetchDiscoveryChunk(ids: [Int]) async -> [Int: AnyCodableJSON] {
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
