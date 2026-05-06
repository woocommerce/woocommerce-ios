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
            decoded = try JSONDecoder().decode([OrderCardPayload].self, from: response.data)
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
