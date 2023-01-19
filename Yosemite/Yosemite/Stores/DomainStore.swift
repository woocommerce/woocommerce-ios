import Foundation
import Networking
import WooFoundation
import protocol Storage.StorageManagerType

/// Handles `DomainAction`.
///
public final class DomainStore: Store {
    // Keeps a strong reference to remote to keep requests alive.
    private let remote: DomainRemoteProtocol

    public init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network, remote: DomainRemoteProtocol) {
        self.remote = remote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    public override convenience init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        let remote = DomainRemote(network: network)
        self.init(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
    }

    public override func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: DomainAction.self)
    }

    /// Called whenever a given Action is dispatched.
    ///
    public override func onAction(_ action: Action) {
        guard let action = action as? DomainAction else {
            assertionFailure("DomainStore received an unsupported action: \(action)")
            return
        }
        switch action {
        case .loadFreeDomainSuggestions(let query, let completion):
            loadFreeDomainSuggestions(query: query, completion: completion)
        case .loadPaidDomainSuggestions(let query, let completion):
            loadPaidDomainSuggestions(query: query, completion: completion)
        case .loadDomains(let siteID, let completion):
            loadDomains(siteID: siteID, completion: completion)
        }
    }
}

private extension DomainStore {
    func loadFreeDomainSuggestions(query: String, completion: @escaping (Result<[FreeDomainSuggestion], Error>) -> Void) {
        Task { @MainActor in
            let result = await Result { try await remote.loadFreeDomainSuggestions(query: query) }
            completion(result)
        }
    }

    func loadPaidDomainSuggestions(query: String, completion: @escaping (Result<[PaidDomainSuggestion], Error>) -> Void) {
        Task { @MainActor in
            do {
                // Fetches domain products and domain suggestions at the same time.
                async let domainProducts = remote.loadDomainProducts()
                async let domainSuggestions = remote.loadPaidDomainSuggestions(query: query)
                let domainProductsByID = try await domainProducts.reduce([Int64: DomainProduct](), { partialResult, product in
                    var productsByID = partialResult
                    productsByID[product.productID] = product
                    return productsByID
                })
                let paidDomainSuggestions: [PaidDomainSuggestion] = try await domainSuggestions.compactMap { domainSuggestion in
                    let productID = domainSuggestion.productID
                    guard let domainProduct = domainProductsByID[productID] else {
                        return nil
                    }
                    return PaidDomainSuggestion(productID: domainSuggestion.productID,
                                                name: domainSuggestion.name,
                                                term: domainProduct.term,
                                                cost: domainProduct.cost,
                                                saleCost: domainProduct.saleCost)
                }
                completion(.success(paidDomainSuggestions))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func loadDomains(siteID: Int64, completion: @escaping (Result<[SiteDomain], Error>) -> Void) {
        Task { @MainActor in
            let result = await Result { try await remote.loadDomains(siteID: siteID) }
            completion(result)
        }
    }
}
