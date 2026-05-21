import Foundation

struct ProductsUpdateDiscovery {

    let client: WCRESTClient

    /// Chunked `GET /products?include=ids` pre-fetch. Variation-target entries skip discovery
    /// entirely; their routing comes from the explicit target object so the planner can fast-path
    /// directly to the variations batch without probing `/products`.
    func discover(entries: [ProductsUpdateTool.Entry]) async -> DiscoveryResult {
        let productEntries = entries.filter { $0.target.kind == .product }
        let unique = Array(Set(productEntries.map(\.target.id)))
        guard !unique.isEmpty else { return DiscoveryResult(captured: [:], unreachable: [:]) }
        let chunks = unique.chunked(into: ProductsUpdateTool.discoveryChunkSize)
        let partials = await BoundedTaskGroup.runOrdered(chunks,
                                                         limit: ProductsUpdateTool.concurrencyCap) { chunk in
            await self.fetchDiscoveryChunk(ids: chunk)
        }
        var captured: [Int: AnyCodableJSON] = [:]
        var unreachable: [Int: Int] = [:]
        for partial in partials {
            captured.merge(partial.captured) { _, new in new }
            unreachable.merge(partial.unreachable) { _, new in new }
        }
        return DiscoveryResult(captured: captured, unreachable: unreachable)
    }

    private func fetchDiscoveryChunk(ids: [Int]) async -> DiscoveryResult {
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
        // A failed chunk marks every id in it unreachable so the planner refuses rather than
        // re-probing each id one by one (the per-id storm this consolidation removes).
        guard HTTPStatusClassification.isSuccess(response.statusCode),
              let payload = RESTResponseParsing.decodeJSON(response.data),
              let rows = RESTResponseParsing.arrayItems(payload) else {
            var unreachable: [Int: Int] = [:]
            for id in ids {
                unreachable[id] = response.statusCode
            }
            return DiscoveryResult(captured: [:], unreachable: unreachable)
        }
        var captured: [Int: AnyCodableJSON] = [:]
        for row in rows {
            guard let identifier = RESTResponseParsing.intField(row, "id") else { continue }
            captured[Int(identifier)] = row
        }
        return DiscoveryResult(captured: captured, unreachable: [:])
    }
}
