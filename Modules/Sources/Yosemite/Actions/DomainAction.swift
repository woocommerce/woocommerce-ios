import Foundation
import class WooFoundation.CurrencySettings

// MARK: - DomainAction: Defines all of the Actions supported by the DomainStore.
//
public enum DomainAction: Action {
    case loadFreeDomainSuggestions(query: String, completion: (Result<[FreeDomainSuggestion], Error>) -> Void)
    case loadPaidDomainSuggestions(query: String, currencySettings: CurrencySettings, completion: (Result<[PaidDomainSuggestion], Error>) -> Void)
    case loadDomains(siteID: Int64, completion: (Result<[SiteDomain], Error>) -> Void)
    case createDomainShoppingCart(siteID: Int64,
                                  domain: DomainToPurchase,
                                  completion: (Result<Void, Error>) -> Void)
    case redeemDomainCredit(siteID: Int64,
                            domain: DomainToPurchase,
                            contactInfo: DomainContactInfo,
                            completion: (Result<Void, Error>) -> Void)
    case loadDomainContactInfo(completion: (Result<DomainContactInfo, Error>) -> Void)
    case validate(domainContactInfo: DomainContactInfo, domain: String, completion: (Result<Void, Error>) -> Void)
}

/// Necessary data for the domain selector flow with paid domains.
public struct PaidDomainSuggestion: Equatable {
    /// ID of the WPCOM product.
    public let productID: Int64
    /// Whether there is privacy support. Used when creating a cart with a domain product.
    public let supportsPrivacy: Bool
    /// Domain name.
    public let name: String
    /// Duration of the product subscription (e.g. "year"), localized on the backend.
    public let term: String
    /// Cost string including the currency.
    public let cost: String
    /// Optional sale cost string including the currency.
    public let saleCost: String?
    /// Whether the domain is a premium domain. A premium domain cannot be redeemed with domain credit.
    public let isPremium: Bool

    public init(productID: Int64, supportsPrivacy: Bool, name: String, term: String, cost: String, saleCost: String? = nil, isPremium: Bool) {
        self.productID = productID
        self.supportsPrivacy = supportsPrivacy
        self.name = name
        self.term = term
        self.cost = cost
        self.saleCost = saleCost
        self.isPremium = isPremium
    }
}
