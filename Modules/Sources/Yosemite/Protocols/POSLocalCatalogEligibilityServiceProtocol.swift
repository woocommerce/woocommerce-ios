import Foundation

/// Eligibility state for local catalog feature
/// Provides diagnostic information for UI display and decision-making
public enum POSLocalCatalogEligibilityState: Equatable, Sendable {
    /// Local catalog is eligible for use
    case eligible

    /// Local catalog is not eligible
    case ineligible(reason: POSLocalCatalogIneligibleReason)
}

/// Reasons why local catalog is ineligible
public enum POSLocalCatalogIneligibleReason: Equatable, Sendable {
    case posTabNotEligible
    case betaFeatureDisabled
    case unsupportedWooCommerceVersion(minimumVersion: String)
    case versionCheckFailed(underlyingError: String)

    /// Analytics skip reason string representation
    public var skipReason: String {
        switch self {
        case .posTabNotEligible:
            return "pos_not_eligible"
        case .betaFeatureDisabled:
            return "feature_flag_disabled"
        case .unsupportedWooCommerceVersion:
            return "unsupported_woocommerce_version"
        case .versionCheckFailed:
            return "version_check_failed"
        }
    }
}

/// Service that provides eligibility information for local catalog feature
///
/// Other services can query this for eligibility state and reasons:
/// - Sync coordinator can check if catalog is eligible
/// - Settings UI can display eligibility status and reasons
/// - Analytics can track why stores are ineligible
///
/// NOTE: This service checks catalog-related eligibility (WooCommerce version), the remote feature flag,
/// and the user-facing beta toggle.
/// It evaluates catalog eligibility when a caller requests or refreshes it, after the session-specific
/// system status service is configured.
public protocol POSLocalCatalogEligibilityServiceProtocol: Sendable {
    /// Attaches the session-specific system status service before catalog eligibility is evaluated.
    /// The service is created by the main-actor POS coordinator so it retains the authenticated
    /// session that owns this catalog eligibility service.
    @discardableResult
    func configure(systemStatusService: POSSystemStatusServiceProtocol) async -> Bool

    /// Get catalog eligibility for a specific site
    /// - Parameter siteID: The site ID to check eligibility for
    /// - Returns: Cached eligibility state, or eligible if not yet checked
    func catalogEligibility(for siteID: Int64) async throws -> POSLocalCatalogEligibilityState

    /// The eligibility state already computed for the site, without evaluating anything: unlike
    /// `catalogEligibility(for:)` a cache miss does not trigger a refresh, which can fetch.
    /// `nil` when nothing has evaluated eligibility for the site this session.
    ///
    /// For diagnostics. Callers deciding behaviour should use `catalogEligibility(for:)`.
    func cachedCatalogEligibility(for siteID: Int64) async -> POSLocalCatalogEligibilityState?

    /// Update POS eligibility and refresh catalog eligibility for the specified site
    /// - Parameters:
    ///   - isEligible: Whether POS is eligible for the site
    ///   - siteID: The site ID to refresh eligibility for
    func updatePOSEligibility(isEligible: Bool, for siteID: Int64) async throws

    /// Refresh eligibility state for a specific site
    /// - Parameter siteID: The site ID to check eligibility for
    /// - Returns: Fresh eligibility state with reason if ineligible
    @discardableResult func refreshEligibilityState(for siteID: Int64) async throws -> POSLocalCatalogEligibilityState

    /// Whether the local catalog feature is enabled from locally available signals only
    /// (local and cached remote feature flags plus the beta toggle), without any network checks.
    /// Used to gate POS entry from cached state when remote eligibility cannot be checked.
    func isLocalCatalogFeatureEnabled() async -> Bool
}

public extension POSLocalCatalogEligibilityServiceProtocol {
    /// Test and preview implementations do not need a system status service.
    @discardableResult
    func configure(systemStatusService: POSSystemStatusServiceProtocol) async -> Bool { false }
}
