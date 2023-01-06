import Foundation

/// Protocol for `DomainRemote` mainly used for mocking.
public protocol DomainRemoteProtocol {
    /// Loads domain suggestions that are free (`*.wordpress.com` only) based on the query.
    /// - Parameter query: What the domain suggestions are based on.
    /// - Returns: The result of free domain suggestions.
    func loadFreeDomainSuggestions(query: String) async throws -> [FreeDomainSuggestion]
}

/// Domain: Remote Endpoints
///
public class DomainRemote: Remote, DomainRemoteProtocol {
    public func loadFreeDomainSuggestions(query: String) async throws -> [FreeDomainSuggestion] {
        let path = Path.domainSuggestions
        let parameters: [String: Any] = [
            ParameterKey.query: query,
            ParameterKey.quantity: Defaults.domainSuggestionsQuantity,
            ParameterKey.wordPressDotComSubdomainsOnly: true
        ]
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: path, parameters: parameters)
        return try await enqueue(request)
    }
}

/// Necessary data for a free domain suggestion.
public struct FreeDomainSuggestion: Decodable, Equatable {
    /// Domain name.
    public let name: String
    /// Theoretically `true` for all domains in the result, but the client side can still filter any exceptions in the UI.
    public let isFree: Bool

    public init(name: String, isFree: Bool) {
        self.name = name
        self.isFree = isFree
    }

    private enum CodingKeys: String, CodingKey {
        case name = "domain_name"
        case isFree = "is_free"
    }
}

/// Necessary data for a site's domain.
public struct SiteDomain: Decodable, Equatable {
    /// Domain name.
    public let name: String

    /// Whether the domain is the site's primary domain.
    public let isPrimary: Bool

    /// The next renewal date, if available.
    public let renewalDate: Date?

    public init(name: String, isPrimary: Bool, renewalDate: Date? = nil) {
        self.name = name
        self.isPrimary = isPrimary
        self.renewalDate = renewalDate
    }

    private enum CodingKeys: String, CodingKey {
        case name = "domain"
        case isPrimary = "primary_domain"
        case renewalDate = "auto_renewal_date"
    }
}

// MARK: - Constants
//
private extension DomainRemote {
    enum Defaults {
        static let domainSuggestionsQuantity = 20
    }

    enum ParameterKey {
        /// Term (e.g "flowers") or domain name (e.g. "flowers.com") to search alternative domain names from.
        static let query = "query"
        /// Maximum number of suggestions to return.
        static let quantity = "quantity"
        /// Whether to restrict suggestions to only wordpress.com subdomains. If `true`, only `quantity` and `query` parameters are respected.
        static let wordPressDotComSubdomainsOnly = "only_wordpressdotcom"
    }

    enum Path {
        static let domainSuggestions = "domains/suggestions"
    }
}
