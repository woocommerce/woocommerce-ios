import CocoaLumberjackSwift
import Foundation

/// REST-only card providers used by the headless harness, which has no
/// CoreData stack to back the storage-first probe in the production
/// providers. Each fetches via WC REST and decodes responses directly into
/// the typed card payloads.

final class RESTOrderCardProvider: CardEntityProvider {

    private let client: WCRESTClient

    init(client: WCRESTClient) {
        self.client = client
    }

    func fetch(refs: [CardRef]) async -> [CardRef: CardEntityOutcome] {
        guard refs.isEmpty == false else { return [:] }
        let response = await client.request(method: "GET",
                                            path: "wc/v3/orders",
                                            query: ["include": refs.map { String($0.id) }.joined(separator: ",")],
                                            body: nil)
        guard HTTPStatusClassification.isSuccess(response.statusCode) else {
            let reason = CardRefRejectionReason.forStatusCode(response.statusCode)
            return Dictionary(uniqueKeysWithValues: refs.map { ($0, .rejected(reason)) })
        }
        let decoded: [OrderCardPayload]
        do {
            let raw = try JSONDecoder().decode([RESTOrderResponse].self, from: response.data)
            decoded = raw.map { $0.toCardPayload() }
        } catch {
            DDLogError("RESTOrderCardProvider failed to decode response: \(error)")
            return Dictionary(uniqueKeysWithValues: refs.map { ($0, .rejected(.internalError)) })
        }
        let keyed = Dictionary(uniqueKeysWithValues: decoded.compactMap { payload -> (Int64, OrderCardPayload)? in
            guard let id = payload.id else { return nil }
            return (id, payload)
        })
        var outcomes: [CardRef: CardEntityOutcome] = [:]
        for ref in refs {
            guard let payload = keyed[ref.id] else {
                outcomes[ref] = .rejected(.notFound)
                continue
            }
            if payload.status == "trash" {
                outcomes[ref] = .rejected(.staleReference)
            } else {
                outcomes[ref] = .found(.order(payload))
            }
        }
        return outcomes
    }
}

final class RESTProductCardProvider: CardEntityProvider {

    private let client: WCRESTClient

    init(client: WCRESTClient) {
        self.client = client
    }

    func fetch(refs: [CardRef]) async -> [CardRef: CardEntityOutcome] {
        guard refs.isEmpty == false else { return [:] }
        let response = await client.request(method: "GET",
                                            path: "wc/v3/products",
                                            query: ["include": refs.map { String($0.id) }.joined(separator: ",")],
                                            body: nil)
        guard HTTPStatusClassification.isSuccess(response.statusCode) else {
            let reason = CardRefRejectionReason.forStatusCode(response.statusCode)
            return Dictionary(uniqueKeysWithValues: refs.map { ($0, .rejected(reason)) })
        }
        let decoded: [ProductCardPayload]
        do {
            decoded = try JSONDecoder().decode([ProductCardPayload].self, from: response.data)
        } catch {
            DDLogError("RESTProductCardProvider failed to decode response: \(error)")
            return Dictionary(uniqueKeysWithValues: refs.map { ($0, .rejected(.internalError)) })
        }
        let keyed = Dictionary(uniqueKeysWithValues: decoded.compactMap { payload -> (Int64, ProductCardPayload)? in
            guard let id = payload.id else { return nil }
            return (id, payload)
        })
        var outcomes: [CardRef: CardEntityOutcome] = [:]
        for ref in refs {
            guard let payload = keyed[ref.id] else {
                outcomes[ref] = .rejected(.notFound)
                continue
            }
            if payload.status == "trash" {
                outcomes[ref] = .rejected(.staleReference)
            } else {
                outcomes[ref] = .found(.product(payload))
            }
        }
        return outcomes
    }
}

/// WC has no batched variation endpoint, so each ref fans out to its own
/// nested GET. Parent id from the ref URL is injected into the payload when
/// the response omits it (WC variations responses do not carry parent_id).
final class RESTVariationCardProvider: CardEntityProvider {

    private let client: WCRESTClient

    init(client: WCRESTClient) {
        self.client = client
    }

    func fetch(refs: [CardRef]) async -> [CardRef: CardEntityOutcome] {
        guard refs.isEmpty == false else { return [:] }
        return await withTaskGroup(of: (CardRef, CardEntityOutcome).self) { group in
            for ref in refs {
                guard let parentID = ref.parentID else {
                    group.addTask { (ref, .rejected(.malformed)) }
                    continue
                }
                let path = "wc/v3/products/\(parentID)/variations/\(ref.id)"
                group.addTask { [client] in
                    let response = await client.request(method: "GET", path: path, query: nil, body: nil)
                    return (ref, Self.outcome(for: response, parentID: parentID))
                }
            }
            var outcomes: [CardRef: CardEntityOutcome] = [:]
            for await pair in group {
                outcomes[pair.0] = pair.1
            }
            return outcomes
        }
    }

    private static func outcome(for response: WCRESTResponse, parentID: Int64) -> CardEntityOutcome {
        guard HTTPStatusClassification.isSuccess(response.statusCode) else {
            return .rejected(CardRefRejectionReason.forStatusCode(response.statusCode))
        }
        let decoded: ProductVariationCardPayload
        do {
            decoded = try JSONDecoder().decode(ProductVariationCardPayload.self, from: response.data)
        } catch {
            DDLogError("RESTVariationCardProvider failed to decode response: \(error)")
            return .rejected(.internalError)
        }
        // WC variation responses omit `parent_id`; inject from the request URL.
        let withParent = ProductVariationCardPayload(
            id: decoded.id,
            parentID: decoded.parentID ?? parentID,
            name: decoded.name,
            sku: decoded.sku,
            price: decoded.price,
            regularPrice: decoded.regularPrice,
            salePrice: decoded.salePrice,
            stockStatus: decoded.stockStatus,
            stockQuantity: decoded.stockQuantity,
            images: decoded.images
        )
        // ProductVariationCardPayload has no `status` field; trash filtering for
        // variations therefore happens only against the cache path. The REST
        // path skipping it matches what WC's nested variation endpoint exposes.
        return .found(.variation(withParent))
    }
}

/// WC `/wc/v3/orders` returns no top-level `customer_name` / `customer_email` —
/// those live under `billing.first_name` / `billing.last_name` / `billing.email`.
/// Flatten them at decode time so the headless harness produces the same payload
/// the cache provider does (which reads them via `Order.billingAddress`).
private struct RESTOrderResponse: Decodable {
    let id: Int64?
    let number: String?
    let status: String?
    let total: String?
    let currency: String?
    let dateCreated: String?
    let customerName: String?
    let customerEmail: String?
    let customerID: Int64?
    let parentID: Int64?
    let billing: Billing?

    struct Billing: Decodable {
        let firstName: String?
        let lastName: String?
        let email: String?

        enum CodingKeys: String, CodingKey {
            case firstName = "first_name"
            case lastName = "last_name"
            case email
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, number, status, total, currency, billing
        case dateCreated = "date_created"
        case customerName = "customer_name"
        case customerEmail = "customer_email"
        case customerID = "customer_id"
        case parentID = "parent_id"
    }

    func toCardPayload() -> OrderCardPayload {
        let synthesizedName: String? = {
            if let customerName, customerName.isEmpty == false { return customerName }
            let combined = [billing?.firstName, billing?.lastName]
                .compactMap { $0?.isEmpty == false ? $0 : nil }
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespaces)
            return combined.isEmpty ? nil : combined
        }()
        return OrderCardPayload(id: id,
                                number: number,
                                status: status,
                                total: total,
                                currency: currency,
                                dateCreated: dateCreated,
                                customerName: synthesizedName,
                                customerEmail: customerEmail ?? billing?.email,
                                customerID: customerID,
                                parentID: parentID)
    }
}
