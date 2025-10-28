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
    case posTabNotVisible
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
    /// Current eligibility state (actor-isolated, requires await to access)
    /// Use `eligibilityState == .eligible` to check if catalog is eligible for sync
    var eligibilityState: POSLocalCatalogEligibilityState { get async }

    /// Update the POS tab visibility state and refresh eligibility
    /// - Parameter isPOSTabVisible: Whether the POS tab is visible
    func updateVisibility(isPOSTabVisible: Bool) async

    /// Force refresh eligibility (bypasses cache and updates eligibilityState)
    /// - Returns: Fresh eligibility state with reason if ineligible
    @discardableResult func refreshEligibilityState() async -> POSLocalCatalogEligibilityState
}
