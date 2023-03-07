import Codegen
import Foundation

/// Protocol for `DomainRemote` mainly used for mocking.
public protocol DomainRemoteProtocol {
    /// Loads domain suggestions that are free (`*.wordpress.com` only) based on the query.
    /// - Parameter query: What the domain suggestions are based on.
    /// - Returns: The result of free domain suggestions.
    func loadFreeDomainSuggestions(query: String) async throws -> [FreeDomainSuggestion]

    /// Loads domain suggestions that are not free based on the query.
    /// - Parameter query: What the domain suggestions are based on.
    /// - Returns: A list of paid domain suggestions.
    func loadPaidDomainSuggestions(query: String) async throws -> [PaidDomainSuggestion]

    /// Loads WPCOM domain products for domain cost and sale info in `loadPaidDomainSuggestions`.
    /// - Returns: A list of domain products.
    func loadDomainProducts() async throws -> [DomainProduct]

    /// Loads all domains for a site.
    /// - Parameter siteID: ID of the site to load the domains for.
    /// - Returns: A list of domains.
    func loadDomains(siteID: Int64) async throws -> [SiteDomain]

    /// Loads the contact info for domain registration.
    /// - Returns: pre-existing contact info from WPCOM if available.
    func loadDomainContactInfo() async throws -> DomainContactInfo

    /// Validates the contact info for domain registration.
    /// - Parameters:
    ///   - domainContactInfo: Contact info to validate.
    ///   - domain: Domain name for domain registration. The validation rules vary between domains.
    func validate(domainContactInfo: DomainContactInfo, domain: String) async throws
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

    public func loadPaidDomainSuggestions(query: String) async throws -> [PaidDomainSuggestion] {
        let path = Path.domainSuggestions
        let parameters: [String: Any] = [
            ParameterKey.query: query,
            ParameterKey.quantity: Defaults.domainSuggestionsQuantity
        ]
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: path, parameters: parameters)
        return try await enqueue(request)
    }

    public func loadDomainProducts() async throws -> [DomainProduct] {
        let path = Path.domainProducts
        let parameters: [String: Any] = [
            ParameterKey.domainProductType: "domains"
        ]
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: path, parameters: parameters)
        let productsByName: [String: DomainProduct] = try await enqueue(request)
        return Array(productsByName.values)
    }

    public func loadDomains(siteID: Int64) async throws -> [SiteDomain] {
        let path = "sites/\(siteID)/\(Path.domains)"
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: path)
        let response: SiteDomainEnvelope = try await enqueue(request)
        return response.domains
    }

    public func loadDomainContactInfo() async throws -> DomainContactInfo {
        let path = Path.domainContactInfo
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: path)
        return try await enqueue(request)
    }

    public func validate(domainContactInfo: DomainContactInfo, domain: String) async throws {
        let path = "\(Path.domainContactInfo)/validate"
        let domainContactInfoDictionary = try domainContactInfo.toDictionary()
        let parameters: [String: Any] = [
            ParameterKey.domainContactInfo: domainContactInfoDictionary,
            ParameterKey.domainNames: domain
        ]
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .post, path: path, parameters: parameters)
        let response: DomainContactInfoValidationResponse = try await enqueue(request)
        guard response.success else {
            throw DomainContactInfoError.invalid(messages: response.errorMessages)
        }
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

/// Necessary data for a paid domain suggestion.
public struct PaidDomainSuggestion: Decodable, Equatable {
    /// Domain name.
    public let name: String
    /// WPCOM product ID.
    public let productID: Int64
    /// Whether there is privacy support. Used when creating a cart with a domain product.
    public let supportsPrivacy: Bool

    public init(name: String, productID: Int64, supportsPrivacy: Bool) {
        self.name = name
        self.productID = productID
        self.supportsPrivacy = supportsPrivacy
    }

    private enum CodingKeys: String, CodingKey {
        case name = "domain_name"
        case productID = "product_id"
        case supportsPrivacy = "supports_privacy"
    }
}

/// Necessary data for a WPCOM domain product.
public struct DomainProduct: Decodable, Equatable {
    /// WPCOM product ID.
    public let productID: Int64
    /// The duration of the product, localized on the backend (e.g. "year").
    public let term: String
    /// Cost string including the currency.
    public let cost: String
    /// Optional sale cost string including the currency.
    public let saleCost: String?

    private enum CodingKeys: String, CodingKey {
        case productID = "product_id"
        case term = "product_term"
        case cost = "combined_cost_display"
        case saleCost = "combined_sale_cost_display"
    }
}

/// Necessary data for a site's domain.
public struct SiteDomain: Decodable, Equatable {
    /// Domain name.
    public let name: String

    /// Whether the domain is the site's primary domain.
    public let isPrimary: Bool

    /// Whether the domain is a free staging domain from certain WPCOM plans.
    public let isWPCOMStagingDomain: Bool

    /// The type of domain, e.g. "wpcom" for WPCOM domains and "mapping" for other domains mapped to the WPCOM domains.
    public let type: DomainType

    /// The next renewal date, if available.
    public let renewalDate: Date?

    public init(name: String, isPrimary: Bool, isWPCOMStagingDomain: Bool, type: DomainType, renewalDate: Date? = nil) {
        self.name = name
        self.isPrimary = isPrimary
        self.isWPCOMStagingDomain = isWPCOMStagingDomain
        self.type = type
        self.renewalDate = renewalDate
    }

    /// Custom decoding implementation since `renewalDate` is an empty string instead of `null` when it's unavailable.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let isPrimary = try container.decode(Bool.self, forKey: .isPrimary)
        let isWPCOMStagingDomain = try container.decode(Bool.self, forKey: .isWPCOMStagingDomain)
        let type = try container.decode(DomainType.self, forKey: .type)

        let renewalDate: Date? = {
            guard let dateString = try? container.decodeIfPresent(String.self, forKey: .renewalDate) else {
                return nil
            }
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM d, yyyy"
            return dateFormatter.date(from: dateString)
        }()

        self.init(name: name, isPrimary: isPrimary, isWPCOMStagingDomain: isWPCOMStagingDomain, type: type, renewalDate: renewalDate)
    }

    private enum CodingKeys: String, CodingKey {
        case name = "domain"
        case isPrimary = "primary_domain"
        case isWPCOMStagingDomain = "is_wpcom_staging_domain"
        case type
        case renewalDate = "auto_renewal_date"
    }
}

public extension SiteDomain {
    /// The type of domain. Most often we filter domains by WPCOM and non-WPCOM domains.
    enum DomainType: Decodable, Equatable {
        case wpcom
        case mapping
        case other(type: String)
    }
}

extension SiteDomain.DomainType: RawRepresentable {
    public init(rawValue: String) {
        switch rawValue {
        case Keys.wpcom:
            self = .wpcom
        case Keys.mapping:
            self = .mapping
        default:
            self = .other(type: rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .wpcom: return Keys.wpcom
        case .mapping: return Keys.mapping
        case .other(let type):  return type
        }
    }

    private enum Keys {
        static let wpcom = "wpcom"
        static let mapping = "mapping"
    }
}

/// Contact info required for redeeming a domain with domain credit.
public struct DomainContactInfo: Codable, GeneratedFakeable, Equatable {
    public let firstName: String
    public let lastName: String
    public let organization: String?
    public let address1: String
    public let address2: String?
    public let postcode: String
    public let city: String
    public let state: String?
    public let countryCode: String
    public let phone: String?
    public let email: String?

    public init(firstName: String,
                lastName: String,
                organization: String?,
                address1: String,
                address2: String?,
                postcode: String,
                city: String,
                state: String?,
                countryCode: String,
                phone: String?,
                email: String?) {
        self.firstName = firstName
        self.lastName = lastName
        self.organization = organization
        self.address1 = address1
        self.address2 = address2
        self.postcode = postcode
        self.city = city
        self.state = state
        self.countryCode = countryCode
        self.phone = phone
        self.email = email
    }

    private enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case organization
        case address1 = "address_1"
        case address2 = "address_2"
        case postcode = "postal_code"
        case city
        case state
        case countryCode = "country_code"
        case phone
        case email
    }
}

public enum DomainContactInfoError: Error, Equatable {
    case invalid(messages: [String]?)
}

/// Maps to a list of domains to match the API response.
private struct SiteDomainEnvelope: Decodable {
    let domains: [SiteDomain]
}

private struct DomainContactInfoValidationResponse: Decodable {
    let success: Bool
    let errorMessages: [String]?

    private enum CodingKeys: String, CodingKey {
        case success
        case errorMessages = "messages_simple"
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
        /// The type of WPCOM products.
        static let domainProductType = "type"
        /// Domain contact info parameter for validating contact info.
        static let domainContactInfo = "contact_information"
        /// Domain names parameter for validating contact info.
        static let domainNames = "domain_names"
    }

    enum Path {
        static let domainSuggestions = "domains/suggestions"
        static let domainProducts = "products"
        static let domains = "domains"
        static let domainContactInfo = "me/domain-contact-information"
    }
}
