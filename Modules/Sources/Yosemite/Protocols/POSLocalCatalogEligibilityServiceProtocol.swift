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
    case catalogSizeTooLarge(totalCount: Int, limit: Int)
    case catalogSizeCheckFailed(underlyingError: String)
}

/// Service that provides eligibility information for local catalog feature
///
/// Other services can query this for eligibility state and reasons:
/// - Sync coordinator can check if catalog is eligible
/// - Settings UI can display eligibility status and reasons
/// - Analytics can track why stores are ineligible
///
/// NOTE: This service checks catalog-related eligibility (size limits) and feature flag state.
/// The service performs an initial eligibility check during initialization.
public protocol POSLocalCatalogEligibilityServiceProtocol {
    /// Get catalog eligibility for a specific site
    /// - Parameter siteID: The site ID to check eligibility for
    /// - Returns: Cached eligibility state, or eligible if not yet checked
    func catalogEligibility(for siteID: Int64) async throws -> POSLocalCatalogEligibilityState

    /// Update POS eligibility and refresh catalog eligibility for the specified site
    /// - Parameters:
    ///   - isEligible: Whether POS is eligible for the site
    ///   - siteID: The site ID to refresh eligibility for
    func updatePOSEligibility(isEligible: Bool, for siteID: Int64) async throws

    /// Refresh eligibility state for a specific site
    /// - Parameter siteID: The site ID to check eligibility for
    /// - Returns: Fresh eligibility state with reason if ineligible
    @discardableResult func refreshEligibilityState(for siteID: Int64) async throws -> POSLocalCatalogEligibilityState
}
