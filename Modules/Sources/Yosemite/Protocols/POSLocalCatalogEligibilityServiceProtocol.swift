import Foundation

/// Eligibility state for local catalog feature
/// Provides diagnostic information for UI display and decision-making
public enum POSLocalCatalogEligibilityState: Equatable {
    /// Local catalog is eligible for use
    case eligible

    /// Local catalog is not eligible
    case ineligible(reason: POSLocalCatalogIneligibleReason)
}

/// Reasons why local catalog is ineligible
public enum POSLocalCatalogIneligibleReason: Equatable {
    case posTabNotEligible
    case featureFlagDisabled
    case unsupportedWooCommerceVersion(minimumVersion: String)
    case catalogSizeCheckFailed(underlyingError: String)

    /// Analytics skip reason string representation
    public var skipReason: String {
        switch self {
        case .posTabNotEligible:
            return "pos_not_eligible"
        case .featureFlagDisabled:
            return "feature_flag_disabled"
        case .unsupportedWooCommerceVersion:
            return "unsupported_woocommerce_version"
        case .catalogSizeCheckFailed:
            return "catalog_size_check_failed"
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
/// NOTE: This service checks catalog-related eligibility (WooCommerce version) and feature flag state.
/// The service performs an initial eligibility check during initialization.
public protocol POSLocalCatalogEligibilityServiceProtocol {
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
