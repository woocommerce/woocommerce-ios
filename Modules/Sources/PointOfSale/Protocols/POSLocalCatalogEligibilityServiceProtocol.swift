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
    /// Current eligibility state (synchronously accessible on main thread)
    var eligibilityState: POSLocalCatalogEligibilityState { get }

    /// Force refresh eligibility (bypasses cache and updates eligibilityState)
    /// - Returns: Fresh eligibility state with reason if ineligible
    func refreshEligibilityState() async -> POSLocalCatalogEligibilityState
}
