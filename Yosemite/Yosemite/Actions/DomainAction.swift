import Foundation

// MARK: - DomainAction: Defines all of the Actions supported by the DomainStore.
//
public enum DomainAction: Action {
    case loadFreeDomainSuggestions(query: String, completion: (Result<[FreeDomainSuggestion], Error>) -> Void)
    case loadPaidDomainSuggestions(query: String, completion: (Result<[PaidDomainSuggestion], Error>) -> Void)
    case loadDomains(siteID: Int64, completion: (Result<[SiteDomain], Error>) -> Void)
}

/// Necessary data for the domain selector flow with paid domains.
public struct PaidDomainSuggestion: Equatable {
    /// ID of the WPCOM product.
    public let productID: Int64
    /// Domain name.
    public let name: String
    /// Duration of the product subscription (e.g. "year"), localized on the backend.
    public let term: String
    /// Cost string including the currency.
    public let cost: String
    /// Optional sale cost string including the currency.
    public let saleCost: String?
}
