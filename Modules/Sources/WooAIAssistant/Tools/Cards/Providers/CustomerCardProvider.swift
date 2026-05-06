import CocoaLumberjackSwift
import Foundation

/// Customer entries are sparse in CoreData (Android also keeps customer REST-only).
/// `customers/{id}` requires `manage_woocommerce`; `customers?include=` works under
/// `read_customers` and is the universal path even for permissive shop_manager roles.
public final class CustomerCardProvider: CardEntityProvider {

    private let client: WCRESTClient

    public init(client: WCRESTClient) {
        self.client = client
    }

    public func fetch(refs: [CardRef]) async -> [CardRef: CardEntityOutcome] {
        guard refs.isEmpty == false else { return [:] }

        let ids = refs.map { String($0.id) }.joined(separator: ",")
        let response = await client.request(method: "GET",
                                            path: "wc/v3/customers",
                                            query: ["include": ids],
                                            body: nil)

        guard HTTPStatusClassification.isSuccess(response.statusCode) else {
            let reason = CardRefRejectionReason.forStatusCode(response.statusCode)
            return Dictionary(uniqueKeysWithValues: refs.map { ($0, .rejected(reason)) })
        }

        let decoded: [CustomerCardPayload]
        do {
            decoded = try JSONDecoder().decode([CustomerCardPayload].self, from: response.data)
        } catch {
            DDLogError("CustomerCardProvider failed to decode response: \(error)")
            return Dictionary(uniqueKeysWithValues: refs.map { ($0, .rejected(.internalError)) })
        }

        let keyed = Dictionary(uniqueKeysWithValues: decoded.compactMap { payload -> (Int64, CustomerCardPayload)? in
            guard let id = payload.id else { return nil }
            return (id, payload)
        })
        var outcomes: [CardRef: CardEntityOutcome] = [:]
        for ref in refs {
            if let payload = keyed[ref.id] {
                outcomes[ref] = .found(.customer(payload))
            } else {
                outcomes[ref] = .rejected(.notFound)
            }
        }
        return outcomes
    }
}
