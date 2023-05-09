import Foundation
import Networking
import WooFoundation
import protocol Storage.StorageManagerType

/// Handles `DomainAction`.
///
public final class DomainStore: Store {
    // Keeps a strong reference to remotes to keep requests alive.
    private let remote: DomainRemoteProtocol
    private let paymentRemote: PaymentRemoteProtocol

    public init(dispatcher: Dispatcher,
                storageManager: StorageManagerType,
                network: Network,
                remote: DomainRemoteProtocol,
                paymentRemote: PaymentRemoteProtocol) {
        self.remote = remote
        self.paymentRemote = paymentRemote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    public override convenience init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        let remote = DomainRemote(network: network)
        let paymentRemote = PaymentRemote(network: network)
        self.init(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote, paymentRemote: paymentRemote)
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
        case .loadPaidDomainSuggestions(let query, let currencySettings, let completion):
            loadPaidDomainSuggestions(query: query, currencySettings: currencySettings, completion: completion)
        case .loadDomains(let siteID, let completion):
            loadDomains(siteID: siteID, completion: completion)
        case .createDomainShoppingCart(let siteID, let domain, let completion):
            createDomainShoppingCart(siteID: siteID, domain: domain, completion: completion)
        case .redeemDomainCredit(let siteID, let domain, let contactInfo, let completion):
            redeemDomainCredit(siteID: siteID, domain: domain, contactInfo: contactInfo, completion: completion)
        case .loadDomainContactInfo(let completion):
            loadDomainContactInfo(completion: completion)
        case .validate(let domainContactInfo, let domain, let completion):
            validate(domainContactInfo: domainContactInfo, domain: domain, completion: completion)
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

    func loadPaidDomainSuggestions(query: String, currencySettings: CurrencySettings, completion: @escaping (Result<[PaidDomainSuggestion], Error>) -> Void) {
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

                let suggestions = try await domainSuggestions
                let pricesByPremiumDomainName = await loadPriceForPremiumDomains(suggestions)
                let paidDomainSuggestions: [PaidDomainSuggestion] = suggestions.compactMap { domainSuggestion -> PaidDomainSuggestion? in
                    let productID = domainSuggestion.productID
                    guard let domainProduct = domainProductsByID[productID] else {
                        return nil
                    }

                    if domainSuggestion.isPremium == true {
                        guard let price = pricesByPremiumDomainName[domainSuggestion.name] else {
                            return nil
                        }
                        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
                        return PaidDomainSuggestion(productID: domainSuggestion.productID,
                                                    supportsPrivacy: domainSuggestion.supportsPrivacy,
                                                    name: domainSuggestion.name,
                                                    term: domainProduct.term,
                                                    cost: currencyFormatter.formatAmount(price.cost, with: price.currency) ?? "",
                                                    saleCost: price.saleCost.map { currencyFormatter.formatAmount($0, with: price.currency) ?? "" },
                                                    isPremium: true)
                    } else {
                        return PaidDomainSuggestion(productID: domainSuggestion.productID,
                                                    supportsPrivacy: domainSuggestion.supportsPrivacy,
                                                    name: domainSuggestion.name,
                                                    term: domainProduct.term,
                                                    cost: domainProduct.cost,
                                                    saleCost: domainProduct.saleCost,
                                                    isPremium: false)
                    }
                }
                completion(.success(paidDomainSuggestions))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Loads the price asynchronously for each premium domain in the domain suggestions.
    /// - Returns: A dictionary that maps a domain name to its price.
    func loadPriceForPremiumDomains(_ domains: [Networking.PaidDomainSuggestion]) async -> [String: PremiumDomainPrice] {
        await withTaskGroup(of: (String, PremiumDomainPrice)?.self, returning: [String: PremiumDomainPrice].self) { group in
            var pricesByDomainName: [String: PremiumDomainPrice] = [:]

            // For each domain suggestion, adds a new task to the group to load the price if the domain is a premium domain.
            for domain in domains {
                if domain.isPremium == true {
                    group.addTask {
                        do {
                            let price = try await self.remote.loadPremiumDomainPrice(domain: domain.name)
                            return (domain.name, price)
                        } catch {
                            // If the domain price fetching fails, we don't want to fail the whole domain suggestions request.
                            DDLogError("⛔️ Error loading the price for premium domain \(domain.name): \(error)")
                            return nil
                        }
                    }
                }
            }

            for await nameAndPrice in group.compactMap({ $0 }) {
                pricesByDomainName[nameAndPrice.0] = nameAndPrice.1
            }
            return pricesByDomainName
        }
    }

    func loadDomains(siteID: Int64, completion: @escaping (Result<[SiteDomain], Error>) -> Void) {
        Task { @MainActor in
            let result = await Result { try await remote.loadDomains(siteID: siteID) }
            completion(result)
        }
    }

    func createDomainShoppingCart(siteID: Int64,
                                  domain: DomainToPurchase,
                                  completion: @escaping (Result<Void, Error>) -> Void) {
        Task { @MainActor in
            let result = await Result {
                try await paymentRemote.createCart(siteID: siteID,
                                                   domain: .init(name: domain.name,
                                                                 productID: domain.productID,
                                                                 supportsPrivacy: domain.supportsPrivacy),
                                                   isTemporary: false)
            }
            completion(result.map { _ in () })
        }
    }

    func redeemDomainCredit(siteID: Int64,
                            domain: DomainToPurchase,
                            contactInfo: DomainContactInfo,
                            completion: @escaping (Result<Void, Error>) -> Void) {
        Task { @MainActor in
            do {
                let cart = try await paymentRemote.createCart(siteID: siteID,
                                                              domain: .init(name: domain.name,
                                                                            productID: domain.productID,
                                                                            supportsPrivacy: domain.supportsPrivacy),
                                                              isTemporary: true)
                try await paymentRemote.checkoutCartWithDomainCredit(cart: cart, contactInfo: contactInfo)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func loadDomainContactInfo(completion: @escaping (Result<DomainContactInfo, Error>) -> Void) {
        Task { @MainActor in
            let result = await Result { try await remote.loadDomainContactInfo() }
            completion(result)
        }
    }

    func validate(domainContactInfo: DomainContactInfo, domain: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task { @MainActor in
            let result = await Result { try await remote.validate(domainContactInfo: domainContactInfo, domain: domain) }
            completion(result)
        }
    }
}
