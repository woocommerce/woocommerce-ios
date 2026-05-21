import Foundation
import CocoaLumberjackSwift

struct LowInStockReportRunner {

    let client: WCRESTClient

    /// Hits wc-analytics' lowstock report (authoritative for WC's low-stock criteria),
    /// then enriches the ids via `/products?include=` (top-level products) and
    /// `/products/{parent}/variations?include=` (variation rows) so the merchant gets back the
    /// full shape regardless of which kind the report surfaced. Returns nil to signal
    /// "endpoint unavailable, fall back to heuristic".
    func run(args: ProductsListTool.Args, perPage: Int) async -> ToolResult? {
        let page = max(1, args.page ?? 1)
        let reportQuery: [String: String] = [
            "type": "lowstock",
            "per_page": String(perPage),
            "page": String(page)
        ]
        let report = await client.request(method: "GET",
                                          path: "wc-analytics/reports/stock",
                                          query: reportQuery,
                                          body: nil)
        guard HTTPStatusClassification.isSuccess(report.statusCode) else { return nil }
        guard let reportPayload = RESTResponseParsing.decodeJSON(report.data),
              let reportRows = RESTResponseParsing.arrayItems(reportPayload) else {
            return nil
        }
        let split = Self.splitReportRows(reportRows)
        if split.orderedIDs.isEmpty {
            return successResult(tagged: [], canLoadMore: false)
        }
        async let productLookup = enrichProducts(ids: split.productIDs)
        async let variationLookup = enrichVariations(grouped: split.variationsByParent)
        let products = await productLookup
        let variations = await variationLookup
        if products == nil && split.productIDs.isEmpty == false {
            return .failed(.init(toolName: ProductsListTool.name,
                                 kind: .toolFailed,
                                 reason: "Could not enrich low-stock product rows"))
        }
        let tagged = combine(orderedIDs: split.orderedIDs,
                             products: products,
                             variations: variations,
                             args: args)
        // Source page being full implies more low-stock pages may exist; post-filtering can shrink
        // the visible window below per_page but does not change that signal.
        let canLoadMore = reportRows.count >= perPage
        return successResult(tagged: tagged, canLoadMore: canLoadMore)
    }

    private func successResult(tagged: [(AnyCodableJSON, ProductsListSummary.RowKind)],
                               canLoadMore: Bool) -> ToolResult {
        let summary = ProductsListSummary.make(tagged: tagged, canLoadMore: canLoadMore)
        return .success(.init(toolName: ProductsListTool.name,
                              structured: LLMPayloadCap.capped(summary, toolName: ProductsListTool.name),
                              uiStructured: nil))
    }

    private func combine(orderedIDs: [ReportEntry],
                         products: [Int: AnyCodableJSON]?,
                         variations: [Int: AnyCodableJSON],
                         args: ProductsListTool.Args) -> [(AnyCodableJSON, ProductsListSummary.RowKind)] {
        var tagged: [(AnyCodableJSON, ProductsListSummary.RowKind)] = []
        for entry in orderedIDs {
            switch entry.kind {
            case .product:
                guard let row = products?[entry.id] else { continue }
                let filtered = ProductsListTool.applyLowInStockPostFilters(rows: [row],
                                                                           args: args,
                                                                           allowCategoryFilter: true)
                guard let kept = filtered.first else { continue }
                tagged.append((kept, .product))
            case .variation:
                guard let row = variations[entry.id] else { continue }
                let filtered = ProductsListTool.applyLowInStockPostFilters(rows: [row],
                                                                           args: args,
                                                                           allowCategoryFilter: false)
                guard let kept = filtered.first else { continue }
                tagged.append((kept, .variation))
            }
        }
        return tagged
    }

    struct ReportEntry {
        let id: Int
        let kind: ProductsListSummary.RowKind
    }

    struct ReportSplit {
        let orderedIDs: [ReportEntry]
        let productIDs: [Int]
        let variationsByParent: [Int: [Int]]
    }

    private static func splitReportRows(_ rows: [AnyCodableJSON]) -> ReportSplit {
        var ordered: [ReportEntry] = []
        var productIDs: [Int] = []
        var variationsByParent: [Int: [Int]] = [:]
        for row in rows {
            guard let raw = RESTResponseParsing.intField(row, "id") else { continue }
            let id = Int(raw)
            let parentID = Int(RESTResponseParsing.intField(row, "parent_id") ?? 0)
            if parentID > 0 {
                ordered.append(ReportEntry(id: id, kind: .variation))
                variationsByParent[parentID, default: []].append(id)
            } else {
                ordered.append(ReportEntry(id: id, kind: .product))
                productIDs.append(id)
            }
        }
        return ReportSplit(orderedIDs: ordered,
                           productIDs: productIDs,
                           variationsByParent: variationsByParent)
    }

    /// Returns nil when the enrichment HTTP call fails - distinguishing "no products requested"
    /// (empty map) from "WC returned a non-2xx" so the caller can surface a failure.
    private func enrichProducts(ids: [Int]) async -> [Int: AnyCodableJSON]? {
        guard !ids.isEmpty else { return [:] }
        return await fetchByInclude(path: "wc/v3/products", ids: ids)
    }

    /// One parent's variations failing to load shouldn't fail the whole request - merchants
    /// rightly expect partial results over an opaque error when several parents are in play.
    private func enrichVariations(grouped: [Int: [Int]]) async -> [Int: AnyCodableJSON] {
        guard !grouped.isEmpty else { return [:] }
        let client = client
        let pairs = Array(grouped.map { ($0.key, $0.value) })
        let partials = await BoundedTaskGroup.runOrdered(pairs,
                                                         limit: ProductsUpdateTool.concurrencyCap) { pair in
            let runner = LowInStockReportRunner(client: client)
            if let result = await runner.fetchByInclude(path: "wc/v3/products/\(pair.0)/variations",
                                                        ids: pair.1) {
                return result
            }
            DDLogError("\(ProductsListTool.name): low-stock variation enrichment failed for parent \(pair.0)")
            return [Int: AnyCodableJSON]()
        }
        return partials.reduce(into: [Int: AnyCodableJSON]()) { merged, partial in
            merged.merge(partial) { _, new in new }
        }
    }

    private func fetchByInclude(path: String, ids: [Int]) async -> [Int: AnyCodableJSON]? {
        let response = await client.request(
            method: "GET",
            path: path,
            query: [
                "include": ids.map(String.init).joined(separator: ","),
                "per_page": String(ids.count),
                "orderby": "include"
            ],
            body: nil
        )
        guard HTTPStatusClassification.isSuccess(response.statusCode),
              let payload = RESTResponseParsing.decodeJSON(response.data),
              let rows = RESTResponseParsing.arrayItems(payload) else {
            return nil
        }
        return Self.keyByID(rows: rows)
    }

    private static func keyByID(rows: [AnyCodableJSON]) -> [Int: AnyCodableJSON] {
        var keyed: [Int: AnyCodableJSON] = [:]
        for row in rows {
            guard let identifier = RESTResponseParsing.intField(row, "id") else { continue }
            keyed[Int(identifier)] = row
        }
        return keyed
    }
}
