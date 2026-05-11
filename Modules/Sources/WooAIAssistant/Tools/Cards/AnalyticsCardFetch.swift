import Foundation

struct AnalyticsCardFetch: Sendable {
    private let client: WCRESTClient

    init(client: WCRESTClient) {
        self.client = client
    }

    func fetch(_ spec: AnalyticsCardSpec) async -> CardFetchOutcome {
        guard let bounds = AnalyticsDateBounds.bounds(start: spec.after, end: spec.before) else {
            return .rejected(.malformed)
        }
        var query: [String: String] = [
            "after": bounds.after,
            "before": bounds.before,
            "interval": spec.interval ?? "day",
            "_fields": "totals,intervals"
        ]
        if let currency = spec.currency?.trimmingCharacters(in: .whitespacesAndNewlines), !currency.isEmpty {
            query["currency"] = currency
        }
        let response = await client.request(method: "GET",
                                            path: spec.kind.reportPath,
                                            query: query,
                                            body: nil)
        guard HTTPStatusClassification.isSuccess(response.statusCode) else {
            return .rejected(.forStatusCode(response.statusCode))
        }
        guard let payload = RESTResponseParsing.decodeJSON(response.data) else {
            return .rejected(.internalError)
        }
        return .found(AnalyticsStatsSummary.make(from: payload, range: (spec.after, spec.before)))
    }
}
